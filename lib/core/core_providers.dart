import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database/app_database.dart';
import 'network/api_service.dart';
import 'network/connectivity_service.dart';
import 'storage/secure_storage_service.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(ref.watch(secureStorageProvider));
});

/// Connectivity watcher (interface state + reachability check).
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

final networkStatusProvider = StreamProvider<NetworkStatus>((ref) {
  return ref.watch(connectivityServiceProvider).statusStream;
});
