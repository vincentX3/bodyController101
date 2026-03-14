import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../main.dart';
import '../../data/providers/providers.dart';
import '../../data/repositories/run_repository.dart';
import '../../data/repositories/strength_repository.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(allGoalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('目标追踪'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddGoalDialog(),
          ),
        ],
      ),
      body: goalsAsync.when(
        data: (goals) {
          if (goals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: MyApp.legDayColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(
                      Icons.flag_outlined,
                      size: 50,
                      color: MyApp.legDayColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '还没有设定目标',
                    style: TextStyle(fontSize: 18, color: MyApp.textPrimary, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _showAddGoalDialog(),
                    icon: Icon(Icons.add, color: MyApp.primaryColor),
                    label: Text('添加目标', style: TextStyle(color: MyApp.primaryColor)),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final goal = goals[index];
              return _buildGoalCard(goal);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('加载失败：$error'),
        ),
      ),
    );
  }

  Widget _buildGoalCard(dynamic goal) {
    final isHalfMarathon = goal.goalType == 'half_marathon';
    final isStrengthGoal = ['squat', 'bench_press', 'deadlift'].contains(goal.goalType);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: MyApp.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          isHalfMarathon ? Icons.directions_run : Icons.fitness_center,
                          color: MyApp.primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          goal.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: MyApp.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (goal.isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('已完成', style: TextStyle(color: Colors.white, fontSize: 12)),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Color(0xFFE53935)),
                    onPressed: () => _confirmDeleteGoal(goal.id),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // 半马目标详情
            if (isHalfMarathon) ...[
              _buildHalfMarathonGoalDetails(goal),
            ],

            // 力量目标详情
            if (isStrengthGoal) ...[
              _buildStrengthGoalDetails(goal),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHalfMarathonGoalDetails(dynamic goal) {
    final targetDate = goal.targetDate as DateTime?;
    final targetTime = goal.targetValue as String?;
    final now = DateTime.now();

    // 计算倒计时
    int daysRemaining = 0;
    if (targetDate != null && targetDate.isAfter(now)) {
      daysRemaining = targetDate.difference(now).inDays;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (targetDate != null) ...[
          Row(
            children: [
              Icon(Icons.event, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                '目标日期：${DateFormat('yyyy-MM-dd').format(targetDate)}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: daysRemaining > 0
                  ? MyApp.primaryColor.withOpacity(0.1)
                  : const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              daysRemaining > 0 ? '剩余 $daysRemaining 天' : '已过期',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: daysRemaining > 0
                    ? MyApp.primaryColor
                    : const Color(0xFFE53935),
              ),
            ),
          ),
        ],
        if (targetTime != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.timer, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                '目标完赛时间：$targetTime',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStrengthGoalDetails(dynamic goal) {
    final targetWeight = goal.targetValue as String?;
    final currentWeight = goal.currentValue as String?;

    // 计算进度
    double progress = 0.0;
    if (targetWeight != null && currentWeight != null) {
      final target = double.tryParse(targetWeight.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      final current = double.tryParse(currentWeight.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      if (target > 0) {
        progress = (current / target).clamp(0.0, 1.0);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (targetWeight != null) ...[
          Row(
            children: [
              Icon(Icons.flag, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                '目标重量：$targetWeight',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (currentWeight != null) ...[
            Row(
              children: [
                Icon(Icons.trending_up, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '当前最佳：$currentWeight',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(MyApp.primaryColor),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 4),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ],
      ],
    );
  }

  void _showAddGoalDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddGoalDialog(),
    );
  }

  Future<void> _confirmDeleteGoal(int goalId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个目标吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repo = ref.read(goalRepositoryProvider);
        await repo.deleteGoal(goalId);
        if (mounted) {
          ref.invalidate(allGoalsProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('目标已删除')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败：$e')),
          );
        }
      }
    }
  }
}

class AddGoalDialog extends ConsumerStatefulWidget {
  const AddGoalDialog({super.key});

  @override
  ConsumerState<AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends ConsumerState<AddGoalDialog> {
  String _goalType = 'half_marathon';
  final _titleController = TextEditingController();
  DateTime? _targetDate;
  final _targetValueController = TextEditingController();
  final _currentValueController = TextEditingController();

  final Map<String, String> _goalTypes = {
    'half_marathon': '半程马拉松',
    'squat': '深蹲',
    'bench_press': '卧推',
    'deadlift': '硬拉',
  };

  @override
  void dispose() {
    _titleController.dispose();
    _targetValueController.dispose();
    _currentValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isHalfMarathon = _goalType == 'half_marathon';

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '添加目标',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: MyApp.textPrimary),
            ),
            const SizedBox(height: 24),

            // 目标类型选择
            DropdownButtonFormField<String>(
              value: _goalType,
              decoration: InputDecoration(
                labelText: '目标类型',
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              items: _goalTypes.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _goalType = value!;
                  _titleController.text = _goalTypes[value]!;
                  if (!isHalfMarathon) {
                    _targetDate = null;
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            // 标题
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: '目标标题',
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 半马特有字段
            if (isHalfMarathon) ...[
              // 目标日期
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: '目标日期',
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  child: Text(
                    _targetDate != null
                        ? DateFormat('yyyy-MM-dd').format(_targetDate!)
                        : '选择日期',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 目标完赛时间
              TextFormField(
                controller: _targetValueController,
                decoration: InputDecoration(
                  labelText: '目标完赛时间（如 1:30:00）',
                  hintText: 'HH:MM:SS',
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],

            // 力量目标特有字段
            if (!isHalfMarathon) ...[
              // 目标重量
              TextFormField(
                controller: _targetValueController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: '目标重量（kg）',
                  suffixText: 'kg',
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 当前重量（可选）
              TextFormField(
                controller: _currentValueController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: '当前最佳重量（可选）',
                  suffixText: 'kg',
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            FilledButton(
              onPressed: _saveGoal,
              style: FilledButton.styleFrom(
                backgroundColor: MyApp.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text('保存', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _targetDate = picked;
      });
    }
  }

  Future<void> _saveGoal() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入目标标题')),
      );
      return;
    }

    try {
      final repo = ref.read(goalRepositoryProvider);
      await repo.addGoal(
        goalType: _goalType,
        title: _titleController.text,
        targetDate: _targetDate,
        targetValue: _targetValueController.text.isEmpty ? null : _targetValueController.text,
        currentValue: _currentValueController.text.isEmpty ? null : _currentValueController.text,
      );

      if (mounted) {
        ref.invalidate(allGoalsProvider);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('目标已添加')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败：$e')),
        );
      }
    }
  }
}