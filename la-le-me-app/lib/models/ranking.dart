class Rank {
  final String name;
  final int minScore;
  final int maxScore;
  final String icon;
  final int color;

  const Rank({
    required this.name,
    required this.minScore,
    required this.maxScore,
    required this.icon,
    required this.color,
  });

  static const List<Rank> ranks = [
    Rank(name: '便秘青铜', minScore: 0, maxScore: 99, icon: '🥉', color: 0xFFCD7F32),
    Rank(name: '通畅白银', minScore: 100, maxScore: 499, icon: '🥈', color: 0xFFC0C0C0),
    Rank(name: '规律黄金', minScore: 500, maxScore: 1999, icon: '🥇', color: 0xFFFFD700),
    Rank(name: '铂金肠王', minScore: 2000, maxScore: 4999, icon: '💎', color: 0xFFE5E4E2),
    Rank(name: '钻石所长', minScore: 5000, maxScore: 9999, icon: '👑', color: 0xFFB9F2FF),
    Rank(name: '星耀肠道长', minScore: 10000, maxScore: 19999, icon: '🌟', color: 0xFF9B59B6),
    Rank(name: '最强王者', minScore: 20000, maxScore: 999999999, icon: '🏆', color: 0xFFFF6B6B),
  ];

  static Rank getByScore(int score) {
    return ranks.firstWhere(
      (r) => score >= r.minScore && score <= r.maxScore,
      orElse: () => ranks.first,
    );
  }

  static String getRankNameByScore(int score) {
    return getByScore(score).name;
  }

  static int getRankLevelByScore(int score) {
    for (int i = 0; i < ranks.length; i++) {
      if (score >= ranks[i].minScore && score <= ranks[i].maxScore) {
        return i;
      }
    }
    return 0;
  }
}

class RankingItem {
  final int rank;
  final String userId;
  final String nickname;
  final String? avatarUrl;
  final double score;
  final String rankTitle;
  final bool isAnonymous;

  const RankingItem({
    required this.rank,
    required this.userId,
    required this.nickname,
    this.avatarUrl,
    required this.score,
    required this.rankTitle,
    this.isAnonymous = false,
  });

  factory RankingItem.fromJson(Map<String, dynamic> json) {
    return RankingItem(
      rank: json['rank'] as int,
      userId: json['user_id'].toString(),
      nickname: json['nickname'] as String? ?? '匿名肠友',
      avatarUrl: json['avatar_url'] as String?,
      score: (json['score'] as num).toDouble(),
      rankTitle: json['rank_title'] as String? ?? '便秘青铜',
      isAnonymous: json['is_anonymous'] as bool? ?? false,
    );
  }
}

class RankingPageResult {
  final List<RankingItem> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const RankingPageResult({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory RankingPageResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return RankingPageResult(
      items: (data['items'] as List)
          .map((e) => RankingItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: data['total'] as int,
      page: data['page'] as int,
      limit: data['limit'] as int,
      totalPages: data['total_pages'] as int,
    );
  }
}