import 'package:eazy_attendance/features/attendance/application/attendance_controller.dart';
import 'package:eazy_attendance/features/dashboard/data/level_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const students = [
    StudentModel(id: 'STD1', name: 'Ama Mensah'),
    StudentModel(id: 'STD2', name: 'Kofi Boateng'),
    StudentModel(id: 'STD3', name: 'Esi Owusu'),
  ];

  group('AttendanceState', () {
    test('derives totals and a rounded percentage from the marks', () {
      const state = AttendanceState(
        students: students,
        marks: {'STD1': true, 'STD2': true, 'STD3': false},
        loading: false,
      );

      expect(state.total, 3);
      expect(state.present, 2);
      expect(state.absent, 1);
      expect(state.percent, 67);
    });

    test('reports 0% for an empty class instead of dividing by zero', () {
      const state = AttendanceState(students: [], marks: {}, loading: false);
      expect(state.percent, 0);
    });

    test('copyWith keeps the error unless one is passed, and can clear it', () {
      const state = AttendanceState(
        students: students,
        marks: {},
        error: 'Could not save attendance. Please try again.',
      );

      expect(state.copyWith(saving: true).error, state.error);
      expect(state.copyWith(error: null).error, isNull);
    });
  });

  group('AttendanceArgs', () {
    test('identity is class + date + name; the pre-loaded roster is ignored',
        () {
      const plain = AttendanceArgs(
        levelId: 'LVL1',
        date: '2026-11-11',
        className: 'JHS 1',
      );
      const seeded = AttendanceArgs(
        levelId: 'LVL1',
        date: '2026-11-11',
        className: 'JHS 1',
        initialStudents: students,
        initialFromCache: true,
      );

      expect(seeded, plain);
      expect(seeded.hashCode, plain.hashCode);
    });

    test('a different date is a different session', () {
      const today = AttendanceArgs(
          levelId: 'LVL1', date: '2026-11-11', className: 'JHS 1');
      const yesterday = AttendanceArgs(
          levelId: 'LVL1', date: '2026-11-10', className: 'JHS 1');

      expect(today == yesterday, isFalse);
    });
  });
}
