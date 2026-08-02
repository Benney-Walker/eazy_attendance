import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core_providers.dart';
import 'attendance_repository.dart';
import 'students_repository.dart';

/// Roster repository (local-first read + network refresh).
final studentsRepositoryProvider = Provider<StudentsRepository>((ref) {
  return StudentsRepository(
    ref.watch(apiServiceProvider),
    ref.watch(appDatabaseProvider),
  );
});

/// Attendance write repository (save-local + enqueue).
final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(ref.watch(appDatabaseProvider));
});
