import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Automatic network status for the app. Staff never choose online/offline —
/// this decides it.
///
/// `connectivity_plus` only reports the *interface* state (WiFi/mobile present),
/// which does not guarantee the internet is actually reachable (captive portals,
/// "connected, no internet", etc.). So each interface change is confirmed with a
/// lightweight DNS lookup before we report `online`.
///
/// Phase 3 exposes this stream (the backbone). Phase 6's sync engine subscribes
/// to it to drain the queue when connectivity returns.
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
