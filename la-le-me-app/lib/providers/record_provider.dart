import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/toilet_record.dart';
import '../services/database_service.dart';
import '../services/score_calculator.dart';
import '../services/regularity_calculator.dart';
import '../services/season_service.dart';

final refreshTriggerProvider = StateProvider<int>((ref) => 0);

final todayRecordsProvider = FutureProvider<List<ToiletRecord>>((ref) async {
  ref.watch(refreshTriggerProvider);
  return await DatabaseService.getTodayRecords();
});

final weekRecordsProvider = FutureProvider<List<ToiletRecord>>((ref) async {
  ref.watch(refreshTriggerProvider);
  return await DatabaseService.getRecentRecords(days: 7);
});

final monthRecordsProvider = FutureProvider<List<ToiletRecord>>((ref) async {
  ref.watch(refreshTriggerProvider);
  return await DatabaseService.getRecentRecords(days: 30);
});

final yearRecordsProvider = FutureProvider<List<ToiletRecord>>((ref) async {
  ref.watch(refreshTriggerProvider);
  return await DatabaseService.getRecentRecords(days: 365);
});

class FiveDayStats {
  final List<String> dates;
  final List<int> bigCounts;
  final List<int> smallCounts;
  final List<int> totalCounts;

  FiveDayStats({
    required this.dates,
    required this.bigCounts,
    required this.smallCounts,
    required this.totalCounts,
  });
}

final fiveDayStatsProvider = FutureProvider<FiveDayStats>((ref) async {
  ref.watch(refreshTriggerProvider);
  final records = await DatabaseService.getRecentRecords(days: 5);
  final now = DateTime.now();

  List<String> dates = [];
  List<int> bigCounts = [];
  List<int> smallCounts = [];
  List<int> totalCounts = [];

  for (int i = 4; i >= 0; i--) {
    final day = now.subtract(Duration(days: i));
    final dayKey =
        '${day.year}${day.month.toString().padLeft(2, '0')}${day.day.toString().padLeft(2, '0')}';
    final monthDay = '${day.month}/${day.day}';

    final dayRecords = records.where((r) {
      final dt = DateTime.fromMillisecondsSinceEpoch(r.timestamp);
      final rKey =
          '${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}';
      return rKey == dayKey;
    }).toList();

    dates.add(monthDay);
    bigCounts.add(dayRecords.where((r) => r.type == RecordType.big).length);
    smallCounts.add(dayRecords.where((r) => r.type == RecordType.small).length);
    totalCounts.add(dayRecords.length);
  }

  return FiveDayStats(
    dates: dates,
    bigCounts: bigCounts,
    smallCounts: smallCounts,
    totalCounts: totalCounts,
  );
});

final todayBigCountProvider = FutureProvider<int>((ref) async {
  ref.watch(refreshTriggerProvider);
  return await DatabaseService.getTodayBigCount();
});

final todaySmallCountProvider = FutureProvider<int>((ref) async {
  ref.watch(refreshTriggerProvider);
  return await DatabaseService.getTodaySmallCount();
});

final seasonScoreProvider = FutureProvider<SeasonInfo>((ref) async {
  ref.watch(refreshTriggerProvider);
  return await SeasonService.getSeasonInfo();
});

final totalRecordCountProvider = FutureProvider<int>((ref) async {
  ref.watch(refreshTriggerProvider);
  return await DatabaseService.getTotalRecordCount();
});

class WeeklyStatsData {
  final int totalBig;
  final int totalSmall;
  final List<int> dailyBigCounts;
  final Map<int, int> bristolDist;
  final int regularityScore;
  final String healthGrade;
  final String healthTitle;
  final double avgBigDuration;
  final double paidHours;
  final Map<String, int> periodDist;

  WeeklyStatsData({
    required this.totalBig,
    required this.totalSmall,
    required this.dailyBigCounts,
    required this.bristolDist,
    required this.regularityScore,
    required this.healthGrade,
    required this.healthTitle,
    required this.avgBigDuration,
    required this.paidHours,
    required this.periodDist,
  });

  int get totalCount => totalBig + totalSmall;
  double get bigRatio =>
      totalBig + totalSmall > 0 ? totalBig / (totalBig + totalSmall) : 0;
}

final weeklyStatsProvider = FutureProvider<WeeklyStatsData>((ref) async {
  ref.watch(refreshTriggerProvider);
  final records = await DatabaseService.getRecentRecords(days: 7);
  return _calculateWeeklyStats(records);
});

