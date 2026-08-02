import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database/app_database.dart';
import 'network/api_service.dart';
import 'network/connectivity_service.dart';
import 'storage/secure_storage_service.dart';

/// Core infrastructure providers (database, storage, networking, connectivity).
/// These are cross-cutting singletons that many features depend on, so they
/// live in core rather than in any one feature.

/// Single app-wide Drift database instance.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Encrypted key-value storage for the JWT and staff identity.
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

/// The single reusable Dio HTTP client (auto-attaches auth headers).
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(ref.watch(secureStorageProvider));
});

/// Connectivity watcher (interface state + reachability check).
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

/// Live online/offline status. The sync engine watches this to drain the queue
/// when connectivity returns; UI can watch it for the quiet indicator.
final networkStatusProvider = StreamProvider<NetworkStatus>((ref) {
  return ref.watch(connectivityServiceProvider).statusStream;
});
