import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/attendance_status.dart';

/// One student's mark within a submission.
class StudentMark {
  const StudentMark({required this.studentId, required this.present});

  final String studentId;
  final bool present;

  AttendanceStatus get status => AttendanceStatus.fromBool(present);
}

/// The write side of attendance. Saving is LOCAL-FIRST: marks are written to
/// the local database and a sync job is enqueued in a single transaction, so
/// the save is instant and durable whether or not there is a network. The
/// Phase 6 sync engine later replays the queued job against the backend.
class AttendanceRepository {
  AttendanceRepository(this._db);

  final AppDatabase _db;

  /// Locally stored marks for (level, date), for rehydrating the screen.
  Future<Map<String, bool>> getLocalMarks(String levelId, String date) async {
    final records = await _db.getAttendance(levelId, date);
    return {
      for (final r in records)
        r.studentId: AttendanceStatus.fromWire(r.status).isPresent,
    };
  }

  Future<void> saveAttendance({
    required String staffId,
    required String levelId,
    required String date,
    required List<StudentMark> marks,
  }) async {
    final now = DateTime.now();

    final records = marks
        .map((m) => AttendanceRecordsCompanion.insert(
              levelId: levelId,
              date: date,
              studentId: m.studentId,
              status: m.status.wire,
              synced: const Value(false),
              updatedAt: now,
            ))
        .toList();

    final payload = jsonEncode(
      marks
          .map((m) => {'studentId': m.studentId, 'status': m.status.wire})
          .toList(),
    );

    final job = SyncQueueCompanion.insert(
      staffId: staffId,
      levelId: levelId,
      date: date,
      payloadJson: payload,
      createdAt: now,
      updatedAt: now,
    );

    await _db.saveAttendanceAndEnqueue(
      records: records,
      job: job,
      levelId: levelId,
      date: date,
    );
  }
}
