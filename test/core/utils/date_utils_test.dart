import 'package:eazy_attendance/core/utils/date_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('toIsoDate', () {
    test('formats as yyyy-MM-dd with zero padding (the backend format)', () {
      expect(toIsoDate(DateTime(2026, 1, 5)), '2026-01-05');
      expect(toIsoDate(DateTime(2026, 11, 11)), '2026-11-11');
    });

    test('ignores the time of day', () {
      expect(toIsoDate(DateTime(2026, 3, 9, 23, 59, 59)), '2026-03-09');
    });
  });

  group('parseIsoDate', () {
    test('round-trips with toIsoDate', () {
      final date = parseIsoDate('2026-04-10');
      expect(date, DateTime(2026, 4, 10));
      expect(toIsoDate(date), '2026-04-10');
    });

    test('falls back to today on malformed input', () {
      final today = DateTime.now();
      for (final bad in ['', 'not-a-date', '2026/04/10', '2026-xx-10']) {
        final parsed = parseIsoDate(bad);
        expect(
          [parsed.year, parsed.month, parsed.day],
          [today.year, today.month, today.day],
          reason: 'input "$bad"',
        );
      }
    });
  });

  group('display formats', () {
    test('navDate is short weekday, day and month', () {
      expect(navDate(DateTime(2026, 11, 11)), 'Wed, 11 Nov');
    });

    test('formatDateLong adds the year', () {
      expect(formatDateLong('2026-04-10'), 'Fri, 10 Apr 2026');
      expect(formatDateLong('2026-01-05'), 'Mon, 5 Jan 2026');
    });
  });

  group('initialsOf', () {
    test('takes the first letter of the first two names, upper-cased', () {
      expect(initialsOf('John Doe'), 'JD');
      expect(initialsOf('ama serwaa mensah'), 'AS');
    });

    test('handles extra whitespace, single names and empty input', () {
      expect(initialsOf('  Kofi   Annan '), 'KA');
      expect(initialsOf('Esi'), 'E');
      expect(initialsOf(''), '');
    });
  });
}
