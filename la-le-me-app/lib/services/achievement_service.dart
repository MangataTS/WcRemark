import '../models/toilet_record.dart';
import '../models/achievement.dart';
import 'database_service.dart';

class AchievementService {
  static Future<List<String>> checkAndUnlock(
    ToiletRecord newRecord,
    List<ToiletRecord> history,
  ) async {
    final allHistory = List<ToiletRecord>.from(history)..add(newRecord);
    final unlocked = <String>[];

    final alreadyUnlocked = await getUnlockedIds();

    if (_checkFirstBig(allHistory)) {
      unlocked.add('first_big');
    }
    if (_checkMorningDays(allHistory, 7)) {
      unlocked.add('morning_7');
    }
    if (_checkPaidPoop(allHistory)) {
      unlocked.add('paid_pooper');
    }
    if (_checkStreak(allHistory, 7)) {
      unlocked.add('streak_7');
    }
    if (_checkStreak(allHistory, 30)) {
      unlocked.add('regular_30');
    }
    if (_checkBristolGold(allHistory)) {
      unlocked.add('perfect_bristol');
    }
    if (_checkSpeedKing(allHistory)) {
      unlocked.add('speed_king');
    }
    if (_checkMarathon(allHistory)) {
      unlocked.add('marathon');
    }
    if (_checkWeekendWarrior(allHistory)) {
      unlocked.add('week_warrior');
    }

    final seasonScore = await _getCurrentSeasonScore();
    if (seasonScore >= 100) unlocked.add('score_100');
    if (seasonScore >= 500) unlocked.add('score_500');
    if (seasonScore >= 2000) unlocked.add('score_2000');
    if (seasonScore >= 5000) unlocked.add('score_5000');
    if (seasonScore >= 10000) unlocked.add('score_10000');

    final newUnlocks = unlocked.where((id) => !alreadyUnlocked.contains(id)).toList();

    for (final id in newUnlocks) {
      await _saveUnlock(id);
    }

    return newUnlocks;
  }

  static Future<List<String>> getUnlockedIds() async {
    final db = await DatabaseService.database;
    final maps = await db.query('achievements', columns: ['id']);
    return maps.map((m) => m['id'] as String).toList();
  }

  static Future<List<Achievement>> getUnlockedAchievements() async {
    final ids = await getUnlockedIds();
    return ids.map((id) => Achievement.getById(id)).whereType<Achievement>().toList();
  }

  static Future<List<Achievement>> getAllAchievementsWithStatus() async {
    final unlockedIds = await getUnlockedIds();
    return Achievement.all.map((a) {
      return Achievement(
        id: a.id,
        name: a.name,
        description: a.description,
        icon: a.icon,
        category: a.category,
        unlockedAt: unlockedIds.contains(a.id) ? 1 : null,
      );
    }).toList();
  }

  static Future<Map<String, dynamic>> getProgressForAchievement(String id) async {
    final records = await DatabaseService.getRecords();
    final bigRecords = records.where((r) => r.type == RecordType.big).toList();

    switch (id) {
      case 'morning_7':
        final morningDays = _countMorningDays(bigRecords);
        return {'current': morningDays, 'target': 7};
      case 'regular_30':
        final streak = _calculateStreak(bigRecords);
        return {'current': streak, 'target': 30};
      case 'streak_7':
        final streak = _calculateStreak(bigRecords);
        return {'current': streak, 'target': 7};
      case 'score_100':
        final score = await _getCurrentSeasonScore();
        return {'current': score, 'target': 100};
      case 'score_500':
        final score = await _getCurrentSeasonScore();
        return {'current': score, 'target': 500};
      case 'score_2000':
        final score = await _getCurrentSeasonScore();
        return {'current': score, 'target': 2000};
      case 'score_5000':
        final score = await _getCurrentSeasonScore();
        return {'current': score, 'target': 5000};
      case 'score_10000':
        final score = await _getCurrentSeasonScore();
        return {'current': score, 'target': 10000};
      default:
        final unlockedIds = await getUnlockedIds();
        return {'current': unlockedIds.contains(id) ? 1 : 0, 'target': 1};
    }
  }

