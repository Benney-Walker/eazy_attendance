class ApiConfig {
  ApiConfig._();

  static const bool useLocal = false;

  static const String LOCAL_URL = 'http://localhost:8080';

  static const String PRODUCTION_URL = 'https://schoolmanagementsystem-production-46c3.up.railway.app';

  static String get baseApi => '${useLocal ? LOCAL_URL : PRODUCTION_URL}/api';

  static const String staffLogin = '/auth/v1/staff-login';

  static const String refreshToken = '/auth/v1/refresh-token';

  static const String loadLevels = '/staff/v1/load-levels';

  static const String loadStudentsForAttendance =
      '/student/v1/load-students-for-attendance';

  static const String markAttendance = '/student/v2/mark-attendance';
}