import '../models/toilet_record.dart';
import '../models/achievement.dart';
import 'database_service.dart';

class AchievementService {
  static Future<List<String>> checkAndUnlock(
    ToiletRecord newRecord,
    List<ToiletRecord> history,
  ) async {
    final allHistory = List<ToiletRecord>.from(history)..add(newRecord);
    final alreadyUnlocked = await getUnlockedIds();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final unlocked = <String>[];

    final bigRecords = allHistory.where((r) => r.type == RecordType.big).toList();
    final totalBig = bigRecords.length;

    if (!alreadyUnlocked.contains('first_big')) {
      if (_checkFirstBig(allHistory)) { unlocked.add('first_big'); }
    }
    if (!alreadyUnlocked.contains('first_10') && totalBig >= 10) {
      unlocked.add('first_10');
    }
    if (!alreadyUnlocked.contains('first_50') && totalBig >= 50) {
      unlocked.add('first_50');
    }
    if (!alreadyUnlocked.contains('first_100') && totalBig >= 100) {
      unlocked.add('first_100');
    }
    if (!alreadyUnlocked.contains('first_365') && totalBig >= 365) {
      unlocked.add('first_365');
    }

    if (!alreadyUnlocked.contains('morning_7')) {
      if (_morningStreak(bigRecords) >= 7) { unlocked.add('morning_7'); }
    }
    if (!alreadyUnlocked.contains('morning_21')) {
      if (_countMorningDays(bigRecords) >= 21) { unlocked.add('morning_21'); }
    }

    final streak = _calculateStreak(bigRecords);
    if (!alreadyUnlocked.contains('streak_7') && streak >= 7) {
      unlocked.add('streak_7');
    }
    if (!alreadyUnlocked.contains('streak_30') && streak >= 30) {
      unlocked.add('streak_30');
    }
    if (!alreadyUnlocked.contains('streak_100') && streak >= 100) {
      unlocked.add('streak_100');
    }

    if (!alreadyUnlocked.contains('perfect_bristol')) {
      if (_checkBristolGold(bigRecords)) { unlocked.add('perfect_bristol'); }
    }
    if (!alreadyUnlocked.contains('bristol_master')) {
      if (_checkBristolAll(bigRecords)) { unlocked.add('bristol_master'); }
    }
    if (!alreadyUnlocked.contains('fiber_rich')) {
      if (_checkFiberRich(bigRecords)) { unlocked.add('fiber_rich'); }
    }

    if (!alreadyUnlocked.contains('paid_pooper')) {
      final paidCount = allHistory.where((r) => r.isPaidPoop).length;
      if (paidCount >= 10) { unlocked.add('paid_pooper'); }
    }
    if (!alreadyUnlocked.contains('paid_king')) {
      if (_checkPaidKing(allHistory)) { unlocked.add('paid_king'); }
    }
    if (!alreadyUnlocked.contains('speed_king')) {
      if (_checkSpeedKing(bigRecords)) { unlocked.add('speed_king'); }
    }
    if (!alreadyUnlocked.contains('marathon')) {
      if (_checkMarathon(bigRecords)) { unlocked.add('marathon'); }
    }
    if (!alreadyUnlocked.contains('week_warrior')) {
      if (_checkWeekendWarrior(allHistory)) { unlocked.add('week_warrior'); }
    }
    if (!alreadyUnlocked.contains('mood_recorder')) {
      if (_checkMoodRecorder(allHistory)) { unlocked.add('mood_recorder'); }
    }
    if (!alreadyUnlocked.contains('night_owl')) {
      if (_checkNightOwl(bigRecords)) { unlocked.add('night_owl'); }
    }
    if (!alreadyUnlocked.contains('double_kill')) {
      if (_checkDoubleKill(allHistory)) { unlocked.add('double_kill'); }
    }

    final seasonScore = await _getCurrentSeasonScore();
    if (!alreadyUnlocked.contains('score_500') && seasonScore >= 500) {
      unlocked.add('score_500');
    }
    if (!alreadyUnlocked.contains('score_2000') && seasonScore >= 2000) {
      unlocked.add('score_2000');
    }
    if (!alreadyUnlocked.contains('score_10000') && seasonScore >= 10000) {
      unlocked.add('score_10000');
    }

    final newUnlocks = unlocked.where((id) => !alreadyUnlocked.contains(id)).toList();
    for (final id in newUnlocks) {
      await _saveUnlock(id, timestamp);
    }
    return newUnlocks;
  }

