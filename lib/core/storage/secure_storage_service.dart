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
  static const _kRefreshToken = 'refresh_token';
  static const _kStaffName = 'staff_name';
  static const _kInstitution = 'institution_name';

  static const _kRememberedStaffId = 'remembered_staff_id';

  /// Persist the values written on a successful login.
  Future<void> saveAuth({
    required String token,
    required String refreshToken,
    required String staffName,
    required String staffId,
    String institutionName = '',
  }) async {
    await Future.wait([
      _storage.write(key: _kToken, value: token),
      _storage.write(key: _kRefreshToken, value: refreshToken),
      _storage.write(key: _kStaffName, value: staffName),
      _storage.write(key: _kInstitution, value: institutionName),
      // Remember the staffId for next time (persists across logout).
      _storage.write(key: _kRememberedStaffId, value: staffId),
    ]);
  }

  /// Replace just the access token after a successful refresh (the refresh
  /// token and everything else are untouched).
  Future<void> updateAccessToken(String token) =>
      _storage.write(key: _kToken, value: token);

  Future<String?> readToken() => _storage.read(key: _kToken);

  Future<String?> readRefreshToken() => _storage.read(key: _kRefreshToken);

  Future<String?> readStaffName() => _storage.read(key: _kStaffName);

  Future<String?> readInstitutionName() => _storage.read(key: _kInstitution);

  /// The remembered staffId for pre-filling the login form (or null).
  Future<String?> readRememberedStaffId() =>
      _storage.read(key: _kRememberedStaffId);

  /// True when an access token is present — used by the auto-login gate.
  Future<bool> hasSession() async {
    final token = await readToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clear() async {
    final remembered = await readRememberedStaffId();
    await _storage.deleteAll();
    if (remembered != null && remembered.isNotEmpty) {
      await _storage.write(key: _kRememberedStaffId, value: remembered);
    }
  }

  /// Fully forget everything including the remembered staffId.
  Future<void> clearAll() => _storage.deleteAll();
}