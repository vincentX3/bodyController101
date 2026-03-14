import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../main.dart';
import '../../data/providers/providers.dart';
import '../../data/repositories/run_repository.dart';

class RunRecordScreen extends ConsumerStatefulWidget {
  const RunRecordScreen({super.key});

  @override
  ConsumerState<RunRecordScreen> createState() => _RunRecordScreenState();
}

class _RunRecordScreenState extends ConsumerState<RunRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _distanceController = TextEditingController();
  final _minutesController = TextEditingController();
  final _secondsController = TextEditingController();
  int _perceivedExertion = 3;
  DateTime _selectedDate = DateTime.now();
  String _calculatedPace = '--:--/km';

  // 快速距离标签
  final List<double> _quickDistances = [5.0, 10.0, 15.0, 21.1];

  @override
  void dispose() {
    _distanceController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  // 计算配速
  void _calculatePace() {
    final distance = double.tryParse(_distanceController.text);
    final minutes = int.tryParse(_minutesController.text) ?? 0;
    final seconds = int.tryParse(_secondsController.text) ?? 0;

    if (distance != null && distance > 0) {
      final totalSeconds = minutes * 60 + seconds;
      final paceSecondsPerKm = totalSeconds / distance;
      final paceMinutes = paceSecondsPerKm ~/ 60;
      final paceSeconds = (paceSecondsPerKm % 60).round();
      setState(() {
        _calculatedPace = '${paceMinutes.toString().padLeft(2, '0')}:${paceSeconds.toString().padLeft(2, '0')}/km';
      });
    } else {
      setState(() {
        _calculatedPace = '--:--/km';
      });
    }
  }

  // 选择日期
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

  // 保存记录
  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    final distance = double.parse(_distanceController.text);
    final minutes = int.parse(_minutesController.text);
    final seconds = int.parse(_secondsController.text);

    try {
      final repo = ref.read(runRepositoryProvider);
      await repo.addRunRecord(
        date: _selectedDate,
        distance: distance,
        durationMinutes: minutes,
        durationSeconds: seconds,
        pace: _calculatedPace,
        perceivedExertion: _perceivedExertion,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('跑步记录已保存')),
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

  // 清空表单
  void _clearForm() {
    _distanceController.clear();
    _minutesController.clear();
    _secondsController.clear();
    setState(() {
      _perceivedExertion = 3;
      _selectedDate = DateTime.now();
      _calculatedPace = '--:--/km';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('记录跑步'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
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

              // 距离输入
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
                      const Text(
                        '距离 (km)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: MyApp.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _distanceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: '输入距离',
                          suffixText: 'km',
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入距离';
                          }
                          final distance = double.tryParse(value);
                          if (distance == null || distance <= 0) {
                            return '请输入有效的距离';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      // 快速距离标签
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _quickDistances.map((dist) {
                          return ActionChip(
                            label: Text('${dist.toStringAsFixed(1)}km'),
                            backgroundColor: MyApp.primaryColor.withOpacity(0.1),
                            labelStyle: TextStyle(color: MyApp.primaryColor, fontWeight: FontWeight.w500),
                            onPressed: () {
                              _distanceController.text = dist.toStringAsFixed(1);
                              _calculatePace();
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 时间输入
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
                      const Text(
                        '用时',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: MyApp.textPrimary),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _minutesController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: '分钟',
                                hintText: '0',
                                filled: true,
                                fillColor: const Color(0xFFF5F5F5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onChanged: (_) => _calculatePace(),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '必填';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _secondsController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: '秒',
                                hintText: '0',
                                filled: true,
                                fillColor: const Color(0xFFF5F5F5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onChanged: (_) => _calculatePace(),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return null; // 可选字段，允许为空
                                }
                                final seconds = int.tryParse(value);
                                if (seconds == null || seconds < 0 || seconds >= 60) {
                                  return '0-59';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // 配速显示
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: MyApp.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.speed,
                              color: MyApp.primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '配速：$_calculatedPace',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: MyApp.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 体感评分
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
                      const Text(
                        '体感评分',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: MyApp.textPrimary),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(5, (index) {
                          return Column(
                            children: [
                              IconButton(
                                iconSize: 40,
                                icon: Icon(
                                  index < _perceivedExertion ? Icons.star : Icons.star_border,
                                  color: index < _perceivedExertion ? MyApp.legDayColor : Colors.grey.shade400,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _perceivedExertion = index + 1;
                                  });
                                },
                              ),
                              Text(
                                '${index + 1}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getPerceivedExertionDescription(_perceivedExertion),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 保存按钮
              FilledButton.icon(
                onPressed: _saveRecord,
                icon: const Icon(Icons.save),
                label: const Text('保存记录'),
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
          ),
        ),
      ),
    );
  }

  String _getPerceivedExertionDescription(int value) {
    switch (value) {
      case 1:
        return '非常轻松';
      case 2:
        return '轻松';
      case 3:
        return '适中';
      case 4:
        return '吃力';
      case 5:
        return '非常吃力';
      default:
        return '';
    }
  }
}