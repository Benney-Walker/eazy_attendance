class ApiConfig {
  ApiConfig._();

  static const bool useLocal = false;

  static const String _localApi = 'http://localhost:8080';
  static const String _productionApi =
      'https://schoolmanagementsystem-eazymanage.up.railway.app';

  /// Base API URL, e.g. `https://.../api`. Matches the website's `BASE_API`.
  static String get baseApi => '${useLocal ? _localApi : _productionApi}/api';

  /// POST — body: { staffId, password } → { authToken, staffName, staffId }.
  static const String staffLogin = '/auth/v1/staff-login';

  /// GET — header: staffId → List<{ levelId, levelName }>.
  static const String loadLevels = '/staff/v1/load-levels';

  /// GET — `/student/v1/load-students-for-attendance/{classId}/{date}`.
  static const String loadStudentsForAttendance =
      '/student/v1/load-students-for-attendance';

  /// POST — body: List<{ studentId, status }>.
  static const String markAttendance = '/student/v2/mark-attendance';
}