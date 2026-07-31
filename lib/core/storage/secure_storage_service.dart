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
    ]);
  }

  Future<String?> readToken() => _storage.read(key: _kToken);

  Future<String?> readStaffName() => _storage.read(key: _kStaffName);

  Future<String?> readStaffId() => _storage.read(key: _kStaffId);

  /// True when a JWT is present — used by the auto-login gate.
  Future<bool> hasSession() async {
    final token = await readToken();
    return token != null && token.isNotEmpty;
  }

  /// Clear everything (logout / 401). Equivalent to the website's `clearAuth`.
  Future<void> clear() => _storage.deleteAll();
}