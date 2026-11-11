import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core_providers.dart';
import '../network/connectivity_service.dart';
import 'sync_notifier.dart';
import 'sync_service.dart';

/// Provider for the sync engine.
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    db: ref.watch(appDatabaseProvider),
    api: ref.watch(apiServiceProvider),
    connectivity: ref.watch(connectivityServiceProvider),
  );
});

/// Provider for quiet sync notifications.
final syncNotifierProvider = Provider<SyncNotifier>((ref) => SyncNotifier());

/// UI-facing sync status.
enum SyncPhase { idle, syncing, offline }

class SyncState {
  const SyncState({
    this.phase = SyncPhase.idle,
    this.pending = 0,
    this.lastSyncedAt,
    this.justSynced = false,
  });

  final SyncPhase phase;
  final int pending;
  final DateTime? lastSyncedAt;

  /// Momentary flag set right after a successful drain, for a brief "Synced"
  /// confirmation the UI can show and then let fade.
  final bool justSynced;

  SyncState copyWith({
    SyncPhase? phase,
    int? pending,
    DateTime? lastSyncedAt,
    bool? justSynced,
  }) {
    return SyncState(
      phase: phase ?? this.phase,
      pending: pending ?? this.pending,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      justSynced: justSynced ?? this.justSynced,
    );
  }
}

class SyncController extends Notifier<SyncState> {
  Timer? _debounce;

  @override
  SyncState build() {
    // React to connectivity changes. ref.listen inside build is automatically
    // cleaned up with the notifier, so no manual subscription handling.
    ref.listen<AsyncValue<NetworkStatus>>(
      networkStatusProvider,
      (previous, next) {
        final status = next.valueOrNull;
        if (status == NetworkStatus.online) {
          // Fresh connectivity: re-arm parked jobs and drain.
          _onReconnect();
        } else if (status == NetworkStatus.offline) {
          _refreshPendingThen(SyncPhase.offline);
        }
      },
    );

    ref.onDispose(() => _debounce?.cancel());

    // Seed pending count + kick an initial sync attempt shortly after start.
    _refreshPending();
    Future.microtask(syncNow);

    return const SyncState();
  }

  Future<void> _onReconnect() async {
    await ref.read(syncServiceProvider).resetFailed();
    syncNow();
  }

  void syncNow() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _drain);
  }

  /// Trigger to call from app lifecycle resume.
  Future<void> onResume() => _onReconnect();

  Future<void> _drain() async {
    // Guard: only attempt when we still have a session.
    final hasToken = await ref.read(secureStorageProvider).hasSession();
    if (!hasToken) return;

    final service = ref.read(syncServiceProvider);
    final notifier = ref.read(syncNotifierProvider);

    state = state.copyWith(phase: SyncPhase.syncing, justSynced: false);

    var notify = false;
    var succeeded = 0;
    try {
      // Only surface a notification when there's actually queued work.
      notify = await service.pendingCount() > 0;
      if (notify) await _notifySafely(notifier.showSyncing);

      succeeded = (await service.sync()).succeeded;
    } catch (e, st) {
      // A failed pass (e.g. a database error) must not leave the chip stuck on
      // "Syncing…". Jobs stay queued; the next trigger retries them.
      debugPrint('Sync pass failed: $e\n$st');
    }

    // Resolve the notification: confirm on success, otherwise clear it (we
    // don't nag about failures — the quiet in-app chip shows "pending").
    if (notify) {
      await _notifySafely(
        succeeded > 0 ? () => notifier.showSynced(succeeded) : notifier.clear,
      );
    }

    final pending = await service.pendingCount();
    final online = await ref.read(connectivityServiceProvider).isOnline;

    state = SyncState(
      phase: online ? SyncPhase.idle : SyncPhase.offline,
      pending: pending,
      lastSyncedAt: succeeded > 0 ? DateTime.now() : state.lastSyncedAt,
      justSynced: succeeded > 0,
    );

    // Clear the momentary "just synced" flag after a short delay.
    if (succeeded > 0) {
      Future.delayed(const Duration(seconds: 3), () {
        if (state.justSynced) {
          state = state.copyWith(justSynced: false);
        }
      });
    }
  }

  /// Notifications are a courtesy: failing to show one (permission revoked,
  /// missing resource) must never stop attendance from syncing.
  Future<void> _notifySafely(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      debugPrint('Sync notification failed: $e');
    }
  }

  Future<void> _refreshPending() async {
    final pending = await ref.read(syncServiceProvider).pendingCount();
    state = state.copyWith(pending: pending);
  }

  Future<void> _refreshPendingThen(SyncPhase phase) async {
    final pending = await ref.read(syncServiceProvider).pendingCount();
    state = state.copyWith(pending: pending, phase: phase);
  }
}

final syncControllerProvider =
    NotifierProvider<SyncController, SyncState>(SyncController.new);
