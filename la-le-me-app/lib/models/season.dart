class SeasonHistory {
  final String season;
  final int finalScore;
  final String finalRank;

  const SeasonHistory({
    required this.season,
    required this.finalScore,
    required this.finalRank,
  });

  Map<String, dynamic> toMap() {
    return {
      'season': season,
      'final_score': finalScore,
      'final_rank': finalRank,
    };
  }

  factory SeasonHistory.fromMap(Map<String, dynamic> map) {
    return SeasonHistory(
      season: map['season'] as String,
      finalScore: map['final_score'] as int,
      finalRank: map['final_rank'] as String,
    );
  }
}

class SeasonManager {
  static String getCurrentSeason() {
    DateTime now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }
}