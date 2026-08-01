class LevelModel {
  const LevelModel({required this.id, required this.name});

  final String id;
  final String name;
}

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