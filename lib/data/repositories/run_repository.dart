import '../database/database.dart';
import '../database/database_manager.dart';

class RunRepository {
  final AppDatabase _db = DatabaseManager.instance;

  // 添加跑步记录
  Future<int> addRunRecord({
    required DateTime date,
    required double distance,
    required int durationMinutes,
    required int durationSeconds,
    required String pace,
    required int perceivedExertion,
  }) async {
    return await _db.into(_db.runRecords).insert(
      RunRecordsCompanion.insert(
        date: date,
        distance: distance,
        durationMinutes: durationMinutes,
        durationSeconds: durationSeconds,
        pace: pace,
        perceivedExertion: perceivedExertion,
      ),
    );
  }

  // 获取所有跑步记录
  Future<List<RunRecord>> getAllRunRecords() async {
    return await (_db.select(_db.runRecords)
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
        )
        .get();
  }

  // 获取本周跑步记录
  Future<List<RunRecord>> getWeekRunRecords(DateTime weekStart) async {
    final weekEnd = weekStart.add(const Duration(days: 7));
    return await (_db.select(_db.runRecords)
          ..where((t) => t.date.isBiggerOrEqualValue(weekStart))
          ..where((t) => t.date.isSmallerThanValue(weekEnd))
          ..orderBy([(t) => OrderingTerm.asc(t.date)])
        )
        .get();
  }

  // 获取本月跑步记录
  Future<List<RunRecord>> getMonthRunRecords(DateTime monthStart) async {
    final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 1);
    return await (_db.select(_db.runRecords)
          ..where((t) => t.date.isBiggerOrEqualValue(monthStart))
          ..where((t) => t.date.isSmallerThanValue(monthEnd))
          ..orderBy([(t) => OrderingTerm.asc(t.date)])
        )
        .get();
  }

  // 计算本周跑量
  Future<double> getWeekTotalDistance(DateTime weekStart) async {
    final records = await getWeekRunRecords(weekStart);
    return records.fold(0.0, (sum, record) => sum + record.distance);
  }

  // 获取上周跑量
  Future<double> getLastWeekTotalDistance(DateTime weekStart) async {
    final lastWeekStart = weekStart.subtract(const Duration(days: 7));
    final records = await getWeekRunRecords(lastWeekStart);
    return records.fold(0.0, (sum, record) => sum + record.distance);
  }

  // 获取最长距离
  Future<double> getMaxDistance() async {
    final records = await getAllRunRecords();
    if (records.isEmpty) return 0.0;
    return records.map((r) => r.distance).reduce((a, b) => a > b ? a : b);
  }

  // 删除跑步记录
  Future<void> deleteRunRecord(int id) async {
    await (_db.delete(_db.runRecords)..where((t) => t.id.equals(id))).go();
  }

  // 计算配速（km/分钟格式化为 mm:ss/km）
  static String calculatePace(int durationMinutes, int durationSeconds, double distance) {
    final totalSeconds = durationMinutes * 60 + durationSeconds;
    final paceSecondsPerKm = totalSeconds / distance;
    final paceMinutes = paceSecondsPerKm ~/ 60;
    final paceSeconds = (paceSecondsPerKm % 60).round();
    return '${paceMinutes.toString().padLeft(2, '0')}:${paceSeconds.toString().padLeft(2, '0')}/km';
  }
}