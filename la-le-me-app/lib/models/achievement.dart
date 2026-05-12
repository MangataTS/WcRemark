class AchievementDef {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String category;
  final String difficulty;
  final int target;

  const AchievementDef({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.difficulty,
    this.target = 0,
  });

  static const String catMilestone = 'milestone';
  static const String catRegular = 'regular';
  static const String catHealth = 'health';
  static const String catFun = 'fun';
  static const String catScore = 'score';

  static String categoryLabel(String cat) {
    switch (cat) {
      case catMilestone: return '🏁 里程碑';
      case catRegular: return '📅 规律健康';
      case catHealth: return '🩺 健康指标';
      case catFun: return '🎮 趣味挑战';
      case catScore: return '🏆 积分段位';
      default: return '其他';
    }
  }

  static String difficultyLabel(String d) {
    switch (d) {
      case 'easy': return '⭐ 简单';
      case 'medium': return '⭐⭐ 中等';
      case 'hard': return '⭐⭐⭐ 困难';
      case 'epic': return '👑 史诗';
      default: return d;
    }
  }
}

class Achievement {
  final AchievementDef def;
  final int? unlockedAt;
  final Map<String, dynamic>? progress;

  const Achievement({
    required this.def,
    this.unlockedAt,
    this.progress,
  });

  String get id => def.id;
  String get name => def.name;
  String get description => def.description;
  String get icon => def.icon;
  String get category => def.category;
  String get difficulty => def.difficulty;
  int get target => def.target;
  bool get isUnlocked => unlockedAt != null;

  String get categoryLabel => AchievementDef.categoryLabel(category);
  String get difficultyLabel => AchievementDef.difficultyLabel(difficulty);

