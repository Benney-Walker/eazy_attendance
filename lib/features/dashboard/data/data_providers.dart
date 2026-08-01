import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core_providers.dart';
import '../../auth/application/auth_controller.dart';
import 'levels_repository.dart';

/// Classes repository (local-first read + network refresh).
final levelsRepositoryProvider = Provider<LevelsRepository>((ref) {
  return LevelsRepository(
    ref.watch(apiServiceProvider),
    ref.watch(appDatabaseProvider),
  );
});