import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core_providers.dart';
import '../data/auth_repository.dart';

// ── Repository provider ─────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiServiceProvider),
    ref.watch(secureStorageProvider),
  );
});

// ── Auth state ──────────────────────────────────────────────────────────────

/// High-level authentication status for the whole app.
enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({required this.status, this.staffName, this.institutionName});

  final AuthStatus status;
  final String? staffName;
  final String? institutionName;

  const AuthState.unknown()
      : status = AuthStatus.unknown,
        staffName = null,
        institutionName = null;

  AuthState copyWith({AuthStatus? status, String? staffName, String? institutionName}) => AuthState(
    status: status ?? this.status,
    staffName: staffName ?? this.staffName,
    institutionName: institutionName ?? this.institutionName
  );
}

class AuthController extends AsyncNotifier<AuthState> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Future<AuthState> build() async {

    ref.read(apiServiceProvider).onSessionExpired = _handleSessionExpired;

    return _restoreSession();
  }

  void _handleSessionExpired() {
    _sessionExpiredLogout();
  }

  Future<void> _sessionExpiredLogout() async {
    await _repo.logout(); // clears tokens
    state = const AsyncData(AuthState(status: AuthStatus.unauthenticated));
  }

  Future<AuthState> _restoreSession() async {
    final hasSession = await _repo.hasSession();
    if (!hasSession) {
      return const AuthState(status: AuthStatus.unauthenticated);
    }
    final name = await _repo.currentStaffName();
    return AuthState(status: AuthStatus.authenticated, staffName: name);
  }

  Future<String?> rememberedStaffId() => _repo.rememberedStaffId();

  /// Attempt a login. On success, flips global state to authenticated.
  Future<void> login({
    required String staffId,
    required String password,
  }) async {
    final staffName = await _repo.login(staffId: staffId, password: password);

    ref.read(apiServiceProvider).resetSessionGuard();
    state = AsyncData(
      AuthState(status: AuthStatus.authenticated, staffName: staffName),
    );
  }

  /// Clear the session and return to the unauthenticated state.
  Future<void> logout() async {
    await _repo.logout();
    ref.read(apiServiceProvider).resetSessionGuard();
    state = const AsyncData(AuthState(status: AuthStatus.unauthenticated));
  }
}

final authControllerProvider =
AsyncNotifierProvider<AuthController, AuthState>(AuthController.new);