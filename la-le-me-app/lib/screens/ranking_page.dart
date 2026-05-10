import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ranking.dart';
import '../providers/ranking_provider.dart';

class RankingPage extends ConsumerWidget {
  const RankingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('排行榜'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '全球', icon: Icon(Icons.public)),
              Tab(text: '同城', icon: Icon(Icons.location_on)),
              Tab(text: '好友', icon: Icon(Icons.people)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _GlobalRankingTab(),
            _CityRankingTab(),
            _FriendRankingTab(),
          ],
        ),
      ),
    );
  }
}

class _GlobalRankingTab extends ConsumerWidget {
  const _GlobalRankingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingAsync = ref.watch(globalRankingProvider);

    return rankingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text('无法连接服务器', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('$e', style: const TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(globalRankingProvider),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
      data: (result) {
        if (result.items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events_outlined, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text('暂无排行数据', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 8),
                const Text('本赛季还没有人出库哦～', style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(globalRankingProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: result.items.length,
            itemBuilder: (context, index) {
              final item = result.items[index];
              return _buildRankingItem(context, item, index);
            },
          ),
        );
      },
    );
  }

  Widget _buildRankingItem(BuildContext context, RankingItem item, int index) {
    final rankColors = {
      0: const Color(0xFFFFD700),
      1: const Color(0xFFC0C0C0),
      2: const Color(0xFFCD7F32),
    };

    final rankIcon = index < 3 ? ['🥇', '🥈', '🥉'][index] : '${index + 1}';
    final rankColor = rankColors[index] ?? const Color(0xFF795548);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: index < 3 ? rankColor.withValues(alpha: 0.1) : const Color(0xFFF7F7F7),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Center(
              child: index < 3
                ? Text(rankIcon, style: const TextStyle(fontSize: 24))
                : Text(rankIcon, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF999999))),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.isAnonymous ? '匿名肠友' : item.nickname,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  item.rankTitle,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.score.toInt()}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF795548)),
              ),
              const Text('分', style: TextStyle(fontSize: 11, color: Color(0xFF999999))),
            ],
          ),
        ],
      ),
    );
  }
}

class _CityRankingTab extends StatelessWidget {
  const _CityRankingTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_on_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('同城排行榜', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF666666))),
          const SizedBox(height: 8),
          const Text('设置城市后即可查看同城排名', style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/settings/profile');
            },
            icon: const Icon(Icons.edit_location_alt),
            label: const Text('去设置'),
          ),
        ],
      ),
    );
  }
}

class _FriendRankingTab extends StatelessWidget {
  const _FriendRankingTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('好友排行榜', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF666666))),
          const SizedBox(height: 8),
          const Text('添加好友后即可查看好友排名', style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('好友功能开发中...')),
              );
            },
            icon: const Icon(Icons.person_add),
            label: const Text('添加好友'),
          ),
        ],
      ),
    );
  }
}