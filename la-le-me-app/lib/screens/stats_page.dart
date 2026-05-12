import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/achievement_service.dart';
import '../providers/record_provider.dart';

final unlockedCountProvider = FutureProvider<int>((ref) async {
  ref.watch(refreshTriggerProvider);
  return await AchievementService.getUnlockedCount();
});

final totalCountProvider = FutureProvider<int>((ref) async {
  ref.watch(refreshTriggerProvider);
  return await AchievementService.getTotalCount();
});

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlockedCountAsync = ref.watch(unlockedCountProvider);
    final totalCountAsync = ref.watch(totalCountProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('数据统计')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatCard(
            context,
            icon: '🕐',
            title: '记录时间轴',
            subtitle: '按时间查看所有记录，支持删除',
            onTap: () => Navigator.pushNamed(context, '/stats/timeline'),
          ),
          const SizedBox(height: 12),
          _buildAchievementEntry(context, unlockedCountAsync, totalCountAsync),
          const SizedBox(height: 16),
          _buildStatCard(
            context,
            icon: '📊',
            title: '本周肠道周报',
            subtitle: '查看本周详细统计',
            onTap: () => Navigator.pushNamed(context, '/stats/weekly'),
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            context,
            icon: '📅',
            title: '月度统计',
            subtitle: '日历热力图与趋势',
            onTap: () => Navigator.pushNamed(context, '/stats/monthly'),
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            context,
            icon: '📈',
            title: '年度报告',
            subtitle: '年度关键词与健康报告',
            onTap: () => Navigator.pushNamed(context, '/stats/yearly'),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementEntry(
    BuildContext context,
    AsyncValue<int> unlockedAsync,
    AsyncValue<int> totalAsync,
  ) {
    final unlocked = unlockedAsync.valueOrNull ?? 0;
    final total = totalAsync.valueOrNull ?? 24;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(context, '/stats/achievements'),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF8E1), Color(0xFFFFE0B2)],
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '成就殿堂',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '已解锁 $unlocked / $total 项成就',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF795548)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Color(0xFF795548)),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: total > 0 ? unlocked / total : 0,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFD4A574).withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF795548)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Text(icon, style: const TextStyle(fontSize: 28)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(color: Color(0xFF999999))),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
