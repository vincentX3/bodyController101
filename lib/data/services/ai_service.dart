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
  String _model = 'qwen-turbo';

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
          'model': _model,
          'input': {
            'messages': [
              {'role': 'user', 'content': prompt}
            ]
          },
          'parameters': {
            'result_format': 'text'
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // 兼容不同的响应格式
        final output = data['output'];
        if (output is Map) {
          return output['text'] ?? output['choices']?[0]?['message']?['content'] ?? '无法生成回复';
        }
        return output?.toString() ?? '无法生成回复';
      } else if (response.statusCode == 401) {
        return 'API Key无效，请检查配置';
      } else if (response.statusCode == 429) {
        return '请求过于频繁，请稍后再试';
      } else {
        final errorBody = jsonDecode(response.body);
        return 'API调用失败：${errorBody['message'] ?? response.statusCode}';
      }
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        return '网络连接失败，请检查网络';
      }
      return '调用出错：$e';
    }
  }

  // 生成数据分析洞察
  Future<String> generateInsights() async {
    await init();

    // 获取数据
    final today = DateTime.now();
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final lastWeekStart = weekStart.subtract(const Duration(days: 7));

    final weekRuns = await _runRepo.getWeekRunRecords(weekStart);
    final lastWeekRuns = await _runRepo.getWeekRunRecords(lastWeekStart);
    final allRuns = await _runRepo.getAllRunRecords();
    final strengthRecords = await _strengthRepo.getAllStrengthRecords();
    final maxDistance = await _runRepo.getMaxDistance();

    // 计算本周数据
    double weekTotalDistance = 0;
    int weekTotalDuration = 0;
    for (var r in weekRuns) {
      weekTotalDistance += r.distance;
      weekTotalDuration += r.durationMinutes * 60 + r.durationSeconds;
    }

    // 计算上周数据
    double lastWeekTotalDistance = 0;
    for (var r in lastWeekRuns) {
      lastWeekTotalDistance += r.distance;
    }

    // 计算环比
    final weekChangePercent = lastWeekTotalDistance > 0
        ? ((weekTotalDistance - lastWeekTotalDistance) / lastWeekTotalDistance * 100)
        : (weekTotalDistance > 0 ? 100.0 : 0.0);

    // 计算本周力量训练
    final weekStrengthRecords = strengthRecords.where((r) {
      final recordDate = r.date;
      return recordDate.isAfter(weekStart.subtract(const Duration(seconds: 1))) && 
             recordDate.isBefore(weekStart.add(const Duration(days: 7)));
    }).toList();

    // 计算连续训练天数
    int consecutiveDays = _calculateConsecutiveDays(allRuns, strengthRecords, today);

    // 构建提示词
    final prompt = _buildInsightsPrompt(
      weekTotalDistance: weekTotalDistance,
      weekRunCount: weekRuns.length,
      weekChangePercent: weekChangePercent,
      weekStrengthCount: weekStrengthRecords.length,
      maxDistance: maxDistance,
      consecutiveDays: consecutiveDays,
      weekRuns: weekRuns,
    );

    return await _callAPI(prompt);
  }

  // 计算连续训练天数
  int _calculateConsecutiveDays(List allRuns, List allStrengths, DateTime today) {
    final trainingDates = <DateTime>{};
    
    for (var r in allRuns) {
      final d = r.date as DateTime;
      trainingDates.add(DateTime(d.year, d.month, d.day));
    }
    
    for (var r in allStrengths) {
      final d = r.date as DateTime;
      trainingDates.add(DateTime(d.year, d.month, d.day));
    }

    int consecutive = 0;
    var checkDate = DateTime(today.year, today.month, today.day);
    
    // 从今天往前数连续训练天数
    while (trainingDates.contains(checkDate)) {
      consecutive++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    
    return consecutive;
  }

  // 构建洞察提示词
  String _buildInsightsPrompt({
    required double weekTotalDistance,
    required int weekRunCount,
    required double weekChangePercent,
    required int weekStrengthCount,
    required double maxDistance,
    required int consecutiveDays,
    required List weekRuns,
  }) {
    // 判断是否增幅过大
    final warningFlag = weekChangePercent > 10 ? ' ⚠️ 接近安全上限' : '';
    
    // 构建跑步详情
    String runDetails = '';
    if (weekRuns.isNotEmpty) {
      runDetails = weekRuns.map((r) {
        return '- ${r.distance.toStringAsFixed(1)}km @ ${r.pace}';
      }).join('\n');
    }

    return '''
你是一个专业的健身教练，请根据以下训练数据提供数据洞察。

【本周训练数据】
跑量：${weekTotalDistance.toStringAsFixed(1)} km（环比${weekChangePercent >= 0 ? '+' : ''}${weekChangePercent.toStringAsFixed(0)}%）$warningFlag
跑步次数：$weekRunCount 次
力量训练：$weekStrengthCount 次
连续训练：$consecutiveDays 天
历史最长距离：${maxDistance.toStringAsFixed(1)} km

【本周跑步记录】
${runDetails.isNotEmpty ? runDetails : '本周暂无跑步记录'}

请严格按以下格式输出洞察：

【本周洞察】
• 跑量[评估]：[具体分析]
• 力量进展：[具体分析]
• 恢复信号：[疲劳/恢复状态评估]

【建议】
• [基于数据的2-3条具体可执行建议]

要求：
1. 保持专业但友好的语气
2. 数据驱动，客观分析
3. 建议要具体可执行
4. 简洁明了，不要冗长
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
    final maxDistance = await _runRepo.getMaxDistance();

    // 获取本周力量训练记录
    final weekStrengthRecords = strengthRecords.where((r) {
      final recordDate = r.date;
      return recordDate.isAfter(weekStart.subtract(const Duration(seconds: 1))) && 
             recordDate.isBefore(weekStart.add(const Duration(days: 7)));
    }).toList();

    // 统计本周各分化类型
    final splitCounts = <String, int>{'推日': 0, '拉日': 0, '腿日': 0};
    for (var r in weekStrengthRecords) {
      final splitType = r.splitType;
      if (splitCounts.containsKey(splitType)) {
        splitCounts[splitType] = splitCounts[splitType]! + 1;
      }
    }

    // 构建提示词
    final prompt = _buildPlanPrompt(
      weekTotalDistance: weekTotalDistance,
      weekRunCount: weekRuns.length,
      splitCounts: splitCounts,
      maxDistance: maxDistance,
      today: today,
    );

    return await _callAPI(prompt);
  }

  // 构建计划提示词
  String _buildPlanPrompt({
    required double weekTotalDistance,
    required int weekRunCount,
    required Map<String, int> splitCounts,
    required double maxDistance,
    required DateTime today,
  }) {
    // 计算下周日期范围
    final nextMonday = today.add(Duration(days: 8 - today.weekday));
    final nextSunday = nextMonday.add(const Duration(days: 6));

    return '''
你是一个专业的健身教练，请为用户制定下周训练计划。

【用户背景】
- 目标：半程马拉松备赛 + 3分化器械训练
- 本周跑量：${weekTotalDistance.toStringAsFixed(1)} km
- 本周跑步：$weekRunCount 次
- 本周力量：推日${splitCounts['推日']}次，拉日${splitCounts['拉日']}次，腿日${splitCounts['腿日']}次
- 历史最长距离：${maxDistance.toStringAsFixed(1)} km

【训练原则】
1. 跑步：LSD长距离跑（周末）+ 间歇跑（周中）+ 轻松跑结合
2. 力量：推日（胸、肩、三头）、拉日（背、二头）、腿日（下肢）
3. 渐进超负荷：周跑量增幅不超过10%
4. 恢复：每周至少1天完全休息

【下周日期】
${nextMonday.month}月${nextMonday.day}日（周一）- ${nextSunday.month}月${nextSunday.day}日（周日）

请严格按以下格式输出计划：

【下周训练计划】

周一：[训练内容]
周二：[训练内容]
周三：[训练内容]
周四：[训练内容]
周五：[训练内容]
周六：[训练内容]
周日：休息日

【重点提示】
• [2-3条本周需要注意的事项]

要求：
1. 每天的训练内容要具体（动作、距离、配速）
2. 安排合理，避免连续高强度
3. 简洁实用，可执行性强
''';
  }

  // 对话交互
  Future<String> chat(String userMessage, {List<String>? conversationHistory}) async {
    await init();

    // 构建对话历史
    String context = '''你是一个专业的健身教练，帮助用户进行半程马拉松备赛和3分化器械训练。
你的回答应该：
1. 专业但友好
2. 数据驱动，基于用户的实际训练数据
3. 具体可执行
4. 简洁明了

''';

    // 添加历史对话
    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      context += '【历史对话】\n';
      for (int i = 0; i < conversationHistory.length; i++) {
        if (i % 2 == 0) {
          context += '用户：${conversationHistory[i]}\n';
        } else {
          context += '教练：${conversationHistory[i]}\n';
        }
      }
      context += '\n';
    }

    context += '用户：$userMessage\n\n请回复：';

    return await _callAPI(context);
  }

  // 设置模型
  void setModel(String model) {
    _model = model;
  }
}