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
      InterceptorsWrapper(onRequest: _attachAuthHeaders),
    );
  }

  final SecureStorageService _storage;
  final Dio _dio;

  /// Exposed so repositories can issue calls: `apiService.client.post(...)`.
  Dio get client => _dio;

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
}

/// Convenience [Options] builder for endpoints that must NOT carry auth headers
/// (currently just staff-login, which runs before a token exists).
Options noAuth() => Options(extra: const {'requiresAuth': false});