  String get unlockTimeStr {
    if (unlockedAt == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(unlockedAt!);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  static final List<AchievementDef> definitions = [
    // ===== 里程碑 (milestone) =====
    AchievementDef(
      id: 'first_big', name: '初出茅庐', description: '完成第一次大号记录',
      icon: '🏁', category: AchievementDef.catMilestone, difficulty: 'easy',
    ),
    AchievementDef(
      id: 'first_10', name: '渐入佳境', description: '累计完成10次大号记录',
      icon: '📝', category: AchievementDef.catMilestone, difficulty: 'easy', target: 10,
    ),
    AchievementDef(
      id: 'first_50', name: '肠道常客', description: '累计完成50次大号记录',
      icon: '🎖️', category: AchievementDef.catMilestone, difficulty: 'medium', target: 50,
    ),
    AchievementDef(
      id: 'first_100', name: '百战老将', description: '累计完成100次大号记录',
      icon: '🏅', category: AchievementDef.catMilestone, difficulty: 'hard', target: 100,
    ),
    AchievementDef(
      id: 'first_365', name: '一年之约', description: '累计完成365次大号记录',
      icon: '🗓️', category: AchievementDef.catMilestone, difficulty: 'epic', target: 365,
    ),

    // ===== 规律健康 (regular) =====
    AchievementDef(
      id: 'morning_7', name: '晨便达人', description: '连续7天在6:00-9:00之间完成大号',
      icon: '🌅', category: AchievementDef.catRegular, difficulty: 'medium', target: 7,
    ),
    AchievementDef(
      id: 'morning_21', name: '日出而作', description: '累计21天在6:00-9:00之间完成大号',
      icon: '☀️', category: AchievementDef.catRegular, difficulty: 'hard', target: 21,
    ),
    AchievementDef(
      id: 'streak_7', name: '一周规律', description: '连续7天每天至少完成一次大号',
      icon: '📅', category: AchievementDef.catRegular, difficulty: 'medium', target: 7,
    ),
    AchievementDef(
      id: 'streak_30', name: '规律大师', description: '连续30天每天至少完成一次大号',
      icon: '🗓️', category: AchievementDef.catRegular, difficulty: 'hard', target: 30,
    ),
    AchievementDef(
      id: 'streak_100', name: '生物钟活化石', description: '连续100天每天至少完成一次大号',
      icon: '🏰', category: AchievementDef.catRegular, difficulty: 'epic', target: 100,
    ),

    // ===== 健康指标 (health) =====
    AchievementDef(
      id: 'perfect_bristol', name: '黄金便便', description: '累计10次以上大号且70%以上为布里斯托3-4型',
      icon: '🥇', category: AchievementDef.catHealth, difficulty: 'hard', target: 10,
    ),
    AchievementDef(
      id: 'bristol_master', name: '便便百科全书', description: '集齐全部7种布里斯托分型记录',
      icon: '📚', category: AchievementDef.catHealth, difficulty: 'epic', target: 7,
    ),
    AchievementDef(
      id: 'fiber_rich', name: '膳食纤维大使', description: '连续3天大号布里斯托分型为3-4型',
      icon: '🥬', category: AchievementDef.catHealth, difficulty: 'medium', target: 3,
    ),
    AchievementDef(
      id: 'health_a_7', name: '模范肠道', description: '连续7周健康评级为A级',
      icon: '💚', category: AchievementDef.catHealth, difficulty: 'hard', target: 7,
    ),

    // ===== 趣味挑战 (fun) =====
    AchievementDef(
      id: 'paid_pooper', name: '带薪拉屎', description: '累计完成10次带薪记录',
      icon: '💼', category: AchievementDef.catFun, difficulty: 'easy', target: 10,
    ),
    AchievementDef(
      id: 'paid_king', name: '摸鱼之神', description: '累计完成50次带薪记录，总时长超过5小时',
      icon: '💰', category: AchievementDef.catFun, difficulty: 'hard', target: 50,
    ),
    AchievementDef(
      id: 'speed_king', name: '闪电侠', description: '累计5次大号时长在1-3分钟之间',
      icon: '⚡', category: AchievementDef.catFun, difficulty: 'easy', target: 5,
    ),
    AchievementDef(
      id: 'marathon', name: '持久战', description: '单次大号时长超过15分钟',
      icon: '🏃', category: AchievementDef.catFun, difficulty: 'medium', target: 900,
    ),
    AchievementDef(
      id: 'week_warrior', name: '周末战士', description: '近30天周末记录数超过工作日记录数',
      icon: '🛋️', category: AchievementDef.catFun, difficulty: 'medium',
    ),
    AchievementDef(
      id: 'mood_recorder', name: '情绪管理师', description: '累计记录5种不同心情的大号',
      icon: '🎭', category: AchievementDef.catFun, difficulty: 'medium', target: 5,
    ),
    AchievementDef(
      id: 'night_owl', name: '夜猫子', description: '累计在凌晨0:00-5:00完成3次大号',
      icon: '🦉', category: AchievementDef.catFun, difficulty: 'medium', target: 3,
    ),
    AchievementDef(
      id: 'double_kill', name: '双杀', description: '同一天内完成大号和小号各一次',
      icon: '⚔️', category: AchievementDef.catFun, difficulty: 'easy',
    ),

    // ===== 积分段位 (score) =====
    AchievementDef(
      id: 'score_500', name: '规律达人', description: '赛季积分达到500分',
      icon: '🌟', category: AchievementDef.catScore, difficulty: 'medium', target: 500,
    ),
    AchievementDef(
      id: 'score_2000', name: '肠道大师', description: '赛季积分达到2000分',
      icon: '💎', category: AchievementDef.catScore, difficulty: 'hard', target: 2000,
    ),
    AchievementDef(
      id: 'score_10000', name: '传奇所长', description: '赛季积分达到10000分',
      icon: '👑', category: AchievementDef.catScore, difficulty: 'epic', target: 10000,
    ),
  ];

  static final List<String> categoryOrder = [
    AchievementDef.catMilestone,
    AchievementDef.catRegular,
    AchievementDef.catHealth,
    AchievementDef.catFun,
    AchievementDef.catScore,
  ];

  static AchievementDef? getDefById(String id) {
    try {
      return definitions.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<AchievementDef> getByCategory(String category) {
    return definitions.where((a) => a.category == category).toList();
  }
}
