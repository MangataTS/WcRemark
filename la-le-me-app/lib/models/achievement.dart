class Achievement {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String category;
  final int? unlockedAt;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    this.unlockedAt,
  });

  static const List<Achievement> all = [
    Achievement(id: 'first_big', name: '初出茅庐', description: '记录第一次大号', icon: '🏁', category: 'milestone'),
    Achievement(id: 'morning_7', name: '晨便达人', description: '连续7天在6-9点大号', icon: '🌅', category: 'regular'),
    Achievement(id: 'paid_pooper', name: '带薪拉屎', description: '第一次带薪记录', icon: '💼', category: 'fun'),
    Achievement(id: 'regular_30', name: '规律大师', description: '连续30天每天至少一次大号', icon: '📅', category: 'regular'),
    Achievement(id: 'speed_king', name: '闪电侠', description: '5次大号时长在1-3分钟内', icon: '⚡', category: 'fun'),
    Achievement(id: 'marathon', name: '持久战', description: '单次大号超过15分钟', icon: '🏃', category: 'fun'),
    Achievement(id: 'perfect_bristol', name: '黄金便便', description: '70%以上的大号记录布里斯托分型为3-4型', icon: '🥇', category: 'health'),
    Achievement(id: 'week_warrior', name: '周末战士', description: '周末记录超过工作日', icon: '🛋️', category: 'fun'),
    Achievement(id: 'score_100', name: '破百', description: '赛季积分达到100', icon: '💯', category: 'score'),
    Achievement(id: 'score_500', name: '半千', description: '赛季积分达到500', icon: '🌟', category: 'score'),
    Achievement(id: 'score_2000', name: '两千', description: '赛季积分达到2000', icon: '💎', category: 'score'),
    Achievement(id: 'score_5000', name: '五千', description: '赛季积分达到5000', icon: '👑', category: 'score'),
    Achievement(id: 'score_10000', name: '万', description: '赛季积分达到10000', icon: '🏆', category: 'score'),
  ];

  static Achievement? getById(String id) {
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}