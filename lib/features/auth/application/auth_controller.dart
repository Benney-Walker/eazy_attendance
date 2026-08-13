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

/// Immutable snapshot of who (if anyone) is signed in.
class AuthState {
  const AuthState({required this.status, this.staffName});

  final AuthStatus status;
  final String? staffName;

  const AuthState.unknown()
      : status = AuthStatus.unknown,
        staffName = null;

  AuthState copyWith({AuthStatus? status, String? staffName}) => AuthState(
    status: status ?? this.status,
    staffName: staffName ?? this.staffName,
  );
}

/// Owns the session lifecycle: restore-on-launch (auto-login), login, logout.
///
/// The UI watches [authControllerProvider] for routing (gate) and calls
/// [login] / [logout]. Transient login progress/errors are handled locally by
/// the login screen via [AsyncValue]; this notifier holds the durable status.
class AuthController extends AsyncNotifier<AuthState> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Future<AuthState> build() async {
    // Wire the session-expired handler: this fires only when a token REFRESH
    // fails (refresh token invalid/expired after ~1 week) — not on an ordinary
    // access-token 401, which ApiService refreshes and retries transparently.
    // When it fires, clear the session so the AuthGate routes to login. The
    // sync queue is left intact so unsynced attendance survives.
    ref.read(apiServiceProvider).onSessionExpired = _handleSessionExpired;

    return _restoreSession();
  }

  void _handleSessionExpired() {
    // ignore: discarded_futures
    _sessionExpiredLogout();
  }

  Future<void> _sessionExpiredLogout() async {
    await _repo.logout(); // clears tokens, keeps remembered staffId + sync queue
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

  /// The remembered staffId to pre-fill the login form (or null). Only the
  /// staffId is ever stored — never the password.
  Future<String?> rememberedStaffId() => _repo.rememberedStaffId();

  /// Attempt a login. On success, flips global state to authenticated.
  Future<void> login({
    required String staffId,
    required String password,
  }) async {
    final staffName = await _repo.login(staffId: staffId, password: password);
    // Re-arm the session guard so a future refresh-failure triggers logout.
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