WeeklyStatsData _calculateWeeklyStats(List<ToiletRecord> records) {
  final bigRecords = records.where((r) => r.type == RecordType.big).toList();
  final now = DateTime.now();

  List<int> dailyBigCounts = List.filled(7, 0);
  for (int i = 0; i < 7; i++) {
    final day = now.subtract(Duration(days: 6 - i));
    final dayKey =
        '${day.year}${day.month.toString().padLeft(2, '0')}${day.day.toString().padLeft(2, '0')}';
    dailyBigCounts[i] = bigRecords.where((r) {
      final dt = DateTime.fromMillisecondsSinceEpoch(r.timestamp);
      final rKey =
          '${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}';
      return rKey == dayKey;
    }).length;
  }

  Map<int, int> bristolDist = {};
  for (final r in bigRecords) {
    final bt = r.bristolType ?? 0;
    if (bt > 0) bristolDist[bt] = (bristolDist[bt] ?? 0) + 1;
  }

  final regularityScore = RegularityCalculator.calculate(records);
  final healthGrade = HealthGradeCalculator.calculateMonthly(records);

  double avgDuration = 0;
  if (bigRecords.isNotEmpty) {
    final durations = bigRecords
        .where((r) => r.duration != null)
        .map((r) => r.duration! / 60.0)
        .toList();
    if (durations.isNotEmpty) {
      avgDuration = durations.reduce((a, b) => a + b) / durations.length;
    }
  }

  double paidHours = 0;
  final paidRecords = records.where((r) => r.isPaidPoop).toList();
  if (paidRecords.isNotEmpty) {
    final paidResult = PaidPoopCalculator.calculate(paidRecords);
    paidHours = double.tryParse(paidResult['total_hours'] as String) ?? 0;
  }

  Map<String, int> periodDist = {'早晨': 0, '上午': 0, '下午': 0, '晚间': 0, '夜间': 0};
  for (final r in bigRecords) {
    final hour = DateTime.fromMillisecondsSinceEpoch(r.timestamp).hour;
    if (hour >= 6 && hour < 9) {
      periodDist['早晨'] = periodDist['早晨']! + 1;
    } else if (hour >= 9 && hour < 12) {
      periodDist['上午'] = periodDist['上午']! + 1;
    } else if (hour >= 12 && hour < 18) {
      periodDist['下午'] = periodDist['下午']! + 1;
    } else if (hour >= 18 && hour < 21) {
      periodDist['晚间'] = periodDist['晚间']! + 1;
    } else {
      periodDist['夜间'] = periodDist['夜间']! + 1;
    }
  }

  return WeeklyStatsData(
    totalBig: bigRecords.length,
    totalSmall: records.where((r) => r.type == RecordType.small).length,
    dailyBigCounts: dailyBigCounts,
    bristolDist: bristolDist,
    regularityScore: regularityScore,
    healthGrade: healthGrade.grade,
    healthTitle: healthGrade.title,
    avgBigDuration: avgDuration,
    paidHours: paidHours,
    periodDist: periodDist,
  );
}

class MonthlyStatsData {
  final int totalBig;
  final int totalSmall;
  final Map<int, int> dailyBigCounts;
  final String healthGrade;
  final String healthTitle;
  final double avgBigDuration;
  final double paidHours;
  final Map<String, int> periodDist;
  final Map<int, int> bristolDist;
  final Map<String, int> healthBreakdown;

  MonthlyStatsData({
    required this.totalBig,
    required this.totalSmall,
    required this.dailyBigCounts,
    required this.healthGrade,
    required this.healthTitle,
    required this.avgBigDuration,
    required this.paidHours,
    required this.periodDist,
    required this.bristolDist,
    required this.healthBreakdown,
  });

  int get totalCount => totalBig + totalSmall;
}

final monthlyStatsProvider = FutureProvider<MonthlyStatsData>((ref) async {
  ref.watch(refreshTriggerProvider);
  final records = await DatabaseService.getRecentRecords(days: 30);
  return _calculateMonthlyStats(records);
});

