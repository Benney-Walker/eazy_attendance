import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

// ─── Tables ───────────────────────────────────────────────────────────────

/// Cached classes/levels from `GET /staff/v1/load-levels` (`{levelId, levelName}`).
class Levels extends Table {
  TextColumn get levelId => text()();
  TextColumn get levelName => text()();

  @override
  Set<Column> get primaryKey => {levelId};
}

/// Cached roster from `load-students-for-attendance` (`{studentId, studentName}`),
/// scoped to the level it was loaded for.
class Students extends Table {
  TextColumn get studentId => text()();
  TextColumn get levelId => text()();
  TextColumn get studentName => text()();

  @override
  Set<Column> get primaryKey => {studentId, levelId};
}

class AttendanceRecords extends Table {
  TextColumn get levelId => text()();
  TextColumn get date => text()(); // yyyy-MM-dd, as the backend expects
  TextColumn get studentId => text()();
  TextColumn get status => text()(); // AttendanceStatus.wire
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {levelId, date, studentId};
}

class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get levelId => text()();
  TextColumn get date => text()();
  TextColumn get payloadJson => text()();
  TextColumn get status =>
      text().withDefault(const Constant('PENDING'))(); // SyncJobStatus.wire
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class Preferences extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

// ─── Database ───────────────────────────────────────────────────────────────

