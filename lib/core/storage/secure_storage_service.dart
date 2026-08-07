import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService([FlutterSecureStorage? storage])
      : _storage = storage ??
      const FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
        ),
      );

  final FlutterSecureStorage _storage;

  static const _kToken = 'auth_token';
  static const _kStaffName = 'staff_name';
  static const _kStaffId = 'staff_id';

  /// The last staffId used to sign in. Unlike the session keys above, this
  /// deliberately SURVIVES logout / 401 so the login screen can pre-fill it for
  /// convenience. Only the staffId is remembered — never the password.
  static const _kRememberedStaffId = 'remembered_staff_id';

  /// Persist the three auth values written on a successful login.
  Future<void> saveAuth({
    required String token,
    required String staffName,
    required String staffId,
  }) async {
    await Future.wait([
      _storage.write(key: _kToken, value: token),
      _storage.write(key: _kStaffName, value: staffName),
      _storage.write(key: _kStaffId, value: staffId),
      // Remember the staffId for next time (persists across logout).
      _storage.write(key: _kRememberedStaffId, value: staffId),
    ]);
  }

  Future<String?> readToken() => _storage.read(key: _kToken);

  Future<String?> readStaffName() => _storage.read(key: _kStaffName);

  Future<String?> readStaffId() => _storage.read(key: _kStaffId);

  /// The remembered staffId for pre-filling the login form (or null).
  Future<String?> readRememberedStaffId() =>
      _storage.read(key: _kRememberedStaffId);

  /// True when a JWT is present — used by the auto-login gate.
  Future<bool> hasSession() async {
    final token = await readToken();
    return token != null && token.isNotEmpty;
  }

  /// Clear the SESSION (logout / 401), but keep the remembered staffId so the
  /// login screen can pre-fill it. Reads the remembered value, wipes storage,
  /// then restores just that one key.
  Future<void> clear() async {
    final remembered = await readRememberedStaffId();
    await _storage.deleteAll();
    if (remembered != null && remembered.isNotEmpty) {
      await _storage.write(key: _kRememberedStaffId, value: remembered);
    }
  }

  /// Fully forget everything including the remembered staffId (not used by the
  /// normal logout flow; provided for completeness / a "forget me" action).
  Future<void> clearAll() => _storage.deleteAll();
}