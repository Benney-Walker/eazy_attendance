import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/sync/sync_controller.dart';
import '../../dashboard/data/level_models.dart';
import '../data/attendance_data_providers.dart';
import '../data/attendance_repository.dart';

/// Identifies which class/date the attendance screen is working on.
///
/// [initialStudents] / [initialFromCache] carry the roster the dashboard has
/// just loaded, so the screen doesn't fetch it a second time. They are not part
/// of equality: the provider is keyed by class/date only.
class AttendanceArgs {
  const AttendanceArgs({
    required this.levelId,
    required this.date,
    required this.className,
    this.initialStudents,
    this.initialFromCache = false,
  });

  final String levelId;
  final String date;
  final String className;
  final List<StudentModel>? initialStudents;
  final bool initialFromCache;

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

/// Drives one attendance-marking session: tracks present/absent marks in
/// memory and saves locally + enqueues for sync on submit.
///
/// The state lives as long as the attendance screen is open (auto-dispose), so
/// every visit starts from the latest roster, and nothing from one teacher's
/// session survives into the next. Leaving without saving discards the
/// changes, as on the website.
class AttendanceController
    extends AutoDisposeFamilyNotifier<AttendanceState, AttendanceArgs> {
  bool _disposed = false;

  @override
  AttendanceState build(AttendanceArgs arg) {
    // Riverpod 2 reuses the notifier instance if the provider rebuilds.
    _disposed = false;
    ref.onDispose(() => _disposed = true);

    final seeded = arg.initialStudents;
    if (seeded != null) {
      return _loaded(seeded, fromCache: arg.initialFromCache);
    }

    // Opened without a pre-loaded roster: load it once.
    Future.microtask(_load);
    return const AttendanceState(students: [], marks: {}, loading: true);
  }

  Future<void> _load() async {
    if (_disposed) return;
    final repo = ref.read(studentsRepositoryProvider);

    List<StudentModel> students;
    var fromCache = false;
    try {
      students = await repo.refresh(arg.levelId, arg.date);
    } catch (_) {
      // Offline, server error or unexpected payload: fall back to the cache.
      fromCache = true;
      try {
        students = await repo.getCached(arg.levelId, arg.date);
      } catch (_) {
        students = const [];
      }
    }

    // The teacher may have left the screen while the roster was loading.
    if (_disposed) return;
    state = _loaded(students, fromCache: fromCache);
  }

  AttendanceState _loaded(List<StudentModel> students,
      {required bool fromCache}) {
    return AttendanceState(
      students: students,
      marks: _seedMarks(students),
      loading: false,
      fromCache: fromCache,
    );
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

  Future<bool> save() async {
    if (state.saving || state.students.isEmpty) return false;

    state = state.copyWith(saving: true, error: null);

    final marks = state.students
        .map((s) => StudentMark(
              studentId: s.id,
              present: state.marks[s.id] ?? false,
            ))
        .toList();

    try {
      await ref.read(attendanceRepositoryProvider).saveAttendance(
            levelId: arg.levelId,
            date: arg.date,
            marks: marks,
          );
      state = state.copyWith(saving: false);
      // Kick an automatic sync attempt. Fires only if online; otherwise the
      // job simply waits in the queue for connectivity to return.
      ref.read(syncControllerProvider.notifier).syncNow();
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

final attendanceControllerProvider = NotifierProvider.autoDispose
    .family<AttendanceController, AttendanceState, AttendanceArgs>(
        AttendanceController.new);
