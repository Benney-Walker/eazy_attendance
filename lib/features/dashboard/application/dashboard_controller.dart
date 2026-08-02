import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core_providers.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/date_utils.dart';
import '../data/data_providers.dart';
import '../data/level_models.dart';

/// Immutable dashboard state: the class list, the current selection, and load
/// status. `offlineNotice` is true when we're showing cached classes because a
/// network refresh could not reach the server.
class DashboardState {
  const DashboardState({
    this.classes = const [],
    this.selectedClassId,
    required this.date,
    this.loadingClasses = true,
    this.offlineNotice = false,
  });

  final List<LevelModel> classes;
  final String? selectedClassId;
  final String date; // yyyy-MM-dd
  final bool loadingClasses;
  final bool offlineNotice;

  bool get hasSelection =>
      selectedClassId != null && selectedClassId!.isNotEmpty;

  DashboardState copyWith({
    List<LevelModel>? classes,
    String? selectedClassId,
    String? date,
    bool? loadingClasses,
    bool? offlineNotice,
  }) {
    return DashboardState(
      classes: classes ?? this.classes,
      selectedClassId: selectedClassId ?? this.selectedClassId,
      date: date ?? this.date,
      loadingClasses: loadingClasses ?? this.loadingClasses,
      offlineNotice: offlineNotice ?? this.offlineNotice,
    );
  }
}

const _prefSelectedClass = 'selected_level_id';
const _prefSelectedDate = 'selected_date';

/// Drives the dashboard: loads classes local-first (cache instantly, refresh
/// from network when reachable, fall back to cache when offline), and tracks
/// the selected class + date, persisting them so the screen restores state.
class DashboardController extends AsyncNotifier<DashboardState> {
  @override
  Future<DashboardState> build() async {
    final db = ref.read(appDatabaseProvider);
    final repo = ref.read(levelsRepositoryProvider);

    // Restore prior selection.
    final savedClass = await db.getPref(_prefSelectedClass);
    final savedDate = await db.getPref(_prefSelectedDate);
    final date = (savedDate != null && savedDate.isNotEmpty)
        ? savedDate
        : todayIso();

    // Show cached classes immediately.
    final cached = await repo.getCached();

    var result = DashboardState(
      classes: cached,
      selectedClassId: _validSelection(savedClass, cached),
      date: date,
      loadingClasses: cached.isEmpty, // only "loading" if nothing to show yet
    );

    // Refresh from network in the background; fall back to cache on failure.
    try {
      final fresh = await repo.refresh();
      result = result.copyWith(
        classes: fresh,
        selectedClassId: _validSelection(result.selectedClassId, fresh),
        loadingClasses: false,
        offlineNotice: false,
      );
    } on ApiException {
      // Offline or server error: keep cached classes. Mark offline only if we
      // truly have nothing fresh; an empty cache with no network is a real
      // "can't load" state the UI can message.
      result = result.copyWith(
        loadingClasses: false,
        offlineNotice: cached.isNotEmpty,
      );
    }

    return result;
  }

  /// Keep a selection only if it still exists in the available classes.
  String? _validSelection(String? id, List<LevelModel> classes) {
    if (id == null || id.isEmpty) return null;
    return classes.any((c) => c.id == id) ? id : null;
  }

  Future<void> selectClass(String? classId) async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(selectedClassId: classId));
    if (classId != null && classId.isNotEmpty) {
      await ref.read(appDatabaseProvider).setPref(_prefSelectedClass, classId);
    }
  }

  Future<void> selectDate(DateTime date) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final iso = toIsoDate(date);
    state = AsyncData(current.copyWith(date: iso));
    await ref.read(appDatabaseProvider).setPref(_prefSelectedDate, iso);
  }
}

final dashboardControllerProvider =
    AsyncNotifierProvider<DashboardController, DashboardState>(
        DashboardController.new);