  static Future<void> _saveUnlock(String achievementId) async {
    final db = await DatabaseService.database;
    await db.insert('achievements', {
      'id': achievementId,
      'unlocked_at': DateTime.now().millisecondsSinceEpoch,
      'synced': 0,
    });
  }

  static bool _checkFirstBig(List<ToiletRecord> history) {
    return history.any((r) => r.type == RecordType.big);
  }

  static bool _checkMorningDays(List<ToiletRecord> history, int targetDays) {
    final count = _countMorningDays(history);
    return count >= targetDays;
  }

  static int _countMorningDays(List<ToiletRecord> records) {
    Set<String> morningDays = {};
    for (final r in records) {
      if (r.type == RecordType.big) {
        final dt = DateTime.fromMillisecondsSinceEpoch(r.timestamp);
        if (dt.hour >= 6 && dt.hour <= 9) {
          morningDays.add('${dt.year}-${dt.month}-${dt.day}');
        }
      }
    }
    return morningDays.length;
  }

  static bool _checkPaidPoop(List<ToiletRecord> history) {
    return history.any((r) => r.isPaidPoop);
  }

  static bool _checkStreak(List<ToiletRecord> history, int targetDays) {
    return _calculateStreak(history) >= targetDays;
  }

  static int _calculateStreak(List<ToiletRecord> records) {
    if (records.isEmpty) return 0;

    final bigRecords = records.where((r) => r.type == RecordType.big).toList();
    if (bigRecords.isEmpty) return 0;

    Set<String> daysWithBig = {};
    for (final r in bigRecords) {
      final dt = DateTime.fromMillisecondsSinceEpoch(r.timestamp);
      daysWithBig.add('${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}');
    }

    int streak = 0;
    DateTime checkDay = DateTime.now();
    for (int i = 0; i < 365; i++) {
      final dayStr = '${checkDay.year}-${checkDay.month.toString().padLeft(2, '0')}-${checkDay.day.toString().padLeft(2, '0')}';
      if (daysWithBig.contains(dayStr)) {
        streak++;
      } else if (i > 0) {
        break;
      }
      checkDay = checkDay.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static bool _checkBristolGold(List<ToiletRecord> history) {
    final bigRecords = history.where((r) => r.type == RecordType.big).toList();
    if (bigRecords.length < 10) return false;
    final goldCount = bigRecords.where((r) => r.bristolType == 3 || r.bristolType == 4).length;
    return (goldCount / bigRecords.length) > 0.7;
  }

  static bool _checkSpeedKing(List<ToiletRecord> history) {
    final bigRecords = history.where((r) =>
      r.type == RecordType.big && r.duration != null && r.duration! > 0
    ).toList();
    int fastCount = 0;
    for (final r in bigRecords) {
      final minutes = r.duration! / 60;
      if (minutes >= 1 && minutes <= 3) fastCount++;
    }
    return fastCount >= 5;
  }

  static bool _checkMarathon(List<ToiletRecord> history) {
    return history.any((r) =>
      r.type == RecordType.big && r.duration != null && r.duration! >= 900
    );
  }

  static bool _checkWeekendWarrior(List<ToiletRecord> history) {
    final recent = history.where((r) {
      final dt = DateTime.fromMillisecondsSinceEpoch(r.timestamp);
      final diff = DateTime.now().difference(dt);
      return diff.inDays <= 30;
    }).toList();

    if (recent.isEmpty) return false;

    final weekendCount = recent.where((r) {
      final dt = DateTime.fromMillisecondsSinceEpoch(r.timestamp);
      return dt.weekday == DateTime.saturday || dt.weekday == DateTime.sunday;
    }).length;

    final weekdayCount = recent.length - weekendCount;
    return weekendCount > weekdayCount && recent.length >= 10;
  }

  static Future<int> _getCurrentSeasonScore() async {
    final scoreStr = await DatabaseService.getSetting('season_score');
    return int.tryParse(scoreStr ?? '0') ?? 0;
  }
}