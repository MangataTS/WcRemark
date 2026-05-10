import 'dart:math';
import '../models/toilet_record.dart';

class RegularityCalculator {
  static int calculate(List<ToiletRecord> records) {
    Map<int, int> firstBigPerDay = {};

    for (var record in records) {
      if (record.type == RecordType.big) {
        DateTime dt = DateTime.fromMillisecondsSinceEpoch(record.timestamp);
        int dayKey = dt.year * 10000 + dt.month * 100 + dt.day;
        int minutes = dt.hour * 60 + dt.minute;

        if (!firstBigPerDay.containsKey(dayKey) || minutes < firstBigPerDay[dayKey]!) {
          firstBigPerDay[dayKey] = minutes;
        }
      }
    }

    List<int> times = firstBigPerDay.values.toList();

    if (times.length < 3) return 50;
    if (times.length < 5) return 60;

    times = _unwrapCircularTimes(times);

    double mean = times.reduce((a, b) => a + b) / times.length;
    double variance =
        times.map((t) => pow(t - mean, 2)).reduce((a, b) => a + b) / times.length;
    double std = sqrt(variance);

    if (std <= 30) return 100;
    if (std >= 120) return 0;

    double score = 100 - ((std - 30) / 90) * 100;
    return score.round().clamp(0, 100);
  }

  static List<int> _unwrapCircularTimes(List<int> times) {
    if (times.isEmpty) return times;

    int bestOffset = 0;
    double minVariance = double.infinity;

    for (int offset = 0; offset < 1440; offset += 30) {
      List<int> shifted = times.map((t) => (t - offset + 1440) % 1440).toList();
      shifted = shifted.map((t) => t > 720 ? t - 1440 : t).toList();

      double mean = shifted.reduce((a, b) => a + b) / shifted.length;
      double variance =
          shifted.map((t) => pow(t - mean, 2)).reduce((a, b) => a + b) / shifted.length;

      if (variance < minVariance) {
        minVariance = variance;
        bestOffset = offset;
      }
    }

    List<int> result = times.map((t) => (t - bestOffset + 1440) % 1440).toList();
    return result.map((t) => t > 720 ? t - 1440 : t).toList();
  }
}

class HealthGradeCalculator {
  static HealthGrade calculateMonthly(List<ToiletRecord> records) {
    int daysWithBig = _countDaysWithType(records, RecordType.big);
    int totalDays = _daysInMonth(records);
    double frequencyScore = totalDays > 0 ? (daysWithBig / totalDays) * 30 : 0;

    double regularityScore = RegularityCalculator.calculate(records) * 0.25;

    List<ToiletRecord> bigRecords =
        records.where((r) => r.type == RecordType.big).toList();
    int healthyBristol = bigRecords
        .where((r) => r.bristolType == 3 || r.bristolType == 4)
        .length;
    double bristolScore =
        bigRecords.isEmpty ? 0 : (healthyBristol / bigRecords.length) * 25;

    int goodDuration = bigRecords.where((r) {
      int min = (r.duration ?? 0) ~/ 60;
      return min >= 3 && min <= 8;
    }).length;
    double durationScore =
        bigRecords.isEmpty ? 0 : (goodDuration / bigRecords.length) * 20;

    double total = frequencyScore + regularityScore + bristolScore + durationScore;

    String grade;
    String title;
    if (total >= 90) {
      grade = 'A';
      title = '肠道模范生';
    } else if (total >= 75) {
      grade = 'B';
      title = '运转良好';
    } else if (total >= 60) {
      grade = 'C';
      title = '偶有波动';
    } else {
      grade = 'D';
      title = '需要关注';
    }

    return HealthGrade(
      grade: grade,
      title: title,
      score: total.round(),
      breakdown: {
        'frequency': frequencyScore.round(),
        'regularity': regularityScore.round(),
        'bristol': bristolScore.round(),
        'duration': durationScore.round(),
      },
    );
  }

  static int _countDaysWithType(List<ToiletRecord> records, RecordType type) {
    Set<String> days = {};
    for (var r in records) {
      if (r.type == type) {
        DateTime dt = DateTime.fromMillisecondsSinceEpoch(r.timestamp);
        days.add('${dt.year}-${dt.month}-${dt.day}');
      }
    }
    return days.length;
  }

  static int _daysInMonth(List<ToiletRecord> records) {
    if (records.isEmpty) return 30;
    DateTime first = DateTime.fromMillisecondsSinceEpoch(records.first.timestamp);
    DateTime last = DateTime.fromMillisecondsSinceEpoch(records.last.timestamp);
    return last.difference(first).inDays + 1;
  }
}

class HealthGrade {
  final String grade;
  final String title;
  final int score;
  final Map<String, int> breakdown;

  const HealthGrade({
    required this.grade,
    required this.title,
    required this.score,
    required this.breakdown,
  });
}

class YearlyKeywordGenerator {
  static List<String> generate(List<ToiletRecord> records) {
    List<String> keywords = [];

    int morningCount = records.where((r) {
      if (r.type != RecordType.big) return false;
      DateTime dt = DateTime.fromMillisecondsSinceEpoch(r.timestamp);
      return dt.hour >= 6 && dt.hour <= 9;
    }).length;
    if (morningCount > records.length * 0.6) keywords.add('晨便守护者');

    int paidCount = records.where((r) => r.isPaidPoop).length;
    if (paidCount > 50) keywords.add('带薪拉屎王');

    int fastCount = records.where((r) {
      return r.type == RecordType.big && (r.duration ?? 0) < 180;
    }).length;
    if (fastCount > records.length * 0.5) keywords.add('闪电侠');

    if (keywords.isEmpty) keywords.add('肠道探索者');
    return keywords;
  }
}