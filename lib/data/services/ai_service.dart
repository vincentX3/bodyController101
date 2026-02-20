import 'package:dashscope/dashscope.dart';
import '../repositories/run_repository.dart';
import '../repositories/strength_repository.dart';
import '../repositories/ai_config_repository.dart';

class AIService {
  final AIConfigRepository _configRepo = AIConfigRepository();
  final RunRepository _runRepo = RunRepository();
  final StrengthRepository _strengthRepo = StrengthRepository();

  // 初始化DashScope
  Future<void> init() async {
    final apiKey = await _configRepo.getAPIKey();
    if (apiKey != null && apiKey.isNotEmpty) {
      DashScope.apiKey = apiKey;
    }
  }

  // 生成数据分析洞察
  Future<String> generateInsights() async {
    await init();

    // 获取数据
    final today = DateTime.now();
    final weekStart = today.subtract(Duration(days: today.weekday - 1));

    final weekRuns = await _runRepo.getWeekRunRecords(weekStart);
    final allRuns = await _runRepo.getAllRunRecords();
    final strengthRecords = await _strengthRepo.getAllStrengthRecords();
    final lastWeekDistance = await _runRepo.getLastWeekTotalDistance(weekStart);

    // 构建提示词
    final prompt = _buildInsightsPrompt(weekRuns, allRuns, strengthRecords, weekStart, lastWeekDistance);

    try {
      final generation = Generation();
      final result = await generation.call(
        GenerationModels.qwen_turbo,
        prompt,
        resultFormat: 'message',
      );

      if (result.output?.choices != null && result.output!.choices!.isNotEmpty) {
        return result.output!.choices!.first.message.content;
      } else {
        return '无法生成洞察，请稍后重试';
      }
    } catch (e) {
      return '生成洞察时出错：$e';
    }
  }

  // 构建洞察提示词
  String _buildInsightsPrompt(
    List weekRuns,
    List allRuns,
    List strengthRecords,
    DateTime weekStart,
    double lastWeekDistance,
  ) {
    final weekTotalDistance = weekRuns.fold(0.0, (sum, r) => sum + (r as dynamic).distance);

    final weekChangePercent = lastWeekDistance > 0
        ? ((weekTotalDistance - lastWeekDistance) / lastWeekDistance * 100).toStringAsFixed(0)
        : '0';

    return '''
你是一个专业的健身教练，请根据以下训练数据提供数据洞察：

【本周跑步数据】
- 本周跑量：${weekTotalDistance.toStringAsFixed(1)} km
- 环比变化：$weekChangePercent%
- 训练次数：${weekRuns.length}次
${weekRuns.map((r) => '  • ${(r as dynamic).date.toString().split(' ')[0]}: ${(r as dynamic).distance}km @ ${(r as dynamic).pace}').join('\n')}

【力量训练数据】
- 本周力量训练：${strengthRecords.where((r) {
    final record = r as dynamic;
    final recordDate = record.date as DateTime;
    return recordDate.isAfter(weekStart) && recordDate.isBefore(weekStart.add(const Duration(days: 7)));
  }).length}次
${strengthRecords.take(5).map((r) => '  • ${(r as dynamic).date.toString().split(' ')[0]}: ${(r as dynamic).splitType} - ${(r as dynamic).totalVolume.toStringAsFixed(0)}kg').join('\n')}

【历史最佳】
- 最长距离：${_runRepo.getMaxDistance().toStringAsFixed(1)}km

请以以下格式输出：

【本周洞察】
• [3-4条关键洞察，使用emoji增强可读性]

【建议】
• [基于数据的2-3条具体建议]

重要：
1. 如果周跑量环比增幅超过10%，标记⚠️警告
2. 保持专业但友好的语气
3. 简洁明了，每条不超过30字
''';
  }

