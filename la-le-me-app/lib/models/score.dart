class Multipliers {
  final double r;
  final double h;
  final double t;
  final double p;
  final double s;
  final double m;

  const Multipliers({
    this.r = 1.0,
    this.h = 1.0,
    this.t = 1.0,
    this.p = 1.0,
    this.s = 1.0,
    this.m = 1.0,
  });

  double get total => r * h * t * p * s * m;

  Map<String, dynamic> toJson() {
    return {
      'r': r,
      'h': h,
      't': t,
      'p': p,
      's': s,
      'm': m,
    };
  }

  factory Multipliers.fromJson(Map<String, dynamic> json) {
    return Multipliers(
      r: (json['r'] as num?)?.toDouble() ?? 1.0,
      h: (json['h'] as num?)?.toDouble() ?? 1.0,
      t: (json['t'] as num?)?.toDouble() ?? 1.0,
      p: (json['p'] as num?)?.toDouble() ?? 1.0,
      s: (json['s'] as num?)?.toDouble() ?? 1.0,
      m: (json['m'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

class ScoreSettlementResult {
  final bool accepted;
  final int newSeasonScore;
  final int newRank;
  final int rankChange;
  final List<String> newAchievements;
  final String cheatFlag;
  final String currentRankTitle;

  const ScoreSettlementResult({
    required this.accepted,
    required this.newSeasonScore,
    required this.newRank,
    this.rankChange = 0,
    this.newAchievements = const [],
    this.cheatFlag = 'OK',
    required this.currentRankTitle,
  });

  factory ScoreSettlementResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return ScoreSettlementResult(
      accepted: data['accepted'] as bool? ?? true,
      newSeasonScore: (data['new_season_score'] as num?)?.toInt() ?? 0,
      newRank: data['new_rank'] as int? ?? 0,
      rankChange: data['rank_change'] as int? ?? 0,
      newAchievements: (data['new_achievements'] as List?)?.cast<String>() ?? [],
      cheatFlag: data['cheat_flag'] as String? ?? 'OK',
      currentRankTitle: data['current_rank_title'] as String? ?? '便秘青铜',
    );
  }
}