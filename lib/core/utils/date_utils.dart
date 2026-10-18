String toIsoDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String todayIso() => toIsoDate(DateTime.now());

DateTime parseIsoDate(String iso) {
  final parts = iso.split('-');
  if (parts.length == 3) {
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y != null && m != null && d != null) {
      return DateTime(y, m, d);
    }
  }
  return DateTime.now();
}

const List<String> _weekdays = [
  'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
];

const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Short human-readable date for the nav bar, e.g. "Mon, 4 Aug".
String navDate(DateTime date) {
  final wd = _weekdays[date.weekday - 1];
  final mo = _months[date.month - 1];
  return '$wd, ${date.day} $mo';
}

/// Long human-readable date including the year, e.g. "Thu, 10 Apr 2026" —
/// matches the website's `formatDateLong` used on the attendance screen.
String formatDateLong(String iso) {
  final date = parseIsoDate(iso);
  final wd = _weekdays[date.weekday - 1];
  final mo = _months[date.month - 1];
  return '$wd, ${date.day} $mo ${date.year}';
}

/// Initials from a full name: "John Doe" → "JD" (max two letters), matching
/// the website's `getInitials`.
String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  final letters = parts.take(2).map((w) => w[0]).join();
  return letters.toUpperCase();
}