  // 生成训练计划
  Future<String> generatePlan() async {
    await init();

    // 获取数据
    final today = DateTime.now();
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekRuns = await _runRepo.getWeekRunRecords(weekStart);
    final strengthRecords = await _strengthRepo.getAllStrengthRecords();
    final weekTotalDistance = await _runRepo.getWeekTotalDistance(weekStart);

    // 构建提示词
    final prompt = _buildPlanPrompt(weekRuns, strengthRecords, weekTotalDistance, today);

    try {
      final generation = Generation();
      final result = await generation.call(
        GenerationModels.qwen_turbo,
        prompt,
        resultFormat: 'message',
      );

      if (result.output?.choices != null && result.output!.choices!.isNotEmpty) {
        return result.output!.choices!.first.message.content;
      } else {
        return '无法生成计划，请稍后重试';
      }
    } catch (e) {
      return '生成计划时出错：$e';
    }
  }

  // 构建计划提示词
  String _buildPlanPrompt(
    List weekRuns,
    List strengthRecords,
    double weekTotalDistance,
    DateTime today,
  ) {
    return '''
你是一个专业的健身教练，请为用户制定下周训练计划。

【用户背景】
- 正在进行半程马拉松备赛 + 3分化器械训练
- 本周已训练：${weekRuns.length + strengthRecords.where((r) {
    final record = r as dynamic;
    final recordDate = record.date as DateTime;
    return recordDate.isAfter(today.subtract(const Duration(days: 7)));
  }).length}次
- 本周跑量：${weekTotalDistance.toStringAsFixed(1)}km

【训练原则】
1. 跑步：LSD长距离跑 + 间歇跑 + 轻松跑结合
2. 力量：推日（胸、肩、三头）、拉日（背、二头）、腿日（下肢）
3. 每周至少1天完全休息
4. 力量训练时长45-60分钟

请制定下周训练计划（周一至周日），格式如下：

【下周训练计划】

周一：[分化类型] [动作名称] (时长)
• 具体安排

周二：[跑步类型] [距离] @[配速]
• 具体安排

周三：[分化类型] [动作名称] (时长)
• 具体安排

周四：[跑步类型] [距离] @[配速]
• 具体安排

周五：[分化类型] [动作名称] (时长)
• 具体安排

周六：[跑步类型] [距离] @[配速]
• 具体安排

周日：休息日
• 恢复建议

重要：
1. 跑步配速参考：LSD 5:50-6:30/km，间歇4:20-4:40/km，轻松6:00-6:30/km
2. 每次训练包含具体动作或跑步安排
3. 简洁实用，可执行性强
''';
  }

  // 对话交互（支持追问）
  Future<String> chat(String userMessage, {List<String>? conversationHistory}) async {
    await init();

    final prompt = _buildChatPrompt(userMessage, conversationHistory);

    try {
      final generation = Generation();
      final result = await generation.call(
        GenerationModels.qwen_turbo,
        prompt,
        resultFormat: 'message',
      );

      if (result.output?.choices != null && result.output!.choices!.isNotEmpty) {
        return result.output!.choices!.first.message.content;
      } else {
        return '抱歉，我无法理解您的问题，请重新表述';
      }
    } catch (e) {
      return '回复时出错：$e';
    }
  }

  // 构建对话提示词
  String _buildChatPrompt(String userMessage, List<String>? history) {
    String context = '''
你是一个专业的健身教练，帮助用户进行半程马拉松备赛和3分化器械训练。

用户特点：
- 算法工程师，时间紧张
- 目标：半马完赛 + 力量提升
- 遵循"双目标训练"策略

''';

    if (history != null && history.isNotEmpty) {
      context += '\n【历史对话】\n';
      for (var msg in history) {
        context += '$msg\n';
      }
    }

    context += '\n【用户问题】\n$userMessage';

    context += '''

请以专业、简洁的方式回答，重点关注：
1. 提供可执行的具体建议
2. 考虑用户的时间约束
3. 如果涉及训练调整，说明原因和预期效果
''';

    return context;
  }
}
