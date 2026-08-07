import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../storage/secure_storage_service.dart';

/// The single reusable HTTP client for the whole app. Every network call goes
/// through here — no screen or repository constructs its own Dio.
///
/// An interceptor automatically attaches the JWT (`Authorization: Bearer …`)
/// and `staffId` header to authenticated requests, so callers never assemble
/// auth headers by hand. The base URL and timeouts are centralised.
class ApiService {
  ApiService(this._storage) : _dio = Dio(_baseOptions) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _attachAuthHeaders,
        onResponse: _detectUnauthorized,
      ),
    );
  }

  final SecureStorageService _storage;
  final Dio _dio;

  /// Called once when any authenticated request comes back 401 (expired/invalid
  /// token). The auth layer sets this to clear the session and route to login.
  /// Guarded so a burst of 401s (e.g. several queued syncs) only fires once
  /// until re-armed on the next successful login.
  void Function()? onUnauthorized;
  bool _unauthorizedFired = false;

  /// Exposed so repositories can issue calls: `apiService.client.post(...)`.
  Dio get client => _dio;

  /// Re-arm the 401 handler after a fresh login, so a future expiry fires again.
  void resetUnauthorizedGuard() => _unauthorizedFired = false;

  static final BaseOptions _baseOptions = BaseOptions(
    baseUrl: ApiConfig.baseApi,
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 20),
    sendTimeout: const Duration(seconds: 20),
    // We validate status codes ourselves in repositories so that non-2xx
    // responses don't throw before we can read the server's error body.
    validateStatus: (_) => true,
    headers: {'Content-Type': 'application/json'},
  );

  /// Attaches auth headers when a token is present, unless the request opts out
  /// via `extra['requiresAuth'] == false` (e.g. the login call itself).
  Future<void> _attachAuthHeaders(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final requiresAuth = options.extra['requiresAuth'] != false;
    if (requiresAuth) {
      final token = await _storage.readToken();
      final staffId = await _storage.readStaffId();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      if (staffId != null && staffId.isNotEmpty) {
        options.headers['staffId'] = staffId;
      }
    }
    handler.next(options);
  }

  /// Fires [onUnauthorized] on a 401 from an authenticated request. The login
  /// call itself (requiresAuth == false) is exempt so a wrong-password 401
  /// stays a normal login error, not a global session wipe.
  void _detectUnauthorized(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    final requiresAuth =
        response.requestOptions.extra['requiresAuth'] != false;
    if (requiresAuth &&
        response.statusCode == 401 &&
        !_unauthorizedFired) {
      _unauthorizedFired = true;
      onUnauthorized?.call();
    }
    handler.next(response);
  }
}

/// Convenience [Options] builder for endpoints that must NOT carry auth headers
/// (currently just staff-login, which runs before a token exists).
Options noAuth() => Options(extra: const {'requiresAuth': false});
