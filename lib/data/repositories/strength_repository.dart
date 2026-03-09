import '../database/database_manager.dart';

class StrengthRepository {
  final AppDatabase _db = DatabaseManager.instance;

  // 添加力量训练记录
  Future<int> addStrengthRecord({
    required DateTime date,
    required String splitType,
    required int durationMinutes,
    required double totalVolume,
    required List<Map<String, dynamic>> exerciseSets,
  }) async {
    return await _db.transaction(() async {
      final recordId = await _db.into(_db.strengthRecords).insert(
        StrengthRecordsCompanion.insert(
          date: date,
          splitType: splitType,
          durationMinutes: durationMinutes,
          totalVolume: totalVolume,
        ),
      );

      // 插入动作组记录
      for (var setData in exerciseSets) {
        await _db.into(_db.exerciseSets).insert(
          ExerciseSetsCompanion.insert(
            strengthRecordId: recordId,
            exerciseName: setData['exerciseName'] as String,
            setNumber: setData['setNumber'] as int,
            weight: setData['weight'] as double,
            reps: setData['reps'] as int,
            rpe: Value(setData['rpe'] as int?),
          ),
        );
      }

      return recordId;
    });
  }

  // 获取所有力量训练记录
  Future<List<StrengthRecord>> getAllStrengthRecords() async {
    return await (_db.select(_db.strengthRecords)
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
        )
        .get();
  }

  // 按日期范围获取力量训练记录
  Future<List<StrengthRecord>> getStrengthRecordsByDateRange(DateTime start, DateTime end) async {
    return await (_db.select(_db.strengthRecords)
          ..where((t) => t.date.isBiggerOrEqualValue(start))
          ..where((t) => t.date.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
        )
        .get();
  }

  // 获取本周力量训练记录
  Future<List<StrengthRecord>> getWeekStrengthRecords(DateTime weekStart) async {
    final weekEnd = weekStart.add(const Duration(days: 7));
    return await (_db.select(_db.strengthRecords)
          ..where((t) => t.date.isBiggerOrEqualValue(weekStart))
          ..where((t) => t.date.isSmallerThanValue(weekEnd))
          ..orderBy([(t) => OrderingTerm.asc(t.date)])
        )
        .get();
  }

  // 根据ID获取力量训练记录及其动作组
  Future<Map<String, dynamic>?> getStrengthRecordWithSets(int id) async {
    final record = await (_db.select(_db.strengthRecords)
          ..where((t) => t.id.equals(id))
        )
        .getSingleOrNull();

    if (record == null) return null;

    final sets = await (_db.select(_db.exerciseSets)
          ..where((t) => t.strengthRecordId.equals(id))
          ..orderBy([(t) => OrderingTerm.asc(t.exerciseName)])
          ..orderBy([(t) => OrderingTerm.asc(t.setNumber)])
        )
        .get();

    return {
      'record': record,
      'sets': sets,
    };
  }

  // 获取特定动作的历史记录
  Future<List<Map<String, dynamic>>> getExerciseHistory(String exerciseName) async {
    final sets = await (_db.select(_db.exerciseSets)
          ..where((t) => t.exerciseName.equals(exerciseName))
        )
        .get();

    // 获取对应的训练记录
    final recordIds = sets.map((s) => s.strengthRecordId).toSet();
    final records = await (_db.select(_db.strengthRecords)
          ..where((t) => t.id.isIn(recordIds))
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
        )
        .get();

    // 按训练记录分组
    final Map<int, List<ExerciseSet>> setsByRecord = {};
    for (var set in sets) {
      setsByRecord.putIfAbsent(set.strengthRecordId, () => []);
      setsByRecord[set.strengthRecordId]!.add(set);
    }

    // 组合结果
    final result = <Map<String, dynamic>>[];
    for (var record in records) {
      final recordSets = setsByRecord[record.id] ?? [];
      final exerciseSets = recordSets.where((s) => s.exerciseName == exerciseName).toList();
      
      if (exerciseSets.isNotEmpty) {
        // 计算该动作当天的最佳表现（最大重量）
        final maxWeight = exerciseSets.map((s) => s.weight).reduce((a, b) => a > b ? a : b);
        final maxReps = exerciseSets.where((s) => s.weight == maxWeight).map((s) => s.reps).reduce((a, b) => a > b ? a : b);
        
        result.add({
          'date': record.date,
          'splitType': record.splitType,
          'maxWeight': maxWeight,
          'maxReps': maxReps,
          'sets': exerciseSets,
        });
      }
    }

    return result;
  }

  // 使用Epley公式估算1RM
  static double calculate1RM(double weight, int reps) {
    if (reps == 1) return weight;
    return weight * (1 + reps / 30);
  }

  // 计算总容量（Σ重量×次数）
  static double calculateTotalVolume(List<Map<String, dynamic>> exerciseSets) {
    return exerciseSets.fold(0.0, (sum, setData) {
      final weight = setData['weight'] as double;
      final reps = setData['reps'] as int;
      return sum + (weight * reps);
    });
  }

  // 删除力量训练记录
  Future<void> deleteStrengthRecord(int id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.exerciseSets)..where((t) => t.strengthRecordId.equals(id))).go();
      await (_db.delete(_db.strengthRecords)..where((t) => t.id.equals(id))).go();
    });
  }
}