import '../database/database_manager.dart';

class GoalRepository {
  final AppDatabase _db = DatabaseManager.instance;

  // 添加目标
  Future<int> addGoal({
    required String goalType,
    required String title,
    DateTime? targetDate,
    String? targetValue,
    String? currentValue,
  }) async {
    return await _db.into(_db.goals).insert(
      GoalsCompanion.insert(
        goalType: goalType,
        title: title,
        targetDate: Value(targetDate),
        targetValue: Value(targetValue),
        currentValue: Value(currentValue),
      ),
    );
  }

  // 更新目标
  Future<void> updateGoal({
    required int id,
    String? title,
    DateTime? targetDate,
    String? targetValue,
    String? currentValue,
    bool? isCompleted,
  }) async {
    await (_db.update(_db.goals)..where((t) => t.id.equals(id))).write(
      GoalsCompanion(
        title: title != null ? Value(title) : const Value.absent(),
        targetDate: targetDate != null ? Value(targetDate) : const Value.absent(),
        targetValue: targetValue != null ? Value(targetValue) : const Value.absent(),
        currentValue: currentValue != null ? Value(currentValue) : const Value.absent(),
        isCompleted: isCompleted != null ? Value(isCompleted) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // 获取所有目标
  Future<List<Goal>> getAllGoals() async {
    return await (_db.select(_db.goals)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
        )
        .get();
  }

  // 根据类型获取目标
  Future<Goal?> getGoalByType(String goalType) async {
    return await (_db.select(_db.goals)
          ..where((t) => t.goalType.equals(goalType))
        )
        .getSingleOrNull();
  }

  // 删除目标
  Future<void> deleteGoal(int id) async {
    await (_db.delete(_db.goals)..where((t) => t.id.equals(id))).go();
  }

  // 标记目标为完成
  Future<void> markGoalAsCompleted(int id) async {
    await updateGoal(id: id, isCompleted: true);
  }
}