  static Future<List<String>> getUnlockedIds() async {
    final db = await DatabaseService.database;
    final maps = await db.query('achievements', columns: ['id']);
    return maps.map((m) => m['id'] as String).toList();
  }

  static Future<int?> getUnlockTime(String id) async {
    final db = await DatabaseService.database;
    final maps = await db.query('achievements',
      where: 'id = ?', whereArgs: [id], columns: ['unlocked_at']);
    if (maps.isEmpty) return null;
    return maps.first['unlocked_at'] as int;
  }

  static Future<List<Achievement>> getAllWithStatus() async {
    final unlockedIds = await getUnlockedIds();
    final allRecords = await DatabaseService.getRecords();
    final bigRecords = allRecords.where((r) => r.type == RecordType.big).toList();
    final seasonScore = await _getCurrentSeasonScore();

    final results = <Achievement>[];
    for (final def in Achievement.definitions) {
      final isUnlocked = unlockedIds.contains(def.id);
      int? unlockAt;
      if (isUnlocked) {
        final db = await DatabaseService.database;
        final maps = await db.query('achievements',
          where: 'id = ?', whereArgs: [def.id], columns: ['unlocked_at']);
        if (maps.isNotEmpty) unlockAt = maps.first['unlocked_at'] as int;
      }

      Map<String, dynamic>? progress;
      if (!isUnlocked) {
        progress = _calcProgress(def.id, bigRecords, allRecords, seasonScore,
          unlockedIds);
      }

      results.add(Achievement(def: def, unlockedAt: unlockAt, progress: progress));
    }
    return results;
  }

  static Map<String, dynamic> _calcProgress(
    String id, List<ToiletRecord> bigRecords, List<ToiletRecord> allRecords,
    int seasonScore, List<String> unlockedIds,
  ) {
    final totalBig = bigRecords.length;
    final streak = _calculateStreak(bigRecords);
    switch (id) {
      case 'first_10': return {'current': totalBig, 'target': 10};
      case 'first_50': return {'current': totalBig, 'target': 50};
      case 'first_100': return {'current': totalBig, 'target': 100};
      case 'first_365': return {'current': totalBig, 'target': 365};
      case 'morning_7': return {'current': _morningStreak(bigRecords), 'target': 7};
      case 'morning_21': return {'current': _countMorningDays(bigRecords), 'target': 21};
      case 'streak_7': return {'current': streak, 'target': 7};
      case 'streak_30': return {'current': streak, 'target': 30};
      case 'streak_100': return {'current': streak, 'target': 100};
      case 'paid_pooper': {
        final c = allRecords.where((r) => r.isPaidPoop).length;
        return {'current': c, 'target': 10};
      }
      case 'paid_king': {
        final c = allRecords.where((r) => r.isPaidPoop).length;
        final totalSec = allRecords.where((r) => r.isPaidPoop && r.duration != null)
            .fold<int>(0, (s, r) => s + r.duration!);
        final hours = (totalSec / 3600).toStringAsFixed(1);
        return {'current': c, 'target': 50, 'paid_hours': hours};
      }
      case 'speed_king': {
        int c = 0;
        for (final r in bigRecords) {
          if (r.duration != null) {
            final min = r.duration! / 60;
            if (min >= 1 && min <= 3) c++;
          }
        }
        return {'current': c, 'target': 5};
      }
      case 'perfect_bristol': {
        final gold = bigRecords.where((r) => r.bristolType == 3 || r.bristolType == 4).length;
        return {'current': bigRecords.length, 'target': 10, 'gold_count': gold};
      }
      case 'bristol_master': {
        final types = bigRecords.map((r) => r.bristolType).whereType<int>().toSet();
        return {'current': types.length, 'target': 7};
      }
      case 'fiber_rich': {
        int c = 0;
        Set<String> seen = {};
        for (final r in bigRecords.reversed) {
          final bt = r.bristolType;
          if (bt != 3 && bt != 4) break;
          final dt = DateTime.fromMillisecondsSinceEpoch(r.timestamp);
          final key = '${dt.year}-${dt.month}-${dt.day}';
          if (!seen.contains(key)) { seen.add(key); c++; }
        }
        return {'current': c, 'target': 3};
      }
      case 'mood_recorder': {
        final moods = allRecords.where((r) => r.mood != null).map((r) => r.mood!).toSet();
        return {'current': moods.length, 'target': 5};
      }
      case 'night_owl': {
        int c = 0;
        for (final r in bigRecords) {
          final h = DateTime.fromMillisecondsSinceEpoch(r.timestamp).hour;
          if (h >= 0 && h < 5) c++;
        }
        return {'current': c, 'target': 3};
      }
      case 'score_500': return {'current': seasonScore, 'target': 500};
      case 'score_2000': return {'current': seasonScore, 'target': 2000};
      case 'score_10000': return {'current': seasonScore, 'target': 10000};
      default: return {'current': unlockedIds.contains(id) ? 1 : 0, 'target': 1};
    }
  }

