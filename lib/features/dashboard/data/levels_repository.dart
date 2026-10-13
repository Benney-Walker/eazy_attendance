import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/config/api_config.dart';
import '../../../core/database/app_database.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_service.dart';
import 'level_models.dart';

class LevelsRepository {
  LevelsRepository(this._api, this._db);

  final ApiService _api;
  final AppDatabase _db;

  /// Cached classes (may be empty on a first-ever launch before any refresh).
  Future<List<LevelModel>> getCached() async {
    final rows = await _db.getLevels();
    return rows
        .map((r) => LevelModel(id: r.levelId, name: r.levelName))
        .toList();
  }

  /// Fetch from the backend, update the cache, and return the fresh list.
  /// Throws a typed [ApiException] on failure (caller can fall back to cache).
  Future<List<LevelModel>> refresh() async {
    final Response<dynamic> response;
    try {
      response = await _api.client.get(ApiConfig.loadLevels);
    } on DioException {
      throw const NetworkException();
    }

    final status = response.statusCode ?? 0;
    final message = response.statusMessage.toString() ?? '';
    if (status == 401) throw const UnauthorizedException();
    if (status < 200 || status >= 300) {
      throw ServerException('Failed to load classes.', status);
    }

    final data = response.data;
    if (data is! List) throw const UnexpectedException();

    final models = data
        .whereType<Map>()
        .map((m) => LevelModel(
              id: (m['levelId'] ?? '').toString(),
              name: (m['levelName'] ?? '').toString(),
            ))
        .where((l) => l.id.isNotEmpty)
        .toList();

    await _db.replaceLevels(
      models
          .map((l) => LevelsCompanion.insert(levelId: l.id, levelName: l.name))
          .toList(),
    );

    return models;
  }
}
