import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import '../../data/providers/providers.dart';
import '../../data/repositories/strength_repository.dart';

class StrengthRecordScreen extends ConsumerStatefulWidget {
  final bool isEditMode;
  final int? recordId; // 单条记录编辑（向后兼容）
  final List<int>? recordIds; // 多条记录合并编辑
  final Map<String, dynamic>? existingData;

  const StrengthRecordScreen({
    super.key,
    this.isEditMode = false,
    this.recordId,
    this.recordIds,
    this.existingData,
  });

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
    
    // 编辑模式下初始化已有数据
    if (widget.isEditMode && widget.existingData != null) {
      _initializeFromExistingData();
    }
  }
  
  void _initializeFromExistingData() {
    final data = widget.existingData!;
    final sets = data['sets'] as List<dynamic>;
    
    // 检查是合并模式还是单条记录模式
    if (data.containsKey('recordIds')) {
      // 合并编辑模式
      _selectedSplit = data['splitType'] as String;
      _selectedDate = data['date'] as DateTime;
    } else {
      // 单条记录编辑模式（向后兼容）
      final record = data['record'];
      _selectedSplit = record.splitType;
      _selectedDate = record.date;
    }
    
    // 按动作名称分组
    final Map<String, List<Map<String, dynamic>>> groupedSets = {};
    for (var set in sets) {
      final name = set.exerciseName;
      groupedSets.putIfAbsent(name, () => []);
      groupedSets[name]!.add({
        'weight': set.weight,
        'reps': set.reps,
        'rpe': set.rpe,
      });
    }
    
    // 初始化选中的动作和数据
    groupedSets.forEach((exerciseName, setsList) {
      _selectedExercises[exerciseName] = true;
      _exerciseData[exerciseName] = setsList;
    });
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
        title: Text(widget.isEditMode ? '编辑力量训练' : '记录力量训练'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 日期选择
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                leading: Icon(Icons.calendar_today, color: MyApp.primaryColor),
                title: const Text('训练日期', style: TextStyle(color: MyApp.textPrimary)),
                subtitle: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: MyApp.textHint),
                onTap: _selectDate,
              ),
            ),
            const SizedBox(height: 16),

            // 分化选择
            Card(
              elevation: 0,
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
                      children: [
                        Text(
                          widget.isEditMode ? '分化类型' : '选择分化',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: MyApp.textPrimary),
                        ),
                        if (widget.isEditMode) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('不可修改', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (widget.isEditMode && _selectedSplit != null)
                      // 编辑模式：显示锁定的分化类型
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: _getSplitColor(_selectedSplit!).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _getSplitColor(_selectedSplit!).withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lock_outline, size: 16, color: _getSplitColor(_selectedSplit!)),
                            const SizedBox(width: 8),
                            Text(
                              _selectedSplit!,
                              style: TextStyle(
                                color: _getSplitColor(_selectedSplit!),
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      // 新建模式：显示选择列表
                      ..._splitTemplates.keys.map((split) {
                        Color splitColor;
                        if (split == '推日') {
                          splitColor = MyApp.pushDayColor;
                        } else if (split == '拉日') {
                          splitColor = MyApp.pullDayColor;
                        } else {
                          splitColor = MyApp.legDayColor;
                        }
                        return RadioListTile<String>(
                          title: Text(split, style: TextStyle(color: splitColor, fontWeight: FontWeight.w500)),
                          value: split,
                          groupValue: _selectedSplit,
                          activeColor: splitColor,
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
                elevation: 0,
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
                        children: [
                          Text(
                            widget.isEditMode ? '今日动作' : '选择今日动作（$_selectedSplit）',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: MyApp.textPrimary),
                          ),
                          if (widget.isEditMode) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('不可修改', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (widget.isEditMode)
                        // 编辑模式：显示已选动作列表（只读）
                        ..._selectedExercises.entries
                            .where((entry) => entry.value)
                            .map((entry) => Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.lock_outline, size: 14, color: Colors.grey.shade500),
                                      const SizedBox(width: 8),
                                      Text(
                                        entry.key,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: MyApp.textSecondary,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: MyApp.primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${_exerciseData[entry.key]?.length ?? 0}组',
                                          style: TextStyle(fontSize: 11, color: MyApp.primaryColor),
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList()
                      else
                        // 新建模式：显示选择列表
                        ..._splitTemplates[_selectedSplit]!.map((exercise) {
                          return CheckboxListTile(
                            title: Text(exercise),
                            value: _selectedExercises[exercise] ?? false,
                            activeColor: MyApp.primaryColor,
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
                icon: Icon(widget.isEditMode ? Icons.check : Icons.save),
                label: Text(widget.isEditMode ? '保存修改' : '保存记录'),
                style: FilledButton.styleFrom(
                  backgroundColor: MyApp.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exerciseName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: MyApp.textPrimary),
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
              icon: const Icon(Icons.add, size: 18),
              label: const Text('添加一组'),
              style: OutlinedButton.styleFrom(
                foregroundColor: MyApp.primaryColor,
                side: BorderSide(color: MyApp.primaryColor.withOpacity(0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
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
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: MyApp.textSecondary),
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
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            setData['weight'] == 0.0 ? '重量' : '${setData['weight'].toStringAsFixed(1)}kg',
                            style: TextStyle(
                              fontSize: 13,
                              color: setData['weight'] == 0.0 ? MyApp.textHint : MyApp.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, color: Colors.grey.shade500, size: 18),
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
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            setData['reps'] == 0 ? '次数' : '${setData['reps']}次',
                            style: TextStyle(
                              fontSize: 13,
                              color: setData['reps'] == 0 ? MyApp.textHint : MyApp.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, color: Colors.grey.shade500, size: 18),
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
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          setData['rpe'] == null ? 'RPE' : 'RPE ${setData['rpe']}',
                          style: TextStyle(
                            fontSize: 13,
                            color: setData['rpe'] == null ? MyApp.textHint : MyApp.textPrimary,
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, color: Colors.grey.shade500, size: 18),
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
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_outline, color: Color(0xFFE53935), size: 20),
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

    try {
      final repo = ref.read(strengthRepositoryProvider);
      
      if (widget.isEditMode) {
        // 编辑模式
        if (widget.recordIds != null && widget.recordIds!.isNotEmpty) {
          // 合并编辑模式：删除所有原有记录，创建一条新记录
          await repo.deleteStrengthRecords(widget.recordIds!);
          
          final durationMinutes = (exerciseSets.length * 2 + 10).clamp(30, 90);
          await repo.addStrengthRecord(
            date: _selectedDate,
            splitType: _selectedSplit!,
            durationMinutes: durationMinutes,
            totalVolume: totalVolume,
            exerciseSets: exerciseSets,
          );
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('记录已更新，总容量：${totalVolume.toStringAsFixed(0)}kg')),
            );
            Navigator.pop(context, true);
          }
        } else if (widget.recordId != null) {
          // 单条记录编辑模式（向后兼容）：更新现有记录
          await repo.updateStrengthRecordSets(
            recordId: widget.recordId!,
            exerciseSets: exerciseSets,
          );
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('记录已更新，总容量：${totalVolume.toStringAsFixed(0)}kg')),
            );
            Navigator.pop(context, true);
          }
        }
      } else {
        // 新建模式：创建新记录
        // 估算训练时长（每组2分钟）
        final durationMinutes = (exerciseSets.length * 2 + 10).clamp(30, 90);

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

  Color _getSplitColor(String splitType) {
    switch (splitType) {
      case '推日':
        return MyApp.pushDayColor;
      case '拉日':
        return MyApp.pullDayColor;
      case '腿日':
        return MyApp.legDayColor;
      default:
        return Colors.grey;
    }
  }
}