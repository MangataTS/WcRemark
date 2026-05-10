# 反作弊系统

## 功能描述

反作弊系统确保积分体系的公平性，包含：
- 客户端预检：频率检测、时间合理性、时间间隔检测
- 服务端复检：积分增长速率、乘数合理性、Z-Score行为分析、地理位置跳跃
- 作弊标记与封禁：可疑→扣分、作弊→封赛季、无效→拒绝

## 当前实现状态

### 已完成
- [x] 服务端反作弊完整实现（`anti_cheat_service.go`）
  - 频率检测、时间合理性、间隔检测
  - 积分增长速率、乘数合理性校验、Z-Score分析
- [x] 客户端积分计算引擎（`score_calculator.dart`）
  - 六维乘数完整实现，含边界值约束
- [x] `ScoreSettlementResult` 数据模型含 `cheatFlag` 字段

### 未完成
- [ ] 客户端 `AntiCheatSystem.clientPreCheck()` 未实现（文档有设计，代码未写）
- [ ] 作弊检测结果未在UI中展示（积分被扣/封赛季的提示）
- [ ] 作弊处罚后的用户交互流程
- [ ] 频率限制滑动窗口未在客户端实现

## 实现步骤

### 1. 客户端预检实现（P2）

```dart
// lib/services/anti_cheat_service.dart
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
}

class AntiCheatService {
  static CheatCheckResult clientPreCheck(
    ToiletRecord record,
    List<ToiletRecord> history,
  ) {
    // 1. 频率检测
    final today = history.where((r) => _isToday(r.timestamp)).length;
    if (today > 15) {
      return CheatCheckResult(
        flag: CheatFlag.cheat,
        action: CheatAction.banSeason,
        reason: '今日记录次数严重异常（${today}次），疑似刷分',
      );
    }
    if (today > 10) {
      return CheatCheckResult(
        flag: CheatFlag.suspicious,
        action: CheatAction.holdPoints,
        reason: '今日记录次数异常（${today}次）',
      );
    }

    // 2. 时间合理性
    final duration = record.duration ?? 0;
    if (record.type == RecordType.big && duration < 30) {
      return CheatCheckResult(
        flag: CheatFlag.suspicious,
        action: CheatAction.scorePenalty,
        penalty: 0.5,
        reason: '大号时长仅${duration}秒，异常',
      );
    }
    if (duration > 3600) {
      return CheatCheckResult(
        flag: CheatFlag.invalid,
        action: CheatAction.reject,
        reason: '单次时长超过1小时，不符合常理',
      );
    }

    // 3. 时间间隔检测（5分钟内连续3次）
    final recentRecords = history.where((r) =>
      (record.timestamp - r.timestamp).abs() < 5 * 60 * 1000
    ).toList();
    if (recentRecords.length >= 3) {
      return CheatCheckResult(
        flag: CheatFlag.suspicious,
        action: CheatAction.holdPoints,
        reason: '5分钟内连续记录${recentRecords.length}次',
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
```

### 2. 积分上报流程集成（P2）

```dart
// lib/services/score_service.dart
class ScoreService {
  static Future<ScoreSettlementResult?> submitScore(
    ToiletRecord record,
    List<ToiletRecord> history,
  ) async {
    // 1. 客户端预检
    final preCheck = AntiCheatService.clientPreCheck(record, history);
    if (preCheck.action == CheatAction.reject) {
      _showCheatWarning(preCheck.reason!);
      return null;
    }

    // 2. 计算积分
    final score = ScoreCalculator.calculate(record, history);
    final multipliers = ScoreCalculator.getMultipliers(record, history);

    // 3. 构建请求
    final request = ScoreSettlementRequest(
      recordUuid: record.id,
      type: record.type == RecordType.big ? 'big' : 'small',
      timestamp: record.timestamp,
      duration: record.duration ?? 0,
      isWorkHours: record.isWorkHours,
      isPaidPoop: record.isPaidPoop,
      bristolType: record.bristolType,
      baseScore: record.type == RecordType.big ? 5.0 : 1.0,
      multipliers: multipliers,
      finalScore: score,
      locationHash: record.locationHash,
    );

    // 4. 异步上报
    try {
      final result = await ApiService.instance.syncScore(request);

      // 5. 处理服务端复检结果
      if (result.cheatFlag != 'OK') {
        _handleCheatResult(result);
      }

      return result;
    } catch (e) {
      // 网络失败 → 加入离线队列
      await OfflineQueue.enqueue(request.toJson());
      return null;
    }
  }
}
```

### 3. 作弊UI提示（P2）

```dart
void _showCheatWarning(String reason) {
  showDialog(
    context: navigatorKey.currentContext!,
    builder: (ctx) => AlertDialog(
      title: const Text('⚠️ 记录异常'),
      content: Text(reason),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('我知道了'),
        ),
      ],
    ),
  );
}

void _handleCheatResult(ScoreSettlementResult result) {
  if (result.cheatFlag == 'SUSPICIOUS') {
    // 积分被暂时冻结
    showToast('积分正在审核中');
  } else if (result.cheatFlag == 'CHEAT') {
    // 赛季封禁
    showDialog(/* 赛季封禁提示 */);
  }
}
```

## 接口定义

### CheatCheckResult

```dart
class CheatCheckResult {
  CheatFlag flag;      // ok / suspicious / cheat / invalid
  CheatAction action;  // accept / holdPoints / scorePenalty / banSeason / reject
  String? reason;      // 人类可读原因
  double? penalty;      // 积分惩罚系数（如 0.5 = 扣半）
}
```

### 服务端复检接口（已定义于后端）

```
POST /api/v1/records/sync
→ 服务端执行:
  1. 频率检测 (10次/天警告, 15次/天封禁)
  2. 乘数合理性 (总乘数 > 5.445*1.1 → 异常)
  3. Z-Score分析 (偏离>3σ → 可疑)
  4. 地理跳跃检测
  → 返回 cheatFlag: OK/SUSPICIOUS/CHEAT/INVALID
```

## 相关依赖

| 依赖模块 | 说明 |
|---------|------|
| [01-home-record.md](01-home-record.md) | 记录保存后触发预检 |
| [04-ranking-score.md](04-ranking-score.md) | 积分计算 |
| [07-backend-integration.md](07-backend-integration.md) | 积分上报/离线队列 |
| 后端 `anti_cheat_service.go` | 服务端二次校验 |