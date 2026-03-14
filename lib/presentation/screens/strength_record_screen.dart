import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/providers/providers.dart';
import '../../data/repositories/strength_repository.dart';

class StrengthRecordScreen extends ConsumerStatefulWidget {
  const StrengthRecordScreen({super.key});

  @override
  ConsumerState<StrengthRecordScreen> createState() => _StrengthRecordScreenState();
}

class _StrengthRecordScreenState extends ConsumerState<StrengthRecordScreen> {
  String? _selectedSplit;
  DateTime _selectedDate = DateTime.now();
  final Map<String, List<Map<String, dynamic>>> _exerciseData = {};
  
  // 引体向上体重记忆
  double? _lastPullUpBodyweight;
  static const String _pullUpBodyweightKey = 'last_pullup_bodyweight';

  // 3分化模板
  final Map<String, List<String>> _splitTemplates = {
    '推日': [
      '杠铃卧推',
      '哑铃卧推',
      '哑铃推举',
      '侧平举',
      '绳索下压',
      '窄距卧推',
    ],
    '拉日': [
      '引体向上',
      '高位下拉',
      '杠铃划船',
      '杠铃弯举',
      '哑铃弯举',
      '面拉',
      '反向飞鸟',
    ],
    '腿日': [
      '深蹲',
      '腿举',
      '罗马尼亚硬拉',
      '腿弯举',
      '提踵',
    ],
  };

  final Map<String, bool> _selectedExercises = {};

  // 重量选项 (0.5kg 步进，从2.5kg到300kg)
  List<double> get _weightOptions {
    return [for (double w = 2.5; w <= 300; w += 2.5) w];
  }

  // 次数选项 (1-50次)
  List<int> get _repsOptions {
    return [for (int r = 1; r <= 50; r++) r];
  }

  // RPE选项 (6-10)
  List<int> get _rpeOptions {
    return [for (int r = 6; r <= 10; r++) r];
  }

  @override
  void initState() {
    super.initState();
    _loadLastPullUpBodyweight();
  }

  Future<void> _loadLastPullUpBodyweight() async {
    final prefs = await SharedPreferences.getInstance();
    final weight = prefs.getDouble(_pullUpBodyweightKey);
    if (weight != null) {
      setState(() {
        _lastPullUpBodyweight = weight;
      });
    }
  }

