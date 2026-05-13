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
      case catMilestone:
        return '🏁 里程碑';
      case catRegular:
        return '📅 规律健康';
      case catHealth:
        return '🩺 健康指标';
      case catFun:
        return '🎮 趣味挑战';
      case catScore:
        return '🏆 积分段位';
      default:
        return '其他';
    }
  }

  static String difficultyLabel(String d) {
    switch (d) {
      case 'easy':
        return '⭐ 简单';
      case 'medium':
        return '⭐⭐ 中等';
      case 'hard':
        return '⭐⭐⭐ 困难';
      case 'epic':
        return '👑 史诗';
      default:
        return d;
    }
  }

  factory AchievementDef.fromJson(Map<String, dynamic> json) {
    return AchievementDef(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      category: json['category'] as String,
      difficulty: json['difficulty'] as String,
      target: (json['target'] as num).toInt(),
    );
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

  static List<AchievementDef> get definitions {
    return _definitionsOverride ?? [];
  }

  static List<AchievementDef>? _definitionsOverride;

  static set definitionsOverride(List<AchievementDef>? value) {
    _definitionsOverride = value;
  }

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
