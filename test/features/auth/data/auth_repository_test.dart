import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:eazy_attendance/core/network/api_exception.dart';
import 'package:eazy_attendance/core/network/api_service.dart';
import 'package:eazy_attendance/core/storage/secure_storage_service.dart';
import 'package:eazy_attendance/features/auth/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers every request with a fixed status and JSON body, and records the
/// last request so tests can assert on what was sent.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter({this.status = 200, this.body = const {}, this.error});

  final int status;
  final Object body;
  final DioExceptionType? error;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    if (error != null) {
      throw DioException(requestOptions: options, type: error!);
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// In-memory stand-in for the platform keystore.
class _FakeStorage extends SecureStorageService {
  Map<String, String>? saved;

  @override
  Future<void> saveAuth({
    required String token,
    required String refreshToken,
    required String staffName,
    required String staffId,
    required String institutionName,
  }) async {
    saved = {
      'token': token,
      'refreshToken': refreshToken,
      'staffName': staffName,
      'staffId': staffId,
      'institutionName': institutionName,
    };
  }

  @override
  Future<String?> readToken() async => null;
}

void main() {
  late _FakeStorage storage;
  late ApiService api;

  AuthRepository repositoryWith(_FakeAdapter adapter) {
    api.client.httpClientAdapter = adapter;
    return AuthRepository(api, storage);
  }

  setUp(() {
    storage = _FakeStorage();
    api = ApiService(storage);
  });

  test('stores the session and remembers the typed staff ID', () async {
    // The backend's login response does not include staffId.
    final adapter = _FakeAdapter(body: {
      'staffName': 'AMA MENSAH',
      'roles': ['TEACHING_STAFF'],
      'institutionName': 'DAFFODILS INTERNATIONAL SCHOOL',
      'authToken': 'access',
      'refreshToken': 'refresh',
    });

    final name = await repositoryWith(adapter)
        .login(staffId: 'STF001', password: 'secret');

    expect(name, 'AMA MENSAH');
    expect(storage.saved, {
      'token': 'access',
      'refreshToken': 'refresh',
      'staffName': 'AMA MENSAH',
      'staffId': 'STF001',
      'institutionName': 'DAFFODILS INTERNATIONAL SCHOOL',
    });
    expect(adapter.lastRequest?.path, '/auth/v1/staff-login');
    expect(adapter.lastRequest?.headers['Authorization'], isNull);
  });

  test('surfaces the server message on 401', () async {
    final adapter = _FakeAdapter(status: 401, body: {
      'message': 'You are not allowed to access the system! Contact your admin',
    });

    await expectLater(
      repositoryWith(adapter).login(staffId: 'STF002', password: 'x'),
      throwsA(isA<UnauthorizedException>().having(
        (e) => e.message,
        'message',
        'You are not allowed to access the system! Contact your admin',
      )),
    );
    expect(storage.saved, isNull);
  });

  test('falls back to a generic message on a 401 without one', () async {
    final adapter = _FakeAdapter(status: 401, body: const {});

    await expectLater(
      repositoryWith(adapter).login(staffId: 'STF002', password: 'x'),
      throwsA(isA<UnauthorizedException>()
          .having((e) => e.message, 'message', 'Invalid credentials.')),
    );
  });

  test('rejects a 2xx response without a token', () async {
    final adapter = _FakeAdapter(body: {'staffName': 'AMA MENSAH'});

    await expectLater(
      repositoryWith(adapter).login(staffId: 'STF001', password: 'secret'),
      throwsA(isA<UnexpectedException>()),
    );
    expect(storage.saved, isNull);
  });

  test('maps a connection failure to NetworkException', () async {
    final adapter = _FakeAdapter(error: DioExceptionType.connectionError);

    await expectLater(
      repositoryWith(adapter).login(staffId: 'STF001', password: 'secret'),
      throwsA(isA<NetworkException>()),
    );
  });
}