  Future<void> _savePullUpBodyweight(double weight) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_pullUpBodyweightKey, weight);
    _lastPullUpBodyweight = weight;
  }

  // 显示滚轮选择器对话框
  Future<double?> _showWeightPicker(BuildContext context, double initialValue) async {
    double selectedValue = initialValue > 0 ? initialValue : 20.0;
    int initialIndex = _weightOptions.indexOf(selectedValue);
    if (initialIndex < 0) {
      // 找最接近的值
      for (int i = 0; i < _weightOptions.length; i++) {
        if (_weightOptions[i] >= selectedValue) {
          initialIndex = i;
          break;
        }
      }
    }

    return await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('选择重量'),
          content: SizedBox(
            height: 200,
            width: 200,
            child: CupertinoPicker(
              itemExtent: 40,
              scrollController: FixedExtentScrollController(initialItem: initialIndex),
              onSelectedItemChanged: (index) {
                selectedValue = _weightOptions[index];
              },
              children: _weightOptions.map((weight) {
                return Center(
                  child: Text(
                    '${weight.toStringAsFixed(1)} kg',
                    style: const TextStyle(fontSize: 18),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, selectedValue),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  // 显示次数滚轮选择器
  Future<int?> _showRepsPicker(BuildContext context, int initialValue) async {
    int selectedValue = initialValue > 0 ? initialValue : 10;
    int initialIndex = selectedValue - 1;

    return await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('选择次数'),
          content: SizedBox(
            height: 200,
            width: 150,
            child: CupertinoPicker(
              itemExtent: 40,
              scrollController: FixedExtentScrollController(initialItem: initialIndex),
              onSelectedItemChanged: (index) {
                selectedValue = _repsOptions[index];
              },
              children: _repsOptions.map((reps) {
                return Center(
                  child: Text(
                    '$reps 次',
                    style: const TextStyle(fontSize: 18),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, selectedValue),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  // 显示RPE滚轮选择器
  Future<int?> _showRpePicker(BuildContext context, int? initialValue) async {
    int selectedValue = initialValue ?? 8;
    int initialIndex = selectedValue - 6;

    return await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('选择RPE'),
          content: SizedBox(
            height: 200,
            width: 150,
            child: CupertinoPicker(
              itemExtent: 40,
              scrollController: FixedExtentScrollController(initialItem: initialIndex),
              onSelectedItemChanged: (index) {
                selectedValue = _rpeOptions[index];
              },
              children: _rpeOptions.map((rpe) {
                return Center(
                  child: Text(
                    'RPE $rpe',
                    style: const TextStyle(fontSize: 18),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, selectedValue),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('记录力量训练'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 日期选择
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('训练日期'),
                subtitle: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _selectDate,
              ),
            ),
            const SizedBox(height: 16),

            // 分化选择
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '选择分化',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ..._splitTemplates.keys.map((split) {
                      return RadioListTile<String>(
                        title: Text(split),
                        value: split,
                        groupValue: _selectedSplit,
                        onChanged: (value) {
                          setState(() {
                            _selectedSplit = value;
                            _selectedExercises.clear();
                            _exerciseData.clear();
                          });
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 动作选择
            if (_selectedSplit != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '选择今日动作（$_selectedSplit）',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ..._splitTemplates[_selectedSplit]!.map((exercise) {
                        return CheckboxListTile(
                          title: Text(exercise),
                          value: _selectedExercises[exercise] ?? false,
                          onChanged: (value) {
                            setState(() {
                              _selectedExercises[exercise] = value ?? false;
                              if (value == true) {
                                // 引体向上使用上次输入的体重作为默认值
                                final defaultWeight = (exercise == '引体向上' && _lastPullUpBodyweight != null)
                                    ? _lastPullUpBodyweight!
                                    : 0.0;
                                _exerciseData[exercise] = [
                                  {'weight': defaultWeight, 'reps': 0, 'rpe': null}
                                ];
                              } else {
                                _exerciseData.remove(exercise);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 动作数据录入
              ..._selectedExercises.entries
                  .where((entry) => entry.value)
                  .map((entry) => _buildExerciseCard(entry.key))
                  .toList(),
              const SizedBox(height: 24),

              // 保存按钮
              FilledButton.icon(
                onPressed: _saveRecord,
                icon: const Icon(Icons.save),
                label: const Text('保存记录'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(String exerciseName) {
    final sets = _exerciseData[exerciseName] ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exerciseName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...sets.asMap().entries.map((entry) {
              final index = entry.key;
              final setData = entry.value;
              return _buildSetRow(exerciseName, index, setData);
            }).toList(),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  // 默认填充上一组的重量
                  double defaultWeight = 0.0;
                  if (sets.isNotEmpty && sets.last['weight'] > 0) {
                    // 使用上一组的重量
                    defaultWeight = sets.last['weight'];
                  } else if (exerciseName == '引体向上' && _lastPullUpBodyweight != null) {
                    // 引体向上且没有上一组数据时，使用上次记录的体重
                    defaultWeight = _lastPullUpBodyweight!;
                  }
                  _exerciseData[exerciseName]!.add({
                    'weight': defaultWeight,
                    'reps': 0,
                    'rpe': null,
                  });
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('添加一组'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetRow(String exerciseName, int setIndex, Map<String, dynamic> setData) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          // 第一行：组数 + 重量 + 次数
          Row(
            children: [
              // 组数
              SizedBox(
                width: 50,
                child: Text(
                  '第${setIndex + 1}组',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              // 重量选择器
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final weight = await _showWeightPicker(context, setData['weight'] ?? 0.0);
                    if (weight != null) {
                      setState(() {
                        _exerciseData[exerciseName]![setIndex]['weight'] = weight;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            setData['weight'] == 0.0 ? '重量' : '${setData['weight'].toStringAsFixed(1)}kg',
                            style: TextStyle(
                              fontSize: 13,
                              color: setData['weight'] == 0.0 ? Colors.grey : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 次数选择器
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final reps = await _showRepsPicker(context, setData['reps'] ?? 0);
                    if (reps != null) {
                      setState(() {
                        _exerciseData[exerciseName]![setIndex]['reps'] = reps;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            setData['reps'] == 0 ? '次数' : '${setData['reps']}次',
                            style: TextStyle(
                              fontSize: 13,
                              color: setData['reps'] == 0 ? Colors.grey : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // 第二行：RPE + 删除按钮
          Row(
            children: [
              const SizedBox(width: 58), // 对齐第一行
              // RPE选择器
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final rpe = await _showRpePicker(context, setData['rpe']);
                    if (rpe != null) {
                      setState(() {
                        _exerciseData[exerciseName]![setIndex]['rpe'] = rpe;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          setData['rpe'] == null ? 'RPE' : 'RPE ${setData['rpe']}',
                          style: TextStyle(
                            fontSize: 13,
                            color: setData['rpe'] == null ? Colors.grey : null,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 删除按钮
              GestureDetector(
                onTap: () {
                  setState(() {
                    _exerciseData[exerciseName]!.removeAt(setIndex);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveRecord() async {
    if (_selectedSplit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择分化类型')),
      );
      return;
    }

    // 验证数据
    final selectedExercises = _selectedExercises.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少选择一个动作')),
      );
      return;
    }

    // 收集所有动作组数据
    final exerciseSets = <Map<String, dynamic>>[];
    for (var exerciseName in selectedExercises) {
      final sets = _exerciseData[exerciseName] ?? [];
      for (var i = 0; i < sets.length; i++) {
        final setData = sets[i];
        if (setData['weight'] > 0 && setData['reps'] > 0) {
          exerciseSets.add({
            'exerciseName': exerciseName,
            'setNumber': i + 1,
            'weight': setData['weight'],
            'reps': setData['reps'],
            'rpe': setData['rpe'],
          });
          // 如果是引体向上，记住体重
          if (exerciseName == '引体向上') {
            _savePullUpBodyweight(setData['weight']);
          }
        }
      }
    }

    if (exerciseSets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少录入一组有效数据')),
      );
      return;
    }

    // 计算总容量
    final totalVolume = StrengthRepository.calculateTotalVolume(exerciseSets);

    // 估算训练时长（每组2分钟）
    final durationMinutes = (exerciseSets.length * 2 + 10).clamp(30, 90);

    try {
      final repo = ref.read(strengthRepositoryProvider);
      await repo.addStrengthRecord(
        date: _selectedDate,
        splitType: _selectedSplit!,
        durationMinutes: durationMinutes,
        totalVolume: totalVolume,
        exerciseSets: exerciseSets,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('力量训练记录已保存，总容量：${totalVolume.toStringAsFixed(0)}kg')),
        );
        // 返回列表页并传递true表示有新数据
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败：$e')),
        );
      }
    }
  }

  void _clearForm() {
    setState(() {
      _selectedSplit = null;
      _selectedDate = DateTime.now();
      _selectedExercises.clear();
      _exerciseData.clear();
    });
  }
}