import 'dart:math';
import '../models/toilet_record.dart';

class ScoreCalculator {
  static double calculate(ToiletRecord record, List<ToiletRecord> history) {
    double base = record.type == RecordType.big ? 5.0 : 1.0;

    double r = _calculateRegularity(record, history);
    double h = _calculateHealth(record);
    double t = _calculateTime(record);
    double p = _calculatePaid(record);
    double s = _calculateStreak(record, history);
    double m = _calculateMorning(record);

    double finalScore = base * r * h * t * p * s * m;
    return min(finalScore, 25.0);
  }

  static double _calculateRegularity(ToiletRecord record, List<ToiletRecord> history) {
    if (record.type != RecordType.big) return 1.0;

    DateTime now = DateTime.fromMillisecondsSinceEpoch(record.timestamp);
    DateTime thirtyDaysAgo = now.subtract(const Duration(days: 30));

    var recentHistory = history.where((r) {
      DateTime dt = DateTime.fromMillisecondsSinceEpoch(r.timestamp);
      return r.type == RecordType.big && dt.isAfter(thirtyDaysAgo);
    }).toList();

    Map<int, int> firstPerDay = {};
    for (var r in recentHistory) {
      DateTime dt = DateTime.fromMillisecondsSinceEpoch(r.timestamp);
      int dayKey = dt.year * 10000 + dt.month * 100 + dt.day;
      int minutes = dt.hour * 60 + dt.minute;
      if (!firstPerDay.containsKey(dayKey) || minutes < firstPerDay[dayKey]!) {
        firstPerDay[dayKey] = minutes;
      }
    }

    List<int> times = firstPerDay.values.toList();
    if (times.length < 3) return 1.0;

    double mean = times.reduce((a, b) => a + b) / times.length;
    double variance =
        times.map((t) => pow(t - mean, 2)).reduce((a, b) => a + b) / times.length;
    double std = sqrt(variance);

    if (std <= 20) return 1.5;
    if (std >= 180) return 0.8;
    return 1.5 - ((std - 20) / 160) * 0.7;
  }

  static double _calculateHealth(ToiletRecord record) {
    if (record.type != RecordType.big) return 1.0;

    switch (record.bristolType) {
      case 3:
      case 4:
        return 1.2;
      case 2:
      case 5:
        return 1.0;
      case 1:
        return 0.9;
      case 6:
        return 0.85;
      case 7:
        return 0.8;
      default:
        return 1.0;
    }
  }

  static double _calculateTime(ToiletRecord record) {
    int minutes = (record.duration ?? 0) ~/ 60;

    if (record.type == RecordType.small) {
      return minutes <= 2 ? 1.1 : 1.0;
    }

    if (minutes >= 3 && minutes <= 8) return 1.1;
    if (minutes >= 1 && minutes < 3) return 1.0;
    if (minutes > 8 && minutes <= 15) return 1.0;
    if (minutes > 15 && minutes <= 20) return 0.8;
    if (minutes > 20) return 0.7;
    if (minutes < 1) return 0.8;
    return 1.0;
  }

  static double _calculatePaid(ToiletRecord record) {
    if (!record.isPaidPoop) return 1.0;
    return 1.2;
  }

  static double _calculateStreak(ToiletRecord record, List<ToiletRecord> history) {
    int streak = 0;
    DateTime checkDay = DateTime.fromMillisecondsSinceEpoch(record.timestamp);

    for (int i = 1; i <= 30; i++) {
      DateTime targetDay = checkDay.subtract(Duration(days: i));
      bool hasBig = history.any((r) {
        DateTime dt = DateTime.fromMillisecondsSinceEpoch(r.timestamp);
        return r.type == RecordType.big &&
            dt.year == targetDay.year &&
            dt.month == targetDay.month &&
            dt.day == targetDay.day;
      });
      if (hasBig) {
        streak++;
      } else {
        break;
      }
    }

    if (streak < 2) return 1.0;
    return min(1.0 + (streak - 2) * 0.1, 2.0);
  }

  static double _calculateMorning(ToiletRecord record) {
    if (record.type != RecordType.big) return 1.0;
    DateTime dt = DateTime.fromMillisecondsSinceEpoch(record.timestamp);
    if (dt.hour >= 6 && dt.hour <= 9) return 1.15;
    return 1.0;
  }
}

class PaidPoopCalculator {
  static Map<String, dynamic> calculate(
    List<ToiletRecord> records, {
    double monthlySalary = 10000,
  }) {
    double hourlyRate = monthlySalary / 22 / 8;

    int totalSeconds = records
        .where((r) => r.isPaidPoop)
        .fold(0, (sum, r) => sum + (r.duration ?? 0));

    double totalHours = totalSeconds / 3600;
    double earnings = totalHours * hourlyRate;

    return {
      'total_hours': totalHours.toStringAsFixed(1),
      'earnings': earnings.toStringAsFixed(2),
      'hourly_rate': hourlyRate.toStringAsFixed(2),
      'record_count': records.where((r) => r.isPaidPoop).length,
    };
  }
}