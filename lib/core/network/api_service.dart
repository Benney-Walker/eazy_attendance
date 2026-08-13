import 'dart:async';

import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../storage/secure_storage_service.dart';

class ApiService {
  ApiService(this._storage) : _dio = Dio(_baseOptions) {
    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: _attachAuthHeaders,
        onResponse: _onResponse,
      ),
    );
  }

  final SecureStorageService _storage;
  final Dio _dio;

  void Function()? onSessionExpired;
  bool _sessionExpiredFired = false;

  Future<bool>? _refreshInFlight;

  late final Dio _refreshDio = Dio(_baseOptions);

  Dio get client => _dio;

  /// Re-arm the session-expired guard after a fresh login.
  void resetSessionGuard() => _sessionExpiredFired = false;

  static final BaseOptions _baseOptions = BaseOptions(
    baseUrl: ApiConfig.baseApi,
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 20),
    sendTimeout: const Duration(seconds: 20),
    // We validate status codes ourselves so non-2xx responses don't throw
    // before we can read the server's error body / handle 401.
    validateStatus: (_) => true,
    headers: {'Content-Type': 'application/json'},
  );

  /// Attaches auth headers when a token is present, unless the request opts out
  /// via `extra['requiresAuth'] == false` (the login and refresh calls).
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

  /// On a 401 from an authenticated request, try to refresh + retry once.
  /// The login/refresh calls themselves (requiresAuth == false) are exempt, so
  /// a wrong-password 401 stays a normal login error.
  Future<void> _onResponse(
      Response response,
      ResponseInterceptorHandler handler,
      ) async {
    final options = response.requestOptions;
    final requiresAuth = options.extra['requiresAuth'] != false;
    final alreadyRetried = options.extra['__retried'] == true;

    if (response.statusCode != 401 || !requiresAuth || alreadyRetried) {
      handler.next(response);
      return;
    }

    // Attempt a token refresh (shared across concurrent 401s).
    final refreshed = await _refreshAccessToken();
    if (!refreshed) {
      // Refresh failed → session is genuinely over.
      _fireSessionExpired();
      handler.next(response); // let the original 401 propagate to the caller
      return;
    }

    try {
      final newToken = await _storage.readToken();
      final staffId = await _storage.readStaffId();
      final retryHeaders = Map<String, dynamic>.from(options.headers)
        ..['Authorization'] = 'Bearer $newToken';
      if (staffId != null && staffId.isNotEmpty) {
        retryHeaders['staffId'] = staffId;
      }
      final retryOptions = Options(
        method: options.method,
        headers: retryHeaders,
        responseType: options.responseType,
        contentType: options.contentType,
        sendTimeout: options.sendTimeout,
        receiveTimeout: options.receiveTimeout,
        extra: Map<String, dynamic>.from(options.extra)..['__retried'] = true,
        validateStatus: options.validateStatus,
      );
      final retried = await _refreshDio.request<dynamic>(
        options.path,
        data: options.data,
        queryParameters: options.queryParameters,
        options: retryOptions,
      );
      handler.resolve(retried);
    } on DioException catch (e) {
      if (e.response != null) {
        handler.next(e.response!);
      } else {
        handler.reject(e);
      }
    }
  }

  /// Refresh the access token using the stored refresh token. Returns true on
  /// success (new access token saved). Single-flight: concurrent callers share
  /// one in-flight refresh.
  Future<bool> _refreshAccessToken() {
    return _refreshInFlight ??= _doRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<bool> _doRefresh() async {
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final resp = await _refreshDio.post<dynamic>(
        ApiConfig.refreshToken,
        data: {'refreshToken': refreshToken},
        options: Options(extra: const {'requiresAuth': false}),
      );
      final status = resp.statusCode ?? 0;
      if (status >= 200 && status < 300) {
        final data = resp.data;
        final newToken =
            (data is Map ? data['authToken'] : null)?.toString() ?? '';
        if (newToken.isEmpty) return false;
        await _storage.updateAccessToken(newToken);
        return true;
      }
      // 401 (invalid/expired refresh token) or anything else → failed.
      return false;
    } on DioException {
      // Network failure during refresh: treat as not-refreshed. We do NOT wipe
      // the session here — a transient network drop shouldn't force logout; the
      // caller simply gets the original 401 and can retry when back online.
      return false;
    }
  }

  void _fireSessionExpired() {
    if (_sessionExpiredFired) return;
    _sessionExpiredFired = true;
    onSessionExpired?.call();
  }
}

/// Convenience [Options] builder for endpoints that must NOT carry auth headers
/// (staff-login and refresh-token, which run without/around the access token).
Options noAuth() => Options(extra: const {'requiresAuth': false});