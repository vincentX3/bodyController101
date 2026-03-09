import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/providers/providers.dart';
import 'presentation/screens/records_list_screen.dart';
import 'presentation/screens/goals_screen.dart';
import 'presentation/screens/ai_coach_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Body Controller',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPageIndex = ref.watch(currentPageIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentPageIndex,
        children: const [
          HomeScreen(),
          RecordsListScreen(),
          GoalsScreen(),
          AICoachScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentPageIndex,
        onDestinationSelected: (index) {
          ref.read(currentPageIndexProvider.notifier).state = index;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            selectedIcon: Icon(Icons.home_filled),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.list),
            selectedIcon: Icon(Icons.list_alt),
            label: '记录',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag),
            label: '目标',
          ),
          NavigationDestination(
            icon: Icon(Icons.psychology),
            selectedIcon: Icon(Icons.psychology_rounded),
            label: 'AI教练',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Body Controller'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 欢迎卡片
              _buildWelcomeCard(context),
              const SizedBox(height: 24),

              // 今日统计
              _buildTodayStats(context, ref),
              const SizedBox(height: 24),

              // 本周概览
              _buildWeeklyOverview(context, ref),
              const SizedBox(height: 24),

              // 快捷操作
              _buildQuickActions(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = '早上好';
    } else if (hour < 18) {
      greeting = '下午好';
    } else {
      greeting = '晚上好';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.fitness_center,
                size: 30,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting！',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '准备好今天的训练了吗？',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayStats(BuildContext context, WidgetRef ref) {
    final todayDistanceAsync = ref.watch(todayRunDistanceProvider);
    final todayStrengthCountAsync = ref.watch(todayStrengthCountProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.today,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  '今日训练',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            todayDistanceAsync.when(
              data: (distance) => todayStrengthCountAsync.when(
                data: (strengthCount) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      context,
                      icon: Icons.directions_run,
                      label: '跑步',
                      value: '${distance.toStringAsFixed(1)} km',
                    ),
                    _buildStatItem(
                      context,
                      icon: Icons.fitness_center,
                      label: '力量',
                      value: '$strengthCount 次',
                    ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      context,
                      icon: Icons.directions_run,
                      label: '跑步',
                      value: '${distance.toStringAsFixed(1)} km',
                    ),
                    _buildStatItem(
                      context,
                      icon: Icons.fitness_center,
                      label: '力量',
                      value: '0 次',
                    ),
                  ],
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    context,
                    icon: Icons.directions_run,
                    label: '跑步',
                    value: '0 km',
                  ),
                  _buildStatItem(
                    context,
                    icon: Icons.fitness_center,
                    label: '力量',
                    value: '0 次',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[400],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyOverview(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
    
    final weekDistanceAsync = ref.watch(weekTotalDistanceProvider(weekStartDate));
    final weekTrainingDaysAsync = ref.watch(weekTrainingDaysProvider(weekStartDate));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_view_week,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  '本周概览',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            weekDistanceAsync.when(
              data: (distance) => weekTrainingDaysAsync.when(
                data: (trainingDays) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      context,
                      icon: Icons.directions_run,
                      label: '周跑量',
                      value: '${distance.toStringAsFixed(1)} km',
                    ),
                    _buildStatItem(
                      context,
                      icon: Icons.emoji_events,
                      label: '训练天数',
                      value: '$trainingDays 天',
                    ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      context,
                      icon: Icons.directions_run,
                      label: '周跑量',
                      value: '${distance.toStringAsFixed(1)} km',
                    ),
                    _buildStatItem(
                      context,
                      icon: Icons.emoji_events,
                      label: '训练天数',
                      value: '0 天',
                    ),
                  ],
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    context,
                    icon: Icons.directions_run,
                    label: '周跑量',
                    value: '0 km',
                  ),
                  _buildStatItem(
                    context,
                    icon: Icons.emoji_events,
                    label: '训练天数',
                    value: '0 天',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '快捷操作',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                context,
                icon: Icons.directions_run,
                label: '记录跑步',
                color: Colors.blue,
                onTap: () {
                  ref.read(currentPageIndexProvider.notifier).state = 1;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionButton(
                context,
                icon: Icons.fitness_center,
                label: '记录力量',
                color: Colors.green,
                onTap: () {
                  ref.read(currentPageIndexProvider.notifier).state = 1;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildQuickActionButton(
          context,
          icon: Icons.psychology,
          label: 'AI教练分析',
          color: Colors.purple,
          isFullWidth: true,
          onTap: () {
            ref.read(currentPageIndexProvider.notifier).state = 3;
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isFullWidth = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
