import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../dashboard/data/level_models.dart';
import '../data/students_repository.dart';
import '../data/attendance_data_providers.dart';

/// Result of a Load Students action.
class LoadStudentsResult {
  const LoadStudentsResult({required this.students, required this.fromCache});

  final List<StudentModel> students;

  /// True when served from local cache because the network was unreachable.
  final bool fromCache;
}

/// Handles the dashboard's "Load Students" action: fetch the roster for a
/// (level, date), local-first. Tries the network; on failure falls back to the
/// cached roster so the teacher can still proceed offline.
class LoadStudentsController {
  LoadStudentsController(this._repo);

  final StudentsRepository _repo;

  Future<LoadStudentsResult> load(String levelId, String date) async {
    try {
      final students = await _repo.refresh(levelId, date);
      return LoadStudentsResult(students: students, fromCache: false);
    } on ApiException {
      final cached = await _repo.getCached(levelId, date);
      if (cached.isEmpty) {
        // Nothing online and nothing cached — surface the failure.
        rethrow;
      }
      return LoadStudentsResult(students: cached, fromCache: true);
    }
  }
}

final loadStudentsControllerProvider = Provider<LoadStudentsController>((ref) {
  return LoadStudentsController(ref.watch(studentsRepositoryProvider));
});