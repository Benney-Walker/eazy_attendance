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
    // Wire the global 401 handler: when any authenticated request comes back
    // 401 (expired/invalid token), clear the session so the AuthGate routes to
    // login. The sync queue is intentionally left intact — unsynced attendance
    // survives and uploads after the next login.
    ref.read(apiServiceProvider).onUnauthorized = _handleUnauthorized;

    // Runs once on first read (app launch): decide the initial route.
    return _restoreSession();
  }

  void _handleUnauthorized() {
    // Fire-and-forget: clear the session and flip to unauthenticated. Guarded
    // in ApiService so this only runs once per expiry.
    // ignore: discarded_futures
    _sessionExpiredLogout();
  }

  Future<void> _sessionExpiredLogout() async {
    await _repo.logout(); // clears token, keeps remembered staffId + sync queue
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
  /// Rethrows the typed [ApiException] so the caller can show a message while
  /// keeping global state untouched on failure.
  Future<void> login({
    required String staffId,
    required String password,
  }) async {
    final staffName = await _repo.login(staffId: staffId, password: password);
    // Re-arm the 401 guard so a future token expiry triggers logout again.
    ref.read(apiServiceProvider).resetUnauthorizedGuard();
    state = AsyncData(
      AuthState(status: AuthStatus.authenticated, staffName: staffName),
    );
  }

  /// Clear the session and return to the unauthenticated state.
  Future<void> logout() async {
    await _repo.logout();
    ref.read(apiServiceProvider).resetUnauthorizedGuard();
    state = const AsyncData(AuthState(status: AuthStatus.unauthenticated));
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthState>(AuthController.new);
