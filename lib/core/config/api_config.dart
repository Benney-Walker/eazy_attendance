class ApiConfig {
  ApiConfig._();

  static const bool useLocal = false;

  static const String _localApi = 'http://localhost:8080';
  static const String _productionApi =
      'https://schoolmanagementsystem-eazymanage.up.railway.app';

  static String get baseApi => '${useLocal ? _localApi : _productionApi}/api';

  static const String staffLogin = '/auth/v1/staff-login';

  static const String refreshToken = '/auth/v1/refresh-token';

  static const String loadLevels = '/staff/v1/load-levels';

  static const String loadStudentsForAttendance =
      '/student/v1/load-students-for-attendance';

  static const String markAttendance = '/student/v2/mark-attendance';
}