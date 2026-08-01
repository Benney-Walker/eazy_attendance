import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database/app_database.dart';
import 'network/connectivity_service.dart';

/// Single app-wide Drift database instance.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Connectivity watcher (interface state + reachability check).
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

/// Live online/offline status. Phase 6's sync engine watches this to drain the
/// queue when connectivity returns; UI can watch it for the quiet indicator.
final networkStatusProvider = StreamProvider<NetworkStatus>((ref) {
  return ref.watch(connectivityServiceProvider).statusStream;
});