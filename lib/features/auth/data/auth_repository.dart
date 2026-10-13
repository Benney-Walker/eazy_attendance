import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import 'auth_models.dart';

class AuthRepository {
  AuthRepository(this._api, this._storage);

  final ApiService _api;
  final SecureStorageService _storage;

  /// Authenticate and persist the session. Returns the staff name on success;
  /// throws a typed [ApiException] on failure.
  Future<String> login({
    required String staffId,
    required String password,
  }) async {
    final request = LoginRequest(staffId: staffId, password: password);

    final Response<dynamic> response;
    try {
      response = await _api.client.post(
        ApiConfig.staffLogin,
        data: request.toJson(),
        options: noAuth(),
      );
    } on DioException catch (e) {

      throw _mapDioException(e);
    }

    final status = response.statusCode ?? 0;
    final body = _asMap(response.data);

    if (status >= 200 && status < 300) {
      final parsed = LoginResponse.fromJson(body);
      if (parsed.authToken.isEmpty) {
        throw const UnexpectedException('Login succeeded but no token was returned.');
      }
      await _storage.saveAuth(
        token: parsed.authToken,
        refreshToken: parsed.refreshToken,
        staffName: parsed.staffName,
        staffId: parsed.staffId,
        institutionName: parsed.institutionName,
      );
      return parsed.staffName;
    }

    if (status == 401) {
      throw UnauthorizedException(
          _stringOr(body['body'], 'Invalid credentials.'));
    }
    if (status == 500) {
      throw ServerException(_stringOr(body['message'], 'Server error.'), 500);
    }
    throw const UnexpectedException();
  }

  /// Clear the stored session (logout, or a 401 elsewhere in the app).
  Future<void> logout() => _storage.clear();

  /// Whether a session token is currently stored (drives auto-login).
  Future<bool> hasSession() => _storage.hasSession();

  Future<String?> currentStaffName() => _storage.readStaffName();

  /// The remembered staffId for pre-filling the login form (persists across
  /// logout). Only the staffId is stored — never the password.
  Future<String?> rememberedStaffId() => _storage.readRememberedStaffId();

  /// The institution name captured at login (or null).
  Future<String?> institutionName() => _storage.readInstitutionName();

  // ── helpers ──

  ApiException _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.unknown:
        return const NetworkException();
      default:
        return const UnexpectedException();
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return data.map((k, v) => MapEntry(k.toString(), v));
    return const {};
  }

  String _stringOr(dynamic value, String fallback) {
    final s = value?.toString().trim() ?? '';
    return s.isEmpty ? fallback : s;
  }
}