  static Future<void> _saveUnlock(String achievementId, int timestamp) async {
    final db = await DatabaseService.database;
    await db.insert('achievements', {
      'id': achievementId,
      'unlocked_at': timestamp,
      'synced': 0,
    });
  }

  static Future<int> getUnlockedCount() async {
    final ids = await getUnlockedIds();
    return ids.length;
  }

  static Future<int> getTotalCount() async {
    return Achievement.definitions.length;
  }

  // =========== Detection helpers ===========

  static bool _checkFirstBig(List<ToiletRecord> history) {
    return history.any((r) => r.type == RecordType.big);
  }

  static int _countMorningDays(List<ToiletRecord> records) {
    Set<String> days = {};
    for (final r in records) {
      if (r.type == RecordType.big) {
        final dt = DateTime.fromMillisecondsSinceEpoch(r.timestamp);
        if (dt.hour >= 6 && dt.hour <= 9) {
          days.add('${dt.year}-${dt.month}-${dt.day}');
        }
      }
    }
    return days.length;
  }

  static int _morningStreak(List<ToiletRecord> records) {
    Set<String> days = {};
    for (final r in records) {
      if (r.type == RecordType.big) {
        final dt = DateTime.fromMillisecondsSinceEpoch(r.timestamp);
        if (dt.hour >= 6 && dt.hour <= 9) {
          days.add('${dt.year}-${dt.month}-${dt.day}');
        }
      }
    }
    int streak = 0;
    DateTime check = DateTime.now();
    for (int i = 0; i < 365; i++) {
      final key = '${check.year}-${check.month}-${check.day}';
      if (days.contains(key)) {
        streak++;
      } else if (i > 0) {
        break;
      }
      check = check.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static int _calculateStreak(List<ToiletRecord> records) {
    Set<String> days = {};
    for (final r in records) {
      final dt = DateTime.fromMillisecondsSinceEpoch(r.timestamp);
      days.add('${dt.year}-${dt.month}-${dt.day}');
    }
    int streak = 0;
    DateTime check = DateTime.now();
    for (int i = 0; i < 365; i++) {
      final key = '${check.year}-${check.month}-${check.day}';
      if (days.contains(key)) {
        streak++;
      } else if (i > 0) {
        break;
      }
      check = check.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static bool _checkBristolGold(List<ToiletRecord> bigRecords) {
    if (bigRecords.length < 10) return false;
    final gold = bigRecords.where((r) => r.bristolType == 3 || r.bristolType == 4).length;
    return (gold / bigRecords.length) > 0.7;
  }

  static bool _checkBristolAll(List<ToiletRecord> bigRecords) {
    final types = bigRecords.map((r) => r.bristolType).whereType<int>().toSet();
    return types.length >= 7;
  }

  static bool _checkFiberRich(List<ToiletRecord> bigRecords) {
    int streak = 0;
    Set<String> seen = {};
    for (final r in bigRecords.reversed) {
      final bt = r.bristolType;
      if (bt != 3 && bt != 4) break;
      final dt = DateTime.fromMillisecondsSinceEpoch(r.timestamp);
      final key = '${dt.year}-${dt.month}-${dt.day}';
      if (!seen.contains(key)) { seen.add(key); streak++; }
      if (streak >= 3) return true;
    }
    return false;
  }

  static bool _checkPaidKing(List<ToiletRecord> records) {
    final paid = records.where((r) => r.isPaidPoop).toList();
    if (paid.length < 50) return false;
    final totalSec = paid.where((r) => r.duration != null)
        .fold<int>(0, (s, r) => s + r.duration!);
    return totalSec >= 18000;
  }

  static bool _checkSpeedKing(List<ToiletRecord> bigRecords) {
    int fastCount = 0;
    for (final r in bigRecords) {
      if (r.duration == null) continue;
      final min = r.duration! / 60;
      if (min >= 1 && min <= 3) fastCount++;
    }
    return fastCount >= 5;
  }

  static bool _checkMarathon(List<ToiletRecord> bigRecords) {
    return bigRecords.any((r) => r.duration != null && r.duration! >= 900);
  }

  static bool _checkWeekendWarrior(List<ToiletRecord> records) {
    final recent = records.where((r) {
      final diff = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(r.timestamp));
      return diff.inDays <= 30;
    }).toList();
    if (recent.length < 10) return false;
    final wkend = recent.where((r) {
      final wd = DateTime.fromMillisecondsSinceEpoch(r.timestamp).weekday;
      return wd == DateTime.saturday || wd == DateTime.sunday;
    }).length;
    return wkend > (recent.length - wkend);
  }

  static bool _checkMoodRecorder(List<ToiletRecord> records) {
    final moods = records.where((r) => r.mood != null).map((r) => r.mood!).toSet();
    return moods.length >= 5;
  }

  static bool _checkNightOwl(List<ToiletRecord> bigRecords) {
    int c = 0;
    for (final r in bigRecords) {
      final h = DateTime.fromMillisecondsSinceEpoch(r.timestamp).hour;
      if (h >= 0 && h < 5) c++;
    }
    return c >= 3;
  }

  static bool _checkDoubleKill(List<ToiletRecord> records) {
    Set<String> days = {};
    for (final r in records) {
      final dt = DateTime.fromMillisecondsSinceEpoch(r.timestamp);
      final key = '${dt.year}-${dt.month}-${dt.day}';
      days.add(key);
    }
    for (final dayKey in days) {
      final dayRecords = records.where((r) {
        final dt = DateTime.fromMillisecondsSinceEpoch(r.timestamp);
        return '${dt.year}-${dt.month}-${dt.day}' == dayKey;
      }).toList();
      final hasBig = dayRecords.any((r) => r.type == RecordType.big);
      final hasSmall = dayRecords.any((r) => r.type == RecordType.small);
      if (hasBig && hasSmall) return true;
    }
    return false;
  }

  static Future<int> _getCurrentSeasonScore() async {
    final scoreStr = await DatabaseService.getSetting('season_score');
    return int.tryParse(scoreStr ?? '0') ?? 0;
  }
}
