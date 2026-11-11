import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Quiet system notifications for background sync status.
///
/// Deliberately unobtrusive: a silent, low-importance channel with no sound or
/// vibration. A "Syncing…" notification appears while a background drain runs
/// and is either replaced by a brief "Attendance synced" note or cleared when
/// done — matching the app's quiet, non-intrusive style.
class SyncNotifier {
  SyncNotifier([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const int _syncingId = 1001;
  static const String _channelId = 'sync_status';
  static const String _channelName = 'Sync status';
  static const String _channelDescription =
      'Quiet notifications while attendance syncs in the background.';

  /// Monochrome status-bar icon (android/app/src/main/res/drawable). Kept from
  /// resource shrinking by res/raw/keep.xml because it is referenced by name.
  static const String _smallIcon = '@drawable/ic_stat_sync';

  bool _initialized = false;

  /// Initialise the plugin. Safe to call more than once.
  Future<void> init() async {
    if (_initialized) return;
    const androidInit =
        AndroidInitializationSettings(_smallIcon);
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  /// Request notification permission (Android 13+). No-op on older versions,
  /// where notifications are granted at install time. Returns whether granted.
  ///
  /// Never throws: it is called fire-and-forget from the home shell, and a
  /// notification problem must not surface as an app error.
  Future<bool> requestPermission() async {
    try {
      await init();
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android == null) return true;
      final granted = await android.requestNotificationsPermission();
      return granted ?? true;
    } catch (_) {
      return false;
    }
  }

  AndroidNotificationDetails get _quietOngoing => const AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.low,
        priority: Priority.low,
        playSound: false,
        enableVibration: false,
        onlyAlertOnce: true,
        ongoing: true,
        showProgress: true,
        indeterminate: true,
        icon: _smallIcon,
      );

  AndroidNotificationDetails get _quietDone => const AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.low,
        priority: Priority.low,
        playSound: false,
        enableVibration: false,
        onlyAlertOnce: true,
        autoCancel: true,
        icon: _smallIcon,
      );

  /// Show the ongoing "Syncing…" notification.
  Future<void> showSyncing() async {
    await init();
    await _plugin.show(
      _syncingId,
      'Syncing attendance',
      'Uploading saved attendance…',
      NotificationDetails(android: _quietOngoing),
    );
  }

  /// Replace the syncing notification with a brief "synced" confirmation.
  Future<void> showSynced(int count) async {
    await init();
    final label =
        count <= 0 ? 'Attendance synced' : 'Synced $count record${count == 1 ? '' : 's'}';
    await _plugin.show(
      _syncingId,
      label,
      'Your saved attendance is up to date.',
      NotificationDetails(android: _quietDone),
    );
  }

  /// Clear the syncing notification (nothing to report).
  Future<void> clear() async {
    await _plugin.cancel(_syncingId);
  }
}
