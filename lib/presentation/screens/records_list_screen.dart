import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../main.dart';
import '../../data/providers/providers.dart';
import '../../data/database/database_manager.dart' as db;
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

class StrengthRecordsTab extends ConsumerStatefulWidget {
  const StrengthRecordsTab({super.key});

  @override
  ConsumerState<StrengthRecordsTab> createState() => _StrengthRecordsTabState();
}

// 分组数据结构
class GroupedStrengthRecord {
  final DateTime date;
  final String splitType;
  final List<int> recordIds;
  final double totalVolume;
  final int totalDuration;
  final List<dynamic> allSets;

  GroupedStrengthRecord({
    required this.date,
    required this.splitType,
    required this.recordIds,
    required this.totalVolume,
    required this.totalDuration,
    required this.allSets,
  });

  // 生成唯一标识（日期+分化类型）
  String get key => '${date.year}-${date.month}-${date.day}-$splitType';
}

class _StrengthRecordsTabState extends ConsumerState<StrengthRecordsTab> {
  // 展开状态管理（使用分组的key）
  final Set<String> _expandedGroups = {};
  
  // 分组详情数据缓存
  final Map<String, Map<String, dynamic>?> _groupDetailsCache = {};

  @override
  Widget build(BuildContext context) {
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

        // 按日期+分化类型分组
        final groupedRecords = _groupByDateAndSplitType(records);

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: groupedRecords.length,
          itemBuilder: (context, index) {
            final group = groupedRecords[index];
            return _buildGroupedRecordCard(group);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('加载失败：$error'),
      ),
    );
  }

  // 按日期+分化类型分组
  List<GroupedStrengthRecord> _groupByDateAndSplitType(List<db.StrengthRecord> records) {
    final Map<String, GroupedStrengthRecord> groups = {};
    
    for (var record in records) {
      final date = DateTime(record.date.year, record.date.month, record.date.day);
      final key = '${date.year}-${date.month}-${date.day}-${record.splitType}';
      
      if (groups.containsKey(key)) {
        // 合并到现有分组
        final existing = groups[key]!;
        groups[key] = GroupedStrengthRecord(
          date: date,
          splitType: record.splitType,
          recordIds: [...existing.recordIds, record.id],
          totalVolume: existing.totalVolume + record.totalVolume,
          totalDuration: existing.totalDuration + record.durationMinutes.toInt(),
          allSets: existing.allSets,
        );
      } else {
        // 创建新分组
        groups[key] = GroupedStrengthRecord(
          date: date,
          splitType: record.splitType,
          recordIds: [record.id],
          totalVolume: record.totalVolume,
          totalDuration: record.durationMinutes.toInt(),
          allSets: [],
        );
      }
    }
    
    // 按日期降序排列
    final sortedGroups = groups.values.toList();
    sortedGroups.sort((a, b) => b.date.compareTo(a.date));
    
    return sortedGroups;
  }

  Widget _buildGroupedRecordCard(GroupedStrengthRecord group) {
    final splitColor = _getSplitColor(group.splitType);
    final groupKey = group.key;
    final isExpanded = _expandedGroups.contains(groupKey);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // 主卡片内容
          GestureDetector(
            onTap: () => _toggleExpand(group),
            onLongPress: () => _navigateToEdit(group),
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
                        Row(
                          children: [
                            Text(
                              group.splitType,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: splitColor),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isExpanded ? Icons.expand_less : Icons.expand_more,
                              color: Colors.grey[400],
                              size: 20,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '容量：${group.totalVolume.toStringAsFixed(0)} kg | 时长：${group.totalDuration} 分钟',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                        Text(
                          '共 ${group.recordIds.length} 条记录',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  // 右侧日期和操作按钮
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('MM-dd').format(group.date),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 编辑按钮
                          GestureDetector(
                            onTap: () => _navigateToEdit(group),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: MyApp.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.edit_outlined,
                                color: MyApp.primaryColor,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 删除按钮
                          GestureDetector(
                            onTap: () => _confirmDeleteGroup(group),
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
                ],
              ),
            ),
          ),
          // 展开详情区域
          if (isExpanded) _buildExpandedDetails(group, splitColor),
        ],
      ),
    );
  }

  Widget _buildExpandedDetails(GroupedStrengthRecord group, Color splitColor) {
    final groupKey = group.key;
    
    // 尝试从缓存获取
    if (_groupDetailsCache.containsKey(groupKey)) {
      final cachedDetail = _groupDetailsCache[groupKey];
      if (cachedDetail != null) {
        return _buildDetailContent(cachedDetail, splitColor);
      }
    }
    
    // 获取该分组的所有详情数据
    return FutureBuilder<Map<String, dynamic>?>(
      future: _loadGroupDetails(group),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          );
        }
        
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('无法加载详情'),
          );
        }
        
        final detail = snapshot.data!;
        _groupDetailsCache[groupKey] = detail;
        return _buildDetailContent(detail, splitColor);
      },
    );
  }

  Future<Map<String, dynamic>?> _loadGroupDetails(GroupedStrengthRecord group) async {
    final repo = ref.read(strengthRepositoryProvider);
    return repo.getRecordsByDateAndSplitType(group.date, group.splitType);
  }

  Widget _buildDetailContent(Map<String, dynamic> detail, Color splitColor) {
    final allSets = detail['sets'] as List<dynamic>;
    
    // 按动作名称分组并计算每组的汇总信息
    final Map<String, List<dynamic>> exercisesByName = {};
    for (var set in allSets) {
      final name = set.exerciseName;
      exercisesByName.putIfAbsent(name, () => []);
      exercisesByName[name]!.add(set);
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: exercisesByName.entries.map((entry) {
          final exerciseName = entry.key;
          final exerciseSets = entry.value;
          
          // 计算该动作的总容量
          final exerciseVolume = exerciseSets.fold<double>(0.0, (sum, set) {
            return sum + (set.weight * set.reps);
          });
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.fitness_center_outlined, color: splitColor, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        exerciseName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: MyApp.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: splitColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${exerciseSets.length}组',
                        style: TextStyle(fontSize: 11, color: splitColor, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              // 显示该动作的总容量
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Text(
                  '容量：${exerciseVolume.toStringAsFixed(0)} kg',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _toggleExpand(GroupedStrengthRecord group) {
    setState(() {
      final groupKey = group.key;
      if (_expandedGroups.contains(groupKey)) {
        _expandedGroups.remove(groupKey);
      } else {
        _expandedGroups.add(groupKey);
      }
    });
  }

  Future<void> _navigateToEdit(GroupedStrengthRecord group) async {
    // 获取该分组的所有详情数据
    final detail = await ref.read(strengthRepositoryProvider).getRecordsByDateAndSplitType(
      group.date,
      group.splitType,
    );
    if (detail == null) return;
    
    if (mounted) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StrengthRecordScreen(
            isEditMode: true,
            recordIds: group.recordIds,
            existingData: detail,
          ),
        ),
      );
      if (result == true) {
        // 清除缓存并刷新
        _groupDetailsCache.remove(group.key);
        _expandedGroups.remove(group.key);
        ref.invalidate(allStrengthRecordsProvider);
      }
    }
  }

  Future<void> _confirmDeleteGroup(GroupedStrengthRecord group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 ${group.splitType} (${DateFormat('MM-dd').format(group.date)}) 的所有记录吗？\n共 ${group.recordIds.length} 条记录'),
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
        await repo.deleteStrengthRecords(group.recordIds);
        if (mounted) {
          // 清除缓存
          _expandedGroups.remove(group.key);
          _groupDetailsCache.remove(group.key);
          ref.invalidate(allStrengthRecordsProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('记录已删除')),
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