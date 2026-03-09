import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
        child: const Icon(Icons.add),
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
                Icon(
                  Icons.directions_run_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                const Text(
                  '还没有跑步记录',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
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
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.directions_run,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          '${record.distance.toStringAsFixed(1)} km',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('用时：${record.durationMinutes}分${record.durationSeconds}秒'),
            Text('配速：${record.pace}'),
            Text('体感：${_getPerceivedExertionEmoji(record.perceivedExertion)}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              DateFormat('MM-dd').format(record.date),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDeleteRun(context, ref, record.id),
            ),
          ],
        ),
        onTap: () {
          // 可以添加查看详情功能
        },
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
                Icon(
                  Icons.fitness_center_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                const Text(
                  '还没有力量训练记录',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
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
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: splitColor,
          child: Icon(
            Icons.fitness_center,
            color: Colors.white,
          ),
        ),
        title: Text(
          record.splitType,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('容量：${record.totalVolume.toStringAsFixed(0)} kg'),
            Text('时长：${record.durationMinutes} 分钟'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              DateFormat('MM-dd').format(record.date),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDeleteStrength(context, ref, record.id),
            ),
          ],
        ),
        onTap: () {
          // 可以添加查看详情功能
        },
      ),
    );
  }

  Color _getSplitColor(String splitType) {
    switch (splitType) {
      case '推日':
        return Colors.blue;
      case '拉日':
        return Colors.green;
      case '腿日':
        return Colors.orange;
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