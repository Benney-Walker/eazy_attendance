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

/// The LOCAL SOURCE OF TRUTH for marks. The attendance screen reads and writes
/// here; a row exists per (level, date, student). `status` holds the wire
/// string ("PRESENT"/"ABSENT"). `synced` flips true once the owning sync job
/// succeeds.
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
  TextColumn get staffId => text()();
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

// ─── Database ───────────────────────────────────────────────────────────────

@DriftDatabase(tables: [Levels, Students, AttendanceRecords, SyncQueue])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Test seam: build against an in-memory or custom executor.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

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

  /// Enqueue (or replace) the pending job for a (level, date) atomically with
  /// the record upsert. Last-write-wins: an existing unsynced job for the same
  /// class/date is overwritten rather than duplicated.
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
        await updateJob(existing.id, job);
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