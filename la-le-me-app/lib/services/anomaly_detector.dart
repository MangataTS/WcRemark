import '../models/toilet_record.dart';
import 'database_service.dart';
import 'notification_service.dart';
import 'sound_service.dart';
import 'settings_service.dart';

class AnomalyDetector {
  static const int _constipationDays = 5;
  static const int _diarrheaMinDays = 3;
  static const int _diarrheaMinDailyCount = 3;
  static const List<int> _diarrheaBristolTypes = [5, 6, 7];
  static const List<int> _alertColors = [1, 2];

  static Future<void> checkAndAlert() async {
    try {
      final allRecords = await DatabaseService.getRecords();
      final recentRecords = await DatabaseService.getRecentRecords(days: 7);

      final hasConstipation = await _checkConstipation(allRecords);
      final hasDiarrhea = await _checkDiarrhea(recentRecords);
      final hasBlood = await _checkBloodInStool(allRecords);

      if (hasConstipation || hasDiarrhea || hasBlood) {
        final settings = await AppSettings.load();
        await SoundService.playWaterDrop(settings);
      }
    } catch (_) {}
  }

  static Future<bool> checkConstipation(List<ToiletRecord> records) async {
    final bigRecords = records.where((r) => r.type == RecordType.big).toList();
    if (bigRecords.isEmpty) return false;

    final lastBig =
        bigRecords.reduce((a, b) => a.timestamp > b.timestamp ? a : b);
    final daysSince = DateTime.now()
        .difference(
          DateTime.fromMillisecondsSinceEpoch(lastBig.timestamp),
        )
        .inDays;

    if (daysSince >= _constipationDays) {
      await NotificationService.show(
        title: NotificationType.getLocalizedTitle(
            NotificationType.constipationAlert),
        body: '已经 $daysSince 天没有大号了，建议多吃膳食纤维，必要时就医。',
        payload: NotificationType.constipationAlert,
      );
      return true;
    }
    return false;
  }

  static Future<bool> _checkConstipation(List<ToiletRecord> records) async {
    return checkConstipation(records);
  }

  static bool hasPersistentDiarrhea(List<ToiletRecord> recentRecords) {
    final now = DateTime.now();
    int consecutiveDays = 0;

    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: i));
      final dayRecords = recentRecords.where((r) {
        final dt = DateTime.fromMillisecondsSinceEpoch(r.timestamp);
        return dt.year == day.year &&
            dt.month == day.month &&
            dt.day == day.day;
      }).toList();

      final bigRecords =
          dayRecords.where((r) => r.type == RecordType.big).toList();
      final diarrheaCount = bigRecords
          .where((r) =>
              r.bristolType != null &&
              _diarrheaBristolTypes.contains(r.bristolType))
          .length;

      if (diarrheaCount >= _diarrheaMinDailyCount) {
        consecutiveDays++;
      } else {
        consecutiveDays = 0;
      }

      if (consecutiveDays >= _diarrheaMinDays) return true;
    }
    return false;
  }

  static Future<bool> _checkDiarrhea(List<ToiletRecord> recentRecords) async {
    if (hasPersistentDiarrhea(recentRecords)) {
      await NotificationService.show(
        title:
            NotificationType.getLocalizedTitle(NotificationType.diarrheaAlert),
        body: NotificationType.getLocalizedBody(NotificationType.diarrheaAlert),
        payload: NotificationType.diarrheaAlert,
      );
      return true;
    }
    return false;
  }

  static bool hasBloodInStool(List<ToiletRecord> records) {
    final recent = records.where((r) {
      final dt = DateTime.fromMillisecondsSinceEpoch(r.timestamp);
      return DateTime.now().difference(dt).inDays <= 7;
    }).toList();

    return recent.any((r) =>
        r.type == RecordType.big &&
        r.color != null &&
        _alertColors.contains(r.color));
  }

  static Future<bool> _checkBloodInStool(List<ToiletRecord> records) async {
    if (hasBloodInStool(records)) {
      await NotificationService.show(
        title: NotificationType.getLocalizedTitle(NotificationType.bloodAlert),
        body: NotificationType.getLocalizedBody(NotificationType.bloodAlert),
        payload: NotificationType.bloodAlert,
      );
      return true;
    }
    return false;
  }

  static Future<AnomalyReport> generateReport() async {
    final allRecords = await DatabaseService.getRecords();
    final recentRecords = await DatabaseService.getRecentRecords(days: 7);

    final anomalies = <String>[];
    final warnings = <String>[];
    final recommendations = <String>[];

    final bigRecords =
        allRecords.where((r) => r.type == RecordType.big).toList();
    if (bigRecords.isNotEmpty) {
      final lastBig =
          bigRecords.reduce((a, b) => a.timestamp > b.timestamp ? a : b);
      final daysSince = DateTime.now()
          .difference(
            DateTime.fromMillisecondsSinceEpoch(lastBig.timestamp),
          )
          .inDays;

      if (daysSince >= _constipationDays) {
        anomalies.add('已 $daysSince 天无大号');
        recommendations.add('增加膳食纤维和饮水量');
      } else if (daysSince >= 3) {
        warnings.add('已 $daysSince 天无大号');
      }
    }

    if (hasPersistentDiarrhea(recentRecords)) {
      anomalies.add('持续腹泻');
      recommendations.add('注意补水，必要时就医');
    }

    if (hasBloodInStool(allRecords)) {
      anomalies.add('疑似血便/黑便');
      recommendations.add('请尽快就医检查');
    }

    final avgBristol = _calculateAvgBristol(recentRecords);
    if (avgBristol != null) {
      if (avgBristol < 2) {
        warnings.add('布里斯托均值偏低（${avgBristol.toStringAsFixed(1)}）');
        recommendations.add('增加水分和纤维摄入');
      } else if (avgBristol > 6) {
        warnings.add('布里斯托均值偏高（${avgBristol.toStringAsFixed(1)}）');
        recommendations.add('减少刺激性食物');
      }
    }

    return AnomalyReport(
      anomalies: anomalies,
      warnings: warnings,
      recommendations: recommendations,
      hasCriticalAnomaly: anomalies.isNotEmpty,
    );
  }

  static double? _calculateAvgBristol(List<ToiletRecord> records) {
    final withBristol = records
        .where((r) => r.type == RecordType.big && r.bristolType != null)
        .toList();
    if (withBristol.isEmpty) return null;
    return withBristol
            .map((r) => r.bristolType!.toDouble())
            .reduce((a, b) => a + b) /
        withBristol.length;
  }
}

class AnomalyReport {
  final List<String> anomalies;
  final List<String> warnings;
  final List<String> recommendations;
  final bool hasCriticalAnomaly;

  const AnomalyReport({
    required this.anomalies,
    required this.warnings,
    required this.recommendations,
    required this.hasCriticalAnomaly,
  });

  bool get isEmpty => anomalies.isEmpty && warnings.isEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
}
