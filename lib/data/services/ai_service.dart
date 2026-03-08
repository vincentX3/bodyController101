import 'dart:convert';
import 'package:http/http.dart' as http;
import '../repositories/run_repository.dart';
import '../repositories/strength_repository.dart';
import '../repositories/ai_config_repository.dart';

class AIService {
  final AIConfigRepository _configRepo = AIConfigRepository();
  final RunRepository _runRepo = RunRepository();
  final StrengthRepository _strengthRepo = StrengthRepository();

  String? _apiKey;

  // 初始化API Key
  Future<void> init() async {
    _apiKey = await _configRepo.getAPIKey();
  }

  // 调用阿里云百炼API
  Future<String> _callAPI(String prompt) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      return '请先配置API Key';
    }

    try {
      final response = await http.post(
        Uri.parse('https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'qwen-turbo',
          'input': {
            'messages': [
              {'role': 'user', 'content': prompt}
            ]
          },
          'parameters': {},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['output']['text'] ?? data['output']['choices']?[0]?['message']?['content'] ?? '无法生成回复';
      } else {
        return 'API调用失败：${response.statusCode}';
      }
    } catch (e) {
      return '调用出错：$e';
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
    final maxDistance = await _runRepo.getMaxDistance();

    // 构建提示词
    final prompt = _buildInsightsPrompt(weekRuns, allRuns, strengthRecords, weekStart, lastWeekDistance, maxDistance);

    return await _callAPI(prompt);
  }

  // 构建洞察提示词
  String _buildInsightsPrompt(
    List weekRuns,
    List allRuns,
    List strengthRecords,
    DateTime weekStart,
    double lastWeekDistance,
    double maxDistance,
  ) {
    double weekTotalDistance = 0;
    for (var r in weekRuns) {
      weekTotalDistance += (r as dynamic).distance as double;
    }

    final weekChangePercent = lastWeekDistance > 0
        ? ((weekTotalDistance - lastWeekDistance) / lastWeekDistance * 100).toStringAsFixed(0)
        : '0';

    return '''
你是一个专业的健身教练，请根据以下训练数据提供数据洞察：

【本周跑步数据】
- 本周跑量：${weekTotalDistance.toStringAsFixed(1)} km
- 环比变化：$weekChangePercent%
- 训练次数：${weekRuns.length}次

【力量训练数据】
- 本周力量训练：${strengthRecords.where((r) {
    final record = r as dynamic;
    final recordDate = record.date as DateTime;
    return recordDate.isAfter(weekStart) && recordDate.isBefore(weekStart.add(const Duration(days: 7)));
  }).length}次

【历史最佳】
- 最长距离：${maxDistance.toStringAsFixed(1)}km

请以以下格式输出：

【本周洞察】
• [3-4条关键洞察]

【建议】
• [基于数据的2-3条具体建议]

重要：保持专业但友好的语气，简洁明了。
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

    return await _callAPI(prompt);
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
- 本周跑量：${weekTotalDistance.toStringAsFixed(1)}km

【训练原则】
1. 跑步：LSD长距离跑 + 间歇跑 + 轻松跑结合
2. 力量：推日（胸、肩、三头）、拉日（背、二头）、腿日（下肢）
3. 每周至少1天完全休息

请制定下周训练计划（周一至周日），格式如下：

【下周训练计划】

周一：[训练类型]
周二：[训练类型]
周三：[训练类型]
周四：[训练类型]
周五：[训练类型]
周六：[训练类型]
周日：休息日

重要：简洁实用，可执行性强。
''';
  }

  // 对话交互
  Future<String> chat(String userMessage, {List<String>? conversationHistory}) async {
    await init();

    String context = '''
你是一个专业的健身教练，帮助用户进行半程马拉松备赛和3分化器械训练。

''';

    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      context += '【历史对话】\n';
      for (var msg in conversationHistory) {
        context += '$msg\n';
      }
    }

    context += '【用户问题】\n$userMessage';

    return await _callAPI(context);
  }
}