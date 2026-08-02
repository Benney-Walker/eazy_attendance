/// Central network configuration.
///
/// Mirrors the website's `utils/auth.js` (BASE_API = PRODUCTION_API + '/api').
/// No URL is ever hardcoded inside a widget or service — everything routes
/// through here so switching environments is a one-line change.
class ApiConfig {
  ApiConfig._();

  /// Flip to target the local backend during development.
  /// (On a physical device, `localhost` is the phone itself; use the machine's
  /// LAN IP, or `10.0.2.2` for the Android emulator, when needed.)
  static const bool useLocal = false;

  static const String _localApi = 'http://localhost:8080';
  static const String _productionApi =
      'https://schoolmanagementsystem-eazymanage.up.railway.app';

  /// Base API URL, e.g. `https://.../api`. Matches the website's `BASE_API`.
  static String get baseApi => '${useLocal ? _localApi : _productionApi}/api';

  // ---------------------------------------------------------------------------
  // Endpoint paths (relative to [baseApi]). Copied verbatim from the website so
  // the Spring Boot contract stays identical. Wired up in later phases.
  // ---------------------------------------------------------------------------

  /// POST — body: { staffId, password } → { authToken, staffName, staffId }.
  static const String staffLogin = '/auth/v1/staff-login';

  /// GET — header: staffId → List<{ levelId, levelName }>.
  static const String loadLevels = '/staff/v1/load-levels';

  /// GET — `/student/v1/load-students-for-attendance/{levelId}/{date}`
  ///        → List<{ studentId, studentName, status }>.
  static const String loadStudentsForAttendance =
      '/student/v1/load-students-for-attendance';

  /// POST — headers: staffId, selectedDate, levelId;
  ///        body: List<{ studentId, status }>.
  static const String markAttendance = '/student/v2/mark-attendance';
}
