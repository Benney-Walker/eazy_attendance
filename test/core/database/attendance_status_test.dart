import 'package:eazy_attendance/core/database/attendance_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AttendanceStatus', () {
    test('uses the exact wire strings mark-attendance expects', () {
      expect(AttendanceStatus.present.wire, 'PRESENT');
      expect(AttendanceStatus.absent.wire, 'ABSENT');
    });

    test('maps UI booleans both ways', () {
      expect(AttendanceStatus.fromBool(true), AttendanceStatus.present);
      expect(AttendanceStatus.fromBool(false), AttendanceStatus.absent);
      expect(AttendanceStatus.present.isPresent, isTrue);
      expect(AttendanceStatus.absent.isPresent, isFalse);
    });

    test('treats anything but "PRESENT" as absent, like the website', () {
      expect(AttendanceStatus.fromWire('PRESENT'), AttendanceStatus.present);
      expect(AttendanceStatus.fromWire('ABSENT'), AttendanceStatus.absent);
      expect(AttendanceStatus.fromWire('present'), AttendanceStatus.absent);
      expect(AttendanceStatus.fromWire(null), AttendanceStatus.absent);
    });
  });

  group('SyncJobStatus', () {
    test('parses stored values and defaults unknown ones to pending', () {
      expect(SyncJobStatus.fromWire('PENDING'), SyncJobStatus.pending);
      expect(SyncJobStatus.fromWire('SYNCING'), SyncJobStatus.syncing);
      expect(SyncJobStatus.fromWire('FAILED'), SyncJobStatus.failed);
      expect(SyncJobStatus.fromWire('UNKNOWN'), SyncJobStatus.pending);
      expect(SyncJobStatus.fromWire(null), SyncJobStatus.pending);
    });
  });
}
