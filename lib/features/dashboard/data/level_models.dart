/// A class/level the staff can take attendance for. Mirrors the website's
/// `{ id, name }` shape (from backend `{ levelId, levelName }`).
class LevelModel {
  const LevelModel({required this.id, required this.name});

  final String id;
  final String name;
}

/// A student in a roster. Mirrors the website's `{ id, name, status }`
/// (from backend `{ studentId, studentName, status }`). `presentByDefault`
/// carries the backend's last-known status so a freshly loaded class reflects
/// server state until the staff changes it.
class StudentModel {
  const StudentModel({
    required this.id,
    required this.name,
    this.presentByDefault = false,
  });

  final String id;
  final String name;
  final bool presentByDefault;
}
