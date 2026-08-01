import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/application/auth_controller.dart';
import '../../dashboard/data/level_models.dart';
import '../data/attendance_data_providers.dart';
import '../data/attendance_repository.dart';

/// Identifies which class/date the attendance screen is working on.
class AttendanceArgs {
  const AttendanceArgs({
    required this.levelId,
    required this.date,
    required this.className,
  });

  final String levelId;
  final String date;
  final String className;

  @override
  bool operator ==(Object other) =>
      other is AttendanceArgs &&
          other.levelId == levelId &&
          other.date == date &&
          other.className == className;

  @override
  int get hashCode => Object.hash(levelId, date, className);
}

/// Immutable marking state for one (level, date).
class AttendanceState {
  const AttendanceState({
    required this.students,
    required this.marks,
    this.loading = true,
    this.fromCache = false,
    this.error,
    this.saving = false,
  });

  /// Roster in display order.
  final List<StudentModel> students;

  /// studentId → present?
  final Map<String, bool> marks;

  final bool loading;
  final bool fromCache;
  final String? error;
  final bool saving;

  int get total => students.length;
  int get present => marks.values.where((v) => v).length;
  int get absent => total - present;
  int get percent => total == 0 ? 0 : ((present / total) * 100).round();

  AttendanceState copyWith({
    List<StudentModel>? students,
    Map<String, bool>? marks,
    bool? loading,
    bool? fromCache,
    Object? error = _sentinel,
    bool? saving,
  }) {
    return AttendanceState(
      students: students ?? this.students,
      marks: marks ?? this.marks,
      loading: loading ?? this.loading,
      fromCache: fromCache ?? this.fromCache,
      error: identical(error, _sentinel) ? this.error : error as String?,
      saving: saving ?? this.saving,
    );
  }

  static const _sentinel = Object();
}

class AttendanceController
    extends FamilyNotifier<AttendanceState, AttendanceArgs> {
  @override
  AttendanceState build(AttendanceArgs arg) {
    // Kick off the load once; state starts empty/loading.
    Future.microtask(_load);
    return const AttendanceState(students: [], marks: {}, loading: true);
  }

  Future<void> _load() async {
    final repo = ref.read(studentsRepositoryProvider);
    try {
      final students = await repo.refresh(arg.levelId, arg.date);
      state = AttendanceState(
        students: students,
        marks: _seedMarks(students),
        loading: false,
        fromCache: false,
      );
    } on ApiException {
      final cached = await repo.getCached(arg.levelId, arg.date);
      state = AttendanceState(
        students: cached,
        marks: _seedMarks(cached),
        loading: false,
        fromCache: true,
      );
    }
  }

  Map<String, bool> _seedMarks(List<StudentModel> students) {
    return {for (final s in students) s.id: s.presentByDefault};
  }

  void toggle(String studentId) {
    final marks = Map<String, bool>.from(state.marks);
    marks[studentId] = !(marks[studentId] ?? false);
    state = state.copyWith(marks: marks);
  }

  void markAll(bool present) {
    final marks = {for (final s in state.students) s.id: present};
    state = state.copyWith(marks: marks);
  }

  /// Save locally and enqueue for sync. Returns true on success. This is
  /// instant and offline-safe: it writes to the local DB and queues the job in
  /// one transaction, regardless of connectivity.
  Future<bool> save() async {
    if (state.saving || state.students.isEmpty) return false;

    final staffId = await ref.read(secureStorageProvider).readStaffId();
    if (staffId == null || staffId.isEmpty) {
      state = state.copyWith(error: 'Missing staff information. Please sign in again.');
      return false;
    }

    state = state.copyWith(saving: true, error: null);

    final marks = state.students
        .map((s) => StudentMark(
      studentId: s.id,
      present: state.marks[s.id] ?? false,
    ))
        .toList();

    try {
      await ref.read(attendanceRepositoryProvider).saveAttendance(
        staffId: staffId,
        levelId: arg.levelId,
        date: arg.date,
        marks: marks,
      );
      state = state.copyWith(saving: false);
      return true;
    } catch (_) {
      state = state.copyWith(
        saving: false,
        error: 'Could not save attendance. Please try again.',
      );
      return false;
    }
  }
}

final attendanceControllerProvider = NotifierProvider.family<AttendanceController,
    AttendanceState, AttendanceArgs>(AttendanceController.new);