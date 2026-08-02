import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/config/api_config.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/attendance_status.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_service.dart';
import '../../dashboard/data/level_models.dart';

/// Local-first access to a class roster for a given date.
///
/// The roster (names) is cached per level. Attendance status for the chosen
/// date comes from the local AttendanceRecords table when present (so unsynced
/// local marks win), otherwise from the backend's last-known status on refresh.
class StudentsRepository {
  StudentsRepository(this._api, this._db);

  final ApiService _api;
  final AppDatabase _db;

  /// Cached roster + any locally stored marks for [date]. Used offline.
  Future<List<StudentModel>> getCached(String levelId, String date) async {
    final roster = await _db.getStudentsForLevel(levelId);
    final marks = await _db.getAttendance(levelId, date);
    final markById = {for (final m in marks) m.studentId: m.status};

    return roster.map((s) {
      final localStatus = markById[s.studentId];
      final present = localStatus != null
          ? AttendanceStatus.fromWire(localStatus).isPresent
          : false;
      return StudentModel(
        id: s.studentId,
        name: s.studentName,
        presentByDefault: present,
      );
    }).toList();
  }

  /// Fetch the roster for (level, date) from the backend, cache the names, and
  /// return students. If a local mark already exists for a student on that
  /// date, it takes precedence over the backend status (unsynced local edits
  /// must not be clobbered by a refresh).
  Future<List<StudentModel>> refresh(String levelId, String date) async {
    final Response<dynamic> response;
    try {
      response = await _api.client.get(
        '${ApiConfig.loadStudentsForAttendance}/$levelId/$date',
      );
    } on DioException {
      throw const NetworkException();
    }

    final status = response.statusCode ?? 0;
    if (status == 401) throw const UnauthorizedException();
    if (status < 200 || status >= 300) {
      throw ServerException('Failed to load students.', status);
    }

    final data = response.data;
    if (data is! List) throw const UnexpectedException();

    final rows = data.whereType<Map>().toList();

    // Cache the roster (names) for offline use.
    await _db.replaceStudentsForLevel(
      levelId,
      rows
          .map((m) => StudentsCompanion.insert(
                studentId: (m['studentId'] ?? '').toString(),
                levelId: levelId,
                studentName: (m['studentName'] ?? '').toString(),
              ))
          .where((c) => c.studentId.value.isNotEmpty)
          .toList(),
    );

    // Local marks (if any) override backend status for this date.
    final localMarks = await _db.getAttendance(levelId, date);
    final localById = {for (final m in localMarks) m.studentId: m.status};

    return rows
        .map((m) {
          final id = (m['studentId'] ?? '').toString();
          final backendPresent =
              AttendanceStatus.fromWire(m['status']?.toString()).isPresent;
          final present = localById.containsKey(id)
              ? AttendanceStatus.fromWire(localById[id]).isPresent
              : backendPresent;
          return StudentModel(
            id: id,
            name: (m['studentName'] ?? '').toString(),
            presentByDefault: present,
          );
        })
        .where((s) => s.id.isNotEmpty)
        .toList();
  }
}
