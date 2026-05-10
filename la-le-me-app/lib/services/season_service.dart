import '../models/season.dart';
import '../models/ranking.dart';
import 'database_service.dart';
import 'notification_service.dart';

class SeasonService {
  static const String _seasonScoreKey = 'season_score';
  static const String _currentSeasonKey = 'current_season';
  static const double _seasonResetRatio = 0.1;

  static String getCurrentSeason() {
    return SeasonManager.getCurrentSeason();
  }

  static Future<int> getSeasonScore() async {
    final scoreStr = await DatabaseService.getSetting(_seasonScoreKey);
    return int.tryParse(scoreStr ?? '0') ?? 0;
  }

  static Future<void> setSeasonScore(int score) async {
    await DatabaseService.setSetting(_seasonScoreKey, score.toString());
  }

  static Future<void> addScore(int points) async {
    final currentScore = await getSeasonScore();
    final newScore = currentScore + points;
    await setSeasonScore(newScore);

    final prevRank = Rank.getByScore(currentScore);
    final newRank = Rank.getByScore(newScore);
    if (newRank.name != prevRank.name && newScore > currentScore) {
      await NotificationService.show(
        title: '🎉 段位提升',
        body: '恭喜晋升为 ${newRank.name}！继续加油～',
        payload: 'rank:upgrade',
      );
    }
  }

  static Future<bool> checkAndHandleSeasonChange() async {
    final currentSeason = getCurrentSeason();
    final storedSeason = await DatabaseService.getSetting(_currentSeasonKey);

    if (storedSeason == null) {
      await DatabaseService.setSetting(_currentSeasonKey, currentSeason);
      return false;
    }

    if (storedSeason != currentSeason) {
      await _performSeasonRollover(storedSeason, currentSeason);
      await DatabaseService.setSetting(_currentSeasonKey, currentSeason);
      return true;
    }

    return false;
  }

  static Future<void> _performSeasonRollover(
    String oldSeason,
    String newSeason,
  ) async {
    final currentScore = await getSeasonScore();
    final rank = Rank.getByScore(currentScore);

    await DatabaseService.saveSeasonHistory(SeasonHistory(
      season: oldSeason,
      finalScore: currentScore,
      finalRank: rank.name,
    ));

    final resetScore = (currentScore * _seasonResetRatio).round();
    await setSeasonScore(resetScore);
    await DatabaseService.setSetting(_currentSeasonKey, newSeason);

    await NotificationService.show(
      title: NotificationType.getLocalizedTitle(NotificationType.seasonChange),
      body: NotificationType.getLocalizedBody(
        NotificationType.seasonChange,
        data: {'season': newSeason},
      ),
      payload: NotificationType.seasonChange,
    );
  }

  static Future<SeasonInfo> getSeasonInfo() async {
    final currentSeason = getCurrentSeason();
    final score = await getSeasonScore();
    final rank = Rank.getByScore(score);

    return SeasonInfo(
      season: currentSeason,
      score: score,
      rank: rank,
    );
  }

  static Future<List<SeasonHistory>> getSeasonHistory() async {
    return await DatabaseService.getSeasonHistories();
  }

  static int getNextSeasonReset() {
    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    return nextMonth.difference(now).inDays;
  }
}

class SeasonInfo {
  final String season;
  final int score;
  final Rank rank;

  const SeasonInfo({
    required this.season,
    required this.score,
    required this.rank,
  });

  String get seasonLabel {
    final parts = season.split('-');
    if (parts.length == 2) {
      return '${parts[0]}年${parts[1]}月赛季';
    }
    return '$season赛季';
  }

  String get scoreLabel => '$score 分';
  String get rankLabel => '${rank.icon} ${rank.name}';
  String get progressLabel {
    if (rank.minScore == 0 && rank.maxScore == 999999999) return scoreLabel;
    return '$scoreLabel / 下一段位还需 ${rank.maxScore < 999999999 ? rank.maxScore + 1 - score : "∞"} 分';
  }
}