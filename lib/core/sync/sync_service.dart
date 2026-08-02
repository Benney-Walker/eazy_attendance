import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../config/api_config.dart';
import '../database/app_database.dart';
import '../database/attendance_status.dart';
import '../network/api_service.dart';
import '../network/connectivity_service.dart';

/// Outcome of a drain pass.
class SyncResult {
  const SyncResult({
    required this.attempted,
    required this.succeeded,
    required this.failed,
  });

  final int attempted;
  final int succeeded;
  final int failed;

  bool get didWork => attempted > 0;
}

/// Drains the offline attendance queue to the backend.
///
/// For each queued job it replays `POST /student/v2/mark-attendance` with the
/// EXACT contract the website uses — headers `Authorization`, `staffId`,
/// `selectedDate`, `levelId`, and a JSON body of `[{studentId, status}]` — from
/// the data stored on the job, so a submission uploads byte-identically even
/// after an app restart.
///
/// On success the job is deleted and its local attendance records are marked
/// synced. On failure the attempt count / last error are recorded and the job
/// is kept (as `pending`, or `failed` after [maxAttempts]) so nothing is lost.
class SyncService {
  SyncService({
    required AppDatabase db,
    required ApiService api,
    required ConnectivityService connectivity,
  })  : _db = db,
        _api = api,
        _connectivity = connectivity;

  final AppDatabase _db;
  final ApiService _api;
  final ConnectivityService _connectivity;

  /// After this many failed attempts a job is parked as `failed` and skipped by
  /// automatic passes (still retried on an explicit reconnect/resume trigger).
  static const int maxAttempts = 5;

  bool _running = false;

  /// True while a drain pass is in flight (for the UI's "Syncing…" state).
  bool get isRunning => _running;

  /// How many jobs are still waiting (pending or failed).
  Future<int> pendingCount() async => (await _db.getPendingJobs()).length;

  /// Attempt to upload all queued jobs. Safe to call repeatedly; overlapping
  /// calls are coalesced by an internal lock. Does nothing (attempted 0) when
  /// offline.
  Future<SyncResult> sync() async {
    if (_running) {
      return const SyncResult(attempted: 0, succeeded: 0, failed: 0);
    }
    _running = true;
    try {
      if (!await _connectivity.isOnline) {
        return const SyncResult(attempted: 0, succeeded: 0, failed: 0);
      }

      final jobs = await _db.getPendingJobs();
      var succeeded = 0;
      var failed = 0;
      var attempted = 0;

      for (final job in jobs) {
        // Skip jobs already parked as failed beyond the ceiling; they wait for
        // an explicit trigger to be retried (handled by resetFailed()).
        if (SyncJobStatus.fromWire(job.status) == SyncJobStatus.failed &&
            job.attemptCount >= maxAttempts) {
          continue;
        }

        attempted++;
        final ok = await _uploadJob(job);
        if (ok) {
          succeeded++;
        } else {
          failed++;
        }
      }

      return SyncResult(
          attempted: attempted, succeeded: succeeded, failed: failed);
    } finally {
      _running = false;
    }
  }

  /// Re-arm jobs previously parked as `failed` so the next [sync] retries them
  /// (used on a fresh reconnect / app resume — a new chance to succeed).
  Future<void> resetFailed() async {
    final jobs = await _db.getPendingJobs();
    for (final job in jobs) {
      if (SyncJobStatus.fromWire(job.status) == SyncJobStatus.failed) {
        await _db.updateJob(
          job.id,
          SyncQueueCompanion(
            status: const Value('PENDING'),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    }
  }

  Future<bool> _uploadJob(SyncQueueData job) async {
    // Mark as syncing.
    await _db.updateJob(
      job.id,
      SyncQueueCompanion(
        status: const Value('SYNCING'),
        updatedAt: Value(DateTime.now()),
      ),
    );

    try {
      final body = jsonDecode(job.payloadJson);

      final response = await _api.client.post(
        ApiConfig.markAttendance,
        data: body,
        options: Options(
          headers: {
            // staffId + Authorization are also added by the interceptor, but we
            // set them explicitly from the job so the request is self-contained
            // and replay-accurate regardless of the current session.
            'staffId': job.staffId,
            'selectedDate': job.date,
            'levelId': job.levelId,
          },
        ),
      );

      final status = response.statusCode ?? 0;
      if (status >= 200 && status < 300) {
        // Success: drop the job, mark records synced.
        await _db.markAttendanceSynced(job.levelId, job.date);
        await _db.deleteJob(job.id);
        return true;
      }

      // Non-2xx (including 401): record failure, keep the job.
      await _recordFailure(job, 'Server responded $status');
      return false;
    } on DioException catch (e) {
      await _recordFailure(job, e.message ?? 'Network error');
      return false;
    } catch (e) {
      await _recordFailure(job, e.toString());
      return false;
    }
  }

  Future<void> _recordFailure(SyncQueueData job, String error) async {
    final attempts = job.attemptCount + 1;
    final parked = attempts >= maxAttempts;
    await _db.updateJob(
      job.id,
      SyncQueueCompanion(
        status: Value(parked ? 'FAILED' : 'PENDING'),
        attemptCount: Value(attempts),
        lastError: Value(error),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