@DriftDatabase(
    tables: [Levels, Students, AttendanceRecords, SyncQueue, Preferences])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Test seam: build against an in-memory or custom executor.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // Schema 1 originally created sync_queue with a NOT NULL staff_id
            // column. The column was later dropped from the table definition
            // without a version bump, so devices with an older install still
            // have it and every insert fails. Rebuild the table from the
            // current definition; rows are copied, staff_id is discarded.
            await m.alterTable(TableMigration(syncQueue));
          }
        },
      );

  // ── Preferences (key-value UI state) ──

  Future<String?> getPref(String key) async {
    final row = await (select(preferences)..where((p) => p.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setPref(String key, String value) {
    return into(preferences).insertOnConflictUpdate(
      PreferencesCompanion.insert(key: key, value: value),
    );
  }

  // ── Levels ──

  Future<List<Level>> getLevels() => select(levels).get();

  /// Replace the cached level list with a fresh network result.
  Future<void> replaceLevels(List<LevelsCompanion> rows) async {
    await batch((b) {
      b.deleteAll(levels);
      b.insertAll(levels, rows);
    });
  }

  // ── Students ──

  Future<List<Student>> getStudentsForLevel(String levelId) {
    return (select(students)..where((s) => s.levelId.equals(levelId))).get();
  }

  /// Replace the cached roster for one level.
  Future<void> replaceStudentsForLevel(
    String levelId,
    List<StudentsCompanion> rows,
  ) async {
    await batch((b) {
      b.deleteWhere(students, (s) => s.levelId.equals(levelId));
      b.insertAll(students, rows);
    });
  }

  // ── Attendance records ──

  Future<List<AttendanceRecord>> getAttendance(String levelId, String date) {
    return (select(attendanceRecords)
          ..where((r) => r.levelId.equals(levelId) & r.date.equals(date)))
        .get();
  }

  /// Upsert the full set of marks for one (level, date).
  Future<void> upsertAttendance(List<AttendanceRecordsCompanion> rows) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(attendanceRecords, rows);
    });
  }

  /// Remove one teacher's cached classes, rosters, saved selections and
  /// already-uploaded marks, e.g. when a different teacher signs in on the
  /// same device. Unsynced marks and the sync queue are deliberately kept so
  /// nothing that hasn't reached the server is lost.
  Future<void> clearCachedClassData() {
    return transaction(() async {
      await delete(levels).go();
      await delete(students).go();
      await delete(preferences).go();
      await (delete(attendanceRecords)..where((r) => r.synced.equals(true)))
          .go();
    });
  }

  /// Mark every record for a (level, date) as synced once its job succeeds.
  Future<void> markAttendanceSynced(String levelId, String date) {
    return (update(attendanceRecords)
          ..where((r) => r.levelId.equals(levelId) & r.date.equals(date)))
        .write(const AttendanceRecordsCompanion(synced: Value(true)));
  }

  // ── Sync queue ──

  Future<List<SyncQueueData>> getPendingJobs() {
    return (select(syncQueue)
          ..where((j) => j.status.equals('PENDING') | j.status.equals('FAILED'))
          ..orderBy([(j) => OrderingTerm.asc(j.createdAt)]))
        .get();
  }

  Future<SyncQueueData?> findJobForLevelDate(String levelId, String date) {
    return (select(syncQueue)
          ..where((j) => j.levelId.equals(levelId) & j.date.equals(date))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<int> insertJob(SyncQueueCompanion job) => into(syncQueue).insert(job);

  Future<void> updateJob(int id, SyncQueueCompanion patch) {
    return (update(syncQueue)..where((j) => j.id.equals(id))).write(patch);
  }

  Future<void> deleteJob(int id) {
    return (delete(syncQueue)..where((j) => j.id.equals(id))).go();
  }

  /// Return jobs left in SYNCING by an interrupted upload (app killed, crash)
  /// to PENDING. Only call this when no upload is in flight — the sync pass
  /// does so at its start, inside its own lock.
  Future<void> recoverInterruptedJobs() {
    return (update(syncQueue)..where((j) => j.status.equals('SYNCING'))).write(
      SyncQueueCompanion(
        status: const Value('PENDING'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Finish a successfully uploaded job: delete it and mark its records synced.
  ///
  /// Both steps only happen if the job is still SYNCING. If the teacher
  /// re-saved the class while the upload was in flight, the job was reset to
  /// PENDING with the newer marks; it is kept so the next pass sends them.
  /// Returns true when the job was completed.
  Future<bool> completeJob(SyncQueueData job) {
    return transaction(() async {
      final deleted = await (delete(syncQueue)
            ..where((j) => j.id.equals(job.id) & j.status.equals('SYNCING')))
          .go();
      if (deleted == 0) return false;
      await markAttendanceSynced(job.levelId, job.date);
      return true;
    });
  }

  /// Record a failed upload attempt, unless the job was re-saved while the
  /// upload was in flight (then its counters were already reset).
  Future<void> failJob({
    required int id,
    required int attemptCount,
    required bool parked,
    required String error,
  }) {
    return (update(syncQueue)
          ..where((j) => j.id.equals(id) & j.status.equals('SYNCING')))
        .write(
      SyncQueueCompanion(
        status: Value(parked ? 'FAILED' : 'PENDING'),
        attemptCount: Value(attemptCount),
        lastError: Value(error),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Enqueue (or replace) the pending job for a (level, date) atomically with
  /// the record upsert. Last-write-wins: an existing unsynced job for the same
  /// class/date is overwritten rather than duplicated.
  ///
  /// A replaced job is re-armed (PENDING, zero attempts) so new marks are
  /// uploaded even if the previous payload had been parked as FAILED, and it
  /// keeps its original createdAt so queue order stays first-in, first-out.
  Future<void> saveAttendanceAndEnqueue({
    required List<AttendanceRecordsCompanion> records,
    required SyncQueueCompanion job,
    required String levelId,
    required String date,
  }) async {
    await transaction(() async {
      await batch((b) {
        b.insertAllOnConflictUpdate(attendanceRecords, records);
      });
      final existing = await findJobForLevelDate(levelId, date);
      if (existing != null) {
        await updateJob(
          existing.id,
          job.copyWith(
            status: const Value('PENDING'),
            attemptCount: const Value(0),
            lastError: const Value(null),
            createdAt: Value(existing.createdAt),
          ),
        );
      } else {
        await into(syncQueue).insert(job);
      }
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'eazy_attendance.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
