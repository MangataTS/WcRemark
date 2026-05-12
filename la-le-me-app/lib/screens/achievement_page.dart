import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/achievement.dart';
import '../services/achievement_service.dart';

final achievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  return await AchievementService.getAllWithStatus();
});

class AchievementPage extends ConsumerWidget {
  const AchievementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('成就殿堂'),
        actions: [
          achievementsAsync.when(
            data: (list) {
              final unlocked = list.where((a) => a.isUnlocked).length;
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    '$unlocked / ${list.length}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF795548)),
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: achievementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('加载失败: $e')),
        data: (list) {
          final unlocked = list.where((a) => a.isUnlocked).length;
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(context, unlocked, list.length),
              ),
              for (final cat in Achievement.categoryOrder)
                SliverToBoxAdapter(
                  child: _buildCategorySection(context, cat, list),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int unlocked, int total) {
    final pct = total > 0 ? (unlocked / total * 100).round() : 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF795548), Color(0xFFD4A574)],
          ),
        ),
        child: Row(
          children: [
            const Text('🏆', style: TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('成就殿堂', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('已解锁 $unlocked / $total 项成就', style: const TextStyle(fontSize: 14, color: Color(0xFFFFFFFF))),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: total > 0 ? unlocked / total : 0,
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('完成度 $pct%', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(BuildContext context, String cat, List<Achievement> list) {
    final items = list.where((a) => a.category == cat).toList();
    if (items.isEmpty) return const SizedBox.shrink();

    final catUnlocked = items.where((a) => a.isUnlocked).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                AchievementDef.categoryLabel(cat),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
              ),
              const SizedBox(width: 8),
              Text(
                '$catUnlocked/${items.length}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map((a) => _buildAchievementCard(context, a)),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(BuildContext context, Achievement achievement) {
    final isUnlocked = achievement.isUnlocked;
    final progress = achievement.progress;
    final current = progress?['current'] as int? ?? 0;
    final target = achievement.target;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isUnlocked ? const Color(0xFFFFF8E1) : const Color(0xFFF5F5F5),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isUnlocked ? null : () => _showDetailDialog(context, achievement),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isUnlocked
                      ? const Color(0xFFD4A574).withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.1),
                ),
                child: Center(
                  child: Text(
                    achievement.icon,
                    style: TextStyle(
                      fontSize: 26,
                      color: isUnlocked ? null : Colors.grey.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          achievement.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isUnlocked ? const Color(0xFF1A1A1A) : const Color(0xFF999999),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          achievement.difficultyLabel,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      achievement.description,
                      style: TextStyle(fontSize: 12, color: isUnlocked ? const Color(0xFF666666) : const Color(0xFFBDBDBD)),
                    ),
                    if (isUnlocked && achievement.unlockedAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '达成时间: ${achievement.unlockTimeStr}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFFD4A574)),
                      ),
                    ],
                    if (!isUnlocked && target > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '进度: $current / $target',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                isUnlocked ? Icons.check_circle : Icons.lock_outline,
                color: isUnlocked ? const Color(0xFFD4A574) : const Color(0xFFBDBDBD),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailDialog(BuildContext context, Achievement achievement) {
    final progress = achievement.progress;
    final current = progress?['current'] as int? ?? 0;
    final target = achievement.target;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Text(achievement.icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 8),
            Expanded(child: Text(achievement.name, style: const TextStyle(fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(achievement.description, style: const TextStyle(fontSize: 14, color: Color(0xFF666666))),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('类别: ${achievement.categoryLabel}', style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                const SizedBox(width: 12),
                Text('难度: ${achievement.difficultyLabel}', style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
              ],
            ),
            if (target > 0) ...[
              const SizedBox(height: 12),
              Text('达成条件: $current / $target', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: target > 0 ? (current / target).clamp(0.0, 1.0) : 0,
                  minHeight: 6,
                  backgroundColor: Colors.grey.withValues(alpha: 0.15),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('知道了', style: TextStyle(color: Color(0xFF795548))),
          ),
        ],
      ),
    );
  }
}
