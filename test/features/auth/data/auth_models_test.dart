import 'package:eazy_attendance/features/auth/data/auth_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoginRequest', () {
    test('serialises the exact keys staff-login expects', () {
      const request = LoginRequest(staffId: 'STF001', password: 'secret');
      expect(request.toJson(), {'staffId': 'STF001', 'password': 'secret'});
    });
  });

  group('LoginResponse.fromJson', () {
    test('parses the current backend payload, which has no staffId', () {
      final response = LoginResponse.fromJson({
        'staffName': 'AMA MENSAH',
        'roles': ['TEACHING_STAFF'],
        'institutionName': 'DAFFODILS INTERNATIONAL SCHOOL',
        'authToken': 'access',
        'refreshToken': 'refresh',
      });

      expect(response.authToken, 'access');
      expect(response.refreshToken, 'refresh');
      expect(response.staffName, 'AMA MENSAH');
      expect(response.institutionName, 'DAFFODILS INTERNATIONAL SCHOOL');
      expect(response.roles, ['TEACHING_STAFF']);
      expect(response.staffId, isEmpty);
    });

    test('tolerates missing or null fields', () {
      final response = LoginResponse.fromJson({'roles': null});

      expect(response.authToken, isEmpty);
      expect(response.refreshToken, isEmpty);
      expect(response.staffName, isEmpty);
      expect(response.institutionName, isEmpty);
      expect(response.roles, isEmpty);
    });
  });
}
