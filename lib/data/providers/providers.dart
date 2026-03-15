import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_manager.dart';
import '../repositories/run_repository.dart';
import '../repositories/strength_repository.dart';
import '../repositories/goal_repository.dart';
import '../repositories/ai_config_repository.dart';
import '../services/ai_service.dart';

// 数据库Provider
final databaseProvider = Provider((ref) {
  return DatabaseManager.instance;
});

// Repository Providers
final runRepositoryProvider = Provider((ref) {
  return RunRepository();
});

final strengthRepositoryProvider = Provider((ref) {
  return StrengthRepository();
});

final goalRepositoryProvider = Provider((ref) {
  return GoalRepository();
});

final aiConfigRepositoryProvider = Provider((ref) {
  return AIConfigRepository();
});

// AI Service Provider
final aiServiceProvider = Provider((ref) {
  return AIService();
});

// 跑步记录数据Provider
final allRunRecordsProvider = FutureProvider((ref) async {
  final repo = ref.watch(runRepositoryProvider);
  return repo.getAllRunRecords();
});

// 今日跑步记录Provider
final todayRunRecordsProvider = FutureProvider((ref) async {
  final repo = ref.watch(runRepositoryProvider);
  final today = DateTime.now();
  final todayStart = DateTime(today.year, today.month, today.day);
  return repo.getRunRecordsByDateRange(todayStart, todayStart.add(const Duration(days: 1)));
});

// 今日跑步距离Provider
final todayRunDistanceProvider = FutureProvider((ref) async {
  final records = await ref.watch(todayRunRecordsProvider.future);
  return records.fold<double>(0.0, (sum, record) => sum + record.distance);
});

// 本周跑步记录Provider
final weekRunRecordsProvider = FutureProvider.family((ref, DateTime weekStart) async {
  final repo = ref.watch(runRepositoryProvider);
  return repo.getWeekRunRecords(weekStart);
});

// 本周跑量Provider
final weekTotalDistanceProvider = FutureProvider.family((ref, DateTime weekStart) async {
  final repo = ref.watch(runRepositoryProvider);
  return repo.getWeekTotalDistance(weekStart);
});

// 力量训练记录Provider
final allStrengthRecordsProvider = FutureProvider((ref) async {
  final repo = ref.watch(strengthRepositoryProvider);
  return repo.getAllStrengthRecords();
});

// 单条力量训练记录详情Provider（含所有组数据）
final strengthRecordDetailProvider = FutureProvider.family<Map<String, dynamic>?, int>((ref, recordId) async {
  final repo = ref.watch(strengthRepositoryProvider);
  return repo.getStrengthRecordWithSets(recordId);
});

// 今日力量训练Provider
final todayStrengthRecordsProvider = FutureProvider((ref) async {
  final repo = ref.watch(strengthRepositoryProvider);
  final today = DateTime.now();
  final todayStart = DateTime(today.year, today.month, today.day);
  return repo.getStrengthRecordsByDateRange(todayStart, todayStart.add(const Duration(days: 1)));
});

// 今日力量训练次数Provider
final todayStrengthCountProvider = FutureProvider((ref) async {
  final records = await ref.watch(todayStrengthRecordsProvider.future);
  return records.length;
});

// 本周训练天数Provider
final weekTrainingDaysProvider = FutureProvider.family((ref, DateTime weekStart) async {
  final runRecords = await ref.watch(weekRunRecordsProvider(weekStart).future);
  final strengthRecords = await ref.watch(strengthRepositoryProvider).getWeekStrengthRecords(weekStart);
  
  final trainingDays = <DateTime>{};
  for (var record in runRecords) {
    trainingDays.add(DateTime(record.date.year, record.date.month, record.date.day));
  }
  for (var record in strengthRecords) {
    trainingDays.add(DateTime(record.date.year, record.date.month, record.date.day));
  }
  return trainingDays.length;
});

// 目标Provider
final allGoalsProvider = FutureProvider((ref) async {
  final repo = ref.watch(goalRepositoryProvider);
  return repo.getAllGoals();
});

// AI配置状态Provider
final aiConfigStateProvider = StateNotifierProvider<AIConfigNotifier, AIConfigState>((ref) {
  return AIConfigNotifier(ref.watch(aiConfigRepositoryProvider));
});

// AI配置状态管理
class AIConfigState {
  final bool hasAPIKey;
  final String? apiKey;
  final bool isLoading;

  AIConfigState({
    this.hasAPIKey = false,
    this.apiKey,
    this.isLoading = false,
  });

  AIConfigState copyWith({
    bool? hasAPIKey,
    String? apiKey,
    bool? isLoading,
  }) {
    return AIConfigState(
      hasAPIKey: hasAPIKey ?? this.hasAPIKey,
      apiKey: apiKey ?? this.apiKey,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AIConfigNotifier extends StateNotifier<AIConfigState> {
  final AIConfigRepository _repository;

  AIConfigNotifier(this._repository) : super(AIConfigState()) {
    _checkAPIKey();
  }

  Future<void> _checkAPIKey() async {
    state = state.copyWith(isLoading: true);
    final hasKey = await _repository.hasAPIKey();
    final key = await _repository.getAPIKey();
    state = state.copyWith(
      hasAPIKey: hasKey,
      apiKey: key,
      isLoading: false,
    );
  }

  Future<void> saveAPIKey(String apiKey) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.saveAIConfig(apiKey: apiKey, provider: 'dashscope');
      await _checkAPIKey();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> deleteAPIKey() async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.deleteAIConfig();
      await _checkAPIKey();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }
}

// 当前选中的日期Provider
final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

// 当前页面索引Provider（用于底部导航）
final currentPageIndexProvider = StateProvider<int>((ref) {
  return 0;
});