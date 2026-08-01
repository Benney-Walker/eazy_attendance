import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

enum NetworkStatus { online, offline }

class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  /// Emits whenever effective reachability changes. De-duplicated so listeners
  /// only see actual transitions.
  Stream<NetworkStatus> get statusStream async* {
    // Seed with the current status on subscription.
    yield await currentStatus();

    NetworkStatus? last;
    await for (final _ in _connectivity.onConnectivityChanged) {
      final status = await currentStatus();
      if (status != last) {
        last = status;
        yield status;
      }
    }
  }

  /// One-shot check of effective connectivity right now.
  Future<NetworkStatus> currentStatus() async {
    final results = await _connectivity.checkConnectivity();
    if (_allNone(results)) return NetworkStatus.offline;
    return await _isReachable() ? NetworkStatus.online : NetworkStatus.offline;
  }

  Future<bool> get isOnline async =>
      (await currentStatus()) == NetworkStatus.online;

  bool _allNone(List<ConnectivityResult> results) =>
      results.isEmpty ||
          results.every((r) => r == ConnectivityResult.none);

  /// Confirm the internet is actually reachable via a cheap DNS lookup.
  Future<bool> _isReachable() async {
    try {
      final result = await InternetAddress.lookup('one.one.one.one')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    }
  }
}