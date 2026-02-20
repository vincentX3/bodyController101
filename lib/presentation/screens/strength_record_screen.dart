import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
      '引体向上/高位下拉',
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
                                _exerciseData[exercise] = [
                                  {'weight': 0.0, 'reps': 0, 'rpe': null}
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
                  _exerciseData[exerciseName]!.add({
                    'weight': 0.0,
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
      child: Row(
        children: [
          // 组数
          Container(
            width: 40,
            alignment: Alignment.center,
            child: Text(
              '第${setIndex + 1}组',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          // 重量
          Expanded(
            child: TextField(
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '重量',
                suffixText: 'kg',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              controller: TextEditingController(
                text: setData['weight'] == 0.0 ? '' : setData['weight'].toString(),
              )..selection = TextSelection.fromPosition(
                  TextPosition(offset: TextEditingController(text: setData['weight'] == 0.0 ? '' : setData['weight'].toString()).text.length),
                ),
              onChanged: (value) {
                final weight = double.tryParse(value) ?? 0.0;
                setState(() {
                  _exerciseData[exerciseName]![setIndex]['weight'] = weight;
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          // 次数
          Expanded(
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '次数',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              controller: TextEditingController(
                text: setData['reps'] == 0 ? '' : setData['reps'].toString(),
              )..selection = TextSelection.fromPosition(
                  TextPosition(offset: TextEditingController(text: setData['reps'] == 0 ? '' : setData['reps'].toString()).text.length),
                ),
              onChanged: (value) {
                final reps = int.tryParse(value) ?? 0;
                setState(() {
                  _exerciseData[exerciseName]![setIndex]['reps'] = reps;
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          // RPE
          SizedBox(
            width: 60,
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'RPE',
                hintText: '1-10',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              controller: TextEditingController(
                text: setData['rpe']?.toString() ?? '',
              )..selection = TextSelection.fromPosition(
                  TextPosition(offset: TextEditingController(text: setData['rpe']?.toString() ?? '').text.length),
                ),
              onChanged: (value) {
                final rpe = int.tryParse(value);
                setState(() {
                  _exerciseData[exerciseName]![setIndex]['rpe'] = rpe;
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          // 删除按钮
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () {
              setState(() {
                _exerciseData[exerciseName]!.removeAt(setIndex);
              });
            },
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
        _clearForm();
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