MonthlyStatsData _calculateMonthlyStats(List<ToiletRecord> records) {
  final bigRecords = records.where((r) => r.type == RecordType.big).toList();
  final now = DateTime.now();
  final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

  Map<int, int> dailyBigCounts = {};
  for (int d = 1; d <= daysInMonth; d++) {
    dailyBigCounts[d] = 0;
  }

  for (final r in bigRecords) {
    final dt = DateTime.fromMillisecondsSinceEpoch(r.timestamp);
    dailyBigCounts[dt.day] = (dailyBigCounts[dt.day] ?? 0) + 1;
  }

  Map<int, int> bristolDist = {};
  for (final r in bigRecords) {
    final bt = r.bristolType ?? 0;
    if (bt > 0) bristolDist[bt] = (bristolDist[bt] ?? 0) + 1;
  }

  final healthGrade = HealthGradeCalculator.calculateMonthly(records);

  double avgDuration = 0;
  if (bigRecords.isNotEmpty) {
    final durations = bigRecords
        .where((r) => r.duration != null)
        .map((r) => r.duration! / 60.0)
        .toList();
    if (durations.isNotEmpty) {
      avgDuration = durations.reduce((a, b) => a + b) / durations.length;
    }
  }

  double paidHours = 0;
  final paidRecords = records.where((r) => r.isPaidPoop).toList();
  if (paidRecords.isNotEmpty) {
    final paidResult = PaidPoopCalculator.calculate(paidRecords);
    paidHours = double.tryParse(paidResult['total_hours'] as String) ?? 0;
  }

  Map<String, int> periodDist = {'早晨': 0, '上午': 0, '下午': 0, '晚间': 0, '夜间': 0};
  for (final r in bigRecords) {
    final hour = DateTime.fromMillisecondsSinceEpoch(r.timestamp).hour;
    if (hour >= 6 && hour < 9) {
      periodDist['早晨'] = periodDist['早晨']! + 1;
    } else if (hour >= 9 && hour < 12) {
      periodDist['上午'] = periodDist['上午']! + 1;
    } else if (hour >= 12 && hour < 18) {
      periodDist['下午'] = periodDist['下午']! + 1;
    } else if (hour >= 18 && hour < 21) {
      periodDist['晚间'] = periodDist['晚间']! + 1;
    } else {
      periodDist['夜间'] = periodDist['夜间']! + 1;
    }
  }

  return MonthlyStatsData(
    totalBig: bigRecords.length,
    totalSmall: records.where((r) => r.type == RecordType.small).length,
    dailyBigCounts: dailyBigCounts,
    healthGrade: healthGrade.grade,
    healthTitle: healthGrade.title,
    avgBigDuration: avgDuration,
    paidHours: paidHours,
    periodDist: periodDist,
    bristolDist: bristolDist,
    healthBreakdown: healthGrade.breakdown.map((k, v) => MapEntry(k, v)),
  );
}

class YearlyStatsData {
  final int totalBig;
  final int totalSmall;
  final Map<int, int> monthlyBigCounts;
  final List<String> keywords;
  final double avgBigDuration;
  final double paidEarnings;

  YearlyStatsData({
    required this.totalBig,
    required this.totalSmall,
    required this.monthlyBigCounts,
    required this.keywords,
    required this.avgBigDuration,
    required this.paidEarnings,
  });

  int get totalCount => totalBig + totalSmall;
}

final yearlyStatsProvider = FutureProvider<YearlyStatsData>((ref) async {
  ref.watch(refreshTriggerProvider);
  final records = await DatabaseService.getRecentRecords(days: 365);
  return _calculateYearlyStats(records);
});

YearlyStatsData _calculateYearlyStats(List<ToiletRecord> records) {
  final bigRecords = records.where((r) => r.type == RecordType.big).toList();
  final now = DateTime.now();

  Map<int, int> monthlyBigCounts = {};
  for (int m = 1; m <= 12; m++) {
    monthlyBigCounts[m] = 0;
  }

  for (final r in bigRecords) {
    final dt = DateTime.fromMillisecondsSinceEpoch(r.timestamp);
    if (dt.year == now.year) {
      monthlyBigCounts[dt.month] = (monthlyBigCounts[dt.month] ?? 0) + 1;
    }
  }

  final keywords = YearlyKeywordGenerator.generate(records);

  double avgDuration = 0;
  if (bigRecords.isNotEmpty) {
    final durations = bigRecords
        .where((r) => r.duration != null)
        .map((r) => r.duration! / 60.0)
        .toList();
    if (durations.isNotEmpty) {
      avgDuration = durations.reduce((a, b) => a + b) / durations.length;
    }
  }

  double paidEarnings = 0;
  final paidRecords = records.where((r) => r.isPaidPoop).toList();
  if (paidRecords.isNotEmpty) {
    final paidResult = PaidPoopCalculator.calculate(paidRecords);
    paidEarnings = double.tryParse(paidResult['earnings'] as String) ?? 0;
  }

  return YearlyStatsData(
    totalBig: bigRecords.length,
    totalSmall: records.where((r) => r.type == RecordType.small).length,
    monthlyBigCounts: monthlyBigCounts,
    keywords: keywords,
    avgBigDuration: avgDuration,
    paidEarnings: paidEarnings,
  );
}
