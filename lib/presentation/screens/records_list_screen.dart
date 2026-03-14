import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../main.dart';
import '../../data/providers/providers.dart';
import '../../data/repositories/run_repository.dart';
import '../../data/repositories/strength_repository.dart';
import 'run_record_screen.dart';
import 'strength_record_screen.dart';

class RecordsListScreen extends ConsumerStatefulWidget {
  const RecordsListScreen({super.key});

  @override
  ConsumerState<RecordsListScreen> createState() => _RecordsListScreenState();
}

class _RecordsListScreenState extends ConsumerState<RecordsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('训练记录'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '跑步'),
            Tab(text: '力量训练'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          RunRecordsTab(),
          StrengthRecordsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_tabController.index == 0) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RunRecordScreen()),
            );
            if (result == true) {
              ref.invalidate(allRunRecordsProvider);
            }
          } else {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const StrengthRecordScreen()),
            );
            if (result == true) {
              ref.invalidate(allStrengthRecordsProvider);
            }
          }
        },
        backgroundColor: MyApp.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class RunRecordsTab extends ConsumerWidget {
  const RunRecordsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runRecordsAsync = ref.watch(allRunRecordsProvider);

    return runRecordsAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: MyApp.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    Icons.directions_run_outlined,
                    size: 50,
                    color: MyApp.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '还没有跑步记录',
                  style: TextStyle(fontSize: 18, color: MyApp.textPrimary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  '点击右下角按钮添加记录',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            return _buildRunRecordCard(context, ref, record);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('加载失败：$error'),
      ),
    );
  }

  Widget _buildRunRecordCard(BuildContext context, WidgetRef ref, dynamic record) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // 左侧图标
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: MyApp.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.directions_run,
                color: MyApp.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            // 中间内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${record.distance.toStringAsFixed(1)} km',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: MyApp.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text('用时：${record.durationMinutes}分${record.durationSeconds}秒', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  Text('配速：${record.pace}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  Text('体感：${_getPerceivedExertionEmoji(record.perceivedExertion)}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
            ),
            // 右侧日期和删除按钮
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('MM-dd').format(record.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _confirmDeleteRun(context, ref, record.id),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFE53935),
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getPerceivedExertionEmoji(int value) {
    return '⭐' * value;
  }

  Future<void> _confirmDeleteRun(BuildContext context, WidgetRef ref, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条记录吗？'),
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
        final repo = ref.read(runRepositoryProvider);
        await repo.deleteRunRecord(id);
        if (context.mounted) {
          ref.invalidate(allRunRecordsProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('记录已删除')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败：$e')),
          );
        }
      }
    }
  }
}

class StrengthRecordsTab extends ConsumerWidget {
  const StrengthRecordsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strengthRecordsAsync = ref.watch(allStrengthRecordsProvider);

    return strengthRecordsAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: MyApp.secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    Icons.fitness_center_outlined,
                    size: 50,
                    color: MyApp.secondaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '还没有力量训练记录',
                  style: TextStyle(fontSize: 18, color: MyApp.textPrimary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  '点击右下角按钮添加记录',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            return _buildStrengthRecordCard(context, ref, record);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('加载失败：$error'),
      ),
    );
  }

  Widget _buildStrengthRecordCard(BuildContext context, WidgetRef ref, dynamic record) {
    final splitColor = _getSplitColor(record.splitType);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // 左侧图标
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: splitColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.fitness_center,
                color: splitColor,
              ),
            ),
            const SizedBox(width: 12),
            // 中间内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.splitType,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: splitColor),
                  ),
                  const SizedBox(height: 4),
                  Text('容量：${record.totalVolume.toStringAsFixed(0)} kg', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  Text('时长：${record.durationMinutes} 分钟', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
            ),
            // 右侧日期和删除按钮
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('MM-dd').format(record.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _confirmDeleteStrength(context, ref, record.id),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFE53935),
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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

  Future<void> _confirmDeleteStrength(BuildContext context, WidgetRef ref, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条记录吗？'),
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
        final repo = ref.read(strengthRepositoryProvider);
        await repo.deleteStrengthRecord(id);
        if (context.mounted) {
          ref.invalidate(allStrengthRecordsProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('记录已删除')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败：$e')),
          );
        }
      }
    }
  }
}