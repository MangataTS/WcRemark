import '../models/toilet_record.dart';

enum CheatFlag { ok, suspicious, cheat, invalid }

enum CheatAction { accept, holdPoints, scorePenalty, banSeason, reject }

class CheatCheckResult {
  final CheatFlag flag;
  final CheatAction action;
  final String? reason;
  final double? penalty;

  const CheatCheckResult({
    required this.flag,
    this.action = CheatAction.accept,
    this.reason,
    this.penalty,
  });

  bool get isOk => flag == CheatFlag.ok;
  bool get shouldReject => action == CheatAction.reject;
}

class AntiCheatService {
  static const int _maxDailyRecords = 15;
  static const int _suspiciousDailyCount = 10;
  static const int _minBigDurationSeconds = 30;
  static const int _maxDurationSeconds = 3600;
  static const int _rapidWindowMinutes = 5;
  static const int _rapidThreshold = 3;

  static CheatCheckResult clientPreCheck(
    ToiletRecord record,
    List<ToiletRecord> history,
  ) {
    final todayRecords = history.where((r) => _isToday(r.timestamp)).toList();
    final todayCount = todayRecords.length;

    if (todayCount > _maxDailyRecords) {
      return CheatCheckResult(
        flag: CheatFlag.cheat,
        action: CheatAction.banSeason,
        reason: '今日记录次数严重异常（$todayCount次），疑似刷分',
      );
    }

    if (todayCount > _suspiciousDailyCount) {
      return CheatCheckResult(
        flag: CheatFlag.suspicious,
        action: CheatAction.holdPoints,
        reason: '今日记录次数异常（$todayCount次），积分暂缓结算',
      );
    }

    final duration = record.duration ?? 0;
    if (record.type == RecordType.big && duration > 0) {
      if (duration < _minBigDurationSeconds) {
        return CheatCheckResult(
          flag: CheatFlag.suspicious,
          action: CheatAction.scorePenalty,
          penalty: 0.5,
          reason: '大号时长仅$duration秒，异常偏短',
        );
      }

      if (duration > _maxDurationSeconds) {
        return CheatCheckResult(
          flag: CheatFlag.invalid,
          action: CheatAction.reject,
          reason: '单次时长超过1小时，不符合常理',
        );
      }
    }

    final recentInWindow = history.where((r) {
      final diff = (record.timestamp - r.timestamp).abs();
      return diff < _rapidWindowMinutes * 60 * 1000;
    }).toList();

    if (recentInWindow.length >= _rapidThreshold) {
      return CheatCheckResult(
        flag: CheatFlag.suspicious,
        action: CheatAction.holdPoints,
        reason: '$_rapidWindowMinutes分钟内连续记录${recentInWindow.length}次，疑似刷分',
      );
    }

    return const CheatCheckResult(flag: CheatFlag.ok);
  }

  static CheatCheckResult checkTimeReasonableness(ToiletRecord record) {
    final duration = record.duration ?? 0;

    if (record.type == RecordType.big) {
      if (duration > 0 && duration < _minBigDurationSeconds) {
        return CheatCheckResult(
          flag: CheatFlag.suspicious,
          action: CheatAction.scorePenalty,
          penalty: 0.5,
          reason: '大号时长仅$duration秒',
        );
      }
      if (duration > _maxDurationSeconds) {
        return CheatCheckResult(
          flag: CheatFlag.invalid,
          action: CheatAction.reject,
          reason: '单次大号时长超过1小时',
        );
      }
    }

    if (record.type == RecordType.small && duration > 600) {
      return CheatCheckResult(
        flag: CheatFlag.suspicious,
        action: CheatAction.scorePenalty,
        penalty: 0.3,
        reason: '小号时长超过10分钟，数据异常',
      );
    }

    return const CheatCheckResult(flag: CheatFlag.ok);
  }

  static CheatCheckResult checkFrequency(List<ToiletRecord> todayRecords) {
    final count = todayRecords.length;

    if (count > _maxDailyRecords) {
      return CheatCheckResult(
        flag: CheatFlag.cheat,
        action: CheatAction.banSeason,
        reason: '今日记录$count次，超出合理范围',
      );
    }

    if (count > _suspiciousDailyCount) {
      return CheatCheckResult(
        flag: CheatFlag.suspicious,
        action: CheatAction.holdPoints,
        reason: '今日记录$count次，偏多',
      );
    }

    return const CheatCheckResult(flag: CheatFlag.ok);
  }

  static CheatCheckResult checkInterval(
    ToiletRecord record,
    List<ToiletRecord> history,
  ) {
    final recentInWindow = history.where((r) {
      final diff = (record.timestamp - r.timestamp).abs();
      return diff < _rapidWindowMinutes * 60 * 1000;
    }).toList();

    if (recentInWindow.length >= _rapidThreshold) {
      return CheatCheckResult(
        flag: CheatFlag.suspicious,
        action: CheatAction.holdPoints,
        reason: '$_rapidWindowMinutes分钟内记录${recentInWindow.length}次',
      );
    }

    return const CheatCheckResult(flag: CheatFlag.ok);
  }

  static bool _isToday(int timestamp) {
    final now = DateTime.now();
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }
}