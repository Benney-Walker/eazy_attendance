import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../attendance/data/attendance_repository.dart';
import '../../attendance/data/students_repository.dart';
import '../../../core/core_providers.dart';
import 'levels_repository.dart';

/// Classes repository (local-first read + network refresh).
final levelsRepositoryProvider = Provider<LevelsRepository>((ref) {
  return LevelsRepository(
    ref.watch(apiServiceProvider),
    ref.watch(appDatabaseProvider),
  );
});

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