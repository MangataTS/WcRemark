# 成就系统

## 功能描述

成就系统通过游戏化机制增强用户粘性：
- 13个预定义成就（里程碑/规律/趣味/健康/积分五类）
- 自动解锁条件判定
- 解锁通知与展示
- 服务端成就同步

## 当前实现状态

### 已完成
- [x] `Achievement` 模型类定义完整
  - 13个成就：`morning_7`/`morning_30`/`regular_7`/`regular_30`/`first_big`/`paid_pooper`/`score_100`/`score_1000`/`bristol_gold`/`duration_master`/`all_star`/`streak_7`/`streak_30`
- [x] `Achievement.getById()` 查找方法
- [x] 分类属性（milestone/regularity/health/fun/score）

### 未完成
- [ ] 数据库缺少 `achievements` 表（未建表）
- [ ] 成就解锁逻辑未实现（每个成就的判定条件）
- [ ] 成就展示页面未创建
- [ ] 成就与服务端同步（上报/拉取）
- [ ] 成就解锁通知

## 实现步骤

### 1. 数据库添加 achievements 表（P2）

```sql
-- 添加到 DatabaseService._onCreate
CREATE TABLE achievements (
    id TEXT PRIMARY KEY,
    unlocked_at INTEGER NOT NULL,
    synced INTEGER DEFAULT 0
);

CREATE INDEX idx_achievements_synced ON achievements(synced);
```

### 2. 成就解锁判定逻辑（P2）

```dart
// lib/services/achievement_service.dart
class AchievementService {
  static Future<List<String>> checkAchievements(
    ToiletRecord newRecord,
    List<ToiletRecord> history,
    int currentScore,
  ) async {
    final unlocked = <String>[];

    // 里程碑类
    // 晨便7天
    final morning7 = history.where((r) =>
      r.type == RecordType.big &&
      _isInRange(r.timestamp, 7) &&
      DateTime.fromMillisecondsSinceEpoch(r.timestamp).hour >= 6 &&
      DateTime.fromMillisecondsSinceEpoch(r.timestamp).hour <= 9
    ).length;
    if (morning7 >= 7) unlocked.add('morning_7');

    // 晨便30天
    if (morning7 >= 30) unlocked.add('morning_30');

    // 规律7天
    final regularityScore = RegularityCalculator.calculate(history);
    if (regularityScore >= 80) unlocked.add('regular_7');
    if (regularityScore >= 80 && _regularDays(history, 30) >= 30) unlocked.add('regular_30');

    // 第一次大号
    if (history.any((r) => r.type == RecordType.big)) unlocked.add('first_big');

    // 带薪拉屎
    if (history.any((r) => r.isPaidPoop)) unlocked.add('paid_pooper');

    // 积分成就
    if (currentScore >= 100) unlocked.add('score_100');
    if (currentScore >= 1000) unlocked.add('score_1000');

    // 布里斯托黄金（bristol 3-4 占比>70%）
    final bigRecords = history.where((r) => r.type == RecordType.big).toList();
    if (bigRecords.length >= 10) {
      final goldRatio = bigRecords.where((r) =>
        r.bristolType == 3 || r.bristolType == 4).length / bigRecords.length;
      if (goldRatio > 0.7) unlocked.add('bristol_gold');
    }

    // 时长大师（平均3-8分钟且>10次）
    if (bigRecords.length >= 10) {
      final avgDuration = bigRecords
        .where((r) => r.duration != null)
        .map((r) => r.duration! / 60)
        .toList();
      if (avgDuration.isNotEmpty) {
        final mean = avgDuration.reduce((a, b) => a + b) / avgDuration.length;
        if (mean >= 3 && mean <= 8) unlocked.add('duration_master');
      }
    }

    // 连续7天/30天
    if (_streakDays(history) >= 7) unlocked.add('streak_7');
    if (_streakDays(history) >= 30) unlocked.add('streak_30');

    // 过滤已解锁的
    final alreadyUnlocked = await DatabaseService.instance.getUnlockedAchievements();
    return unlocked.where((id) => !alreadyUnlocked.contains(id)).toList();
  }
}
```

### 3. 成就展示页面（P3）

- 新建 `AchievementPage`
- 按分类展示成就列表
- 已解锁成就显示解锁时间
- 未解锁成就显示条件简述和进度条

### 4. 成就同步（P3）

- 积分上报时附带 `achievement_ids`
- 服务端校验后写入 `user_achievements` 表
- WebSocket 推送 `achievement_unlock` 事件

## 数据结构

### Achievement 模型（已有）

```dart
class Achievement {
  final String id;
  final String name;
  final String description;
  final String icon;      // emoji
  final String category;  // milestone/regularity/health/fun/score
  final DateTime? unlockedAt;

  static final List<Achievement> all = [
    Achievement(id: 'morning_7', name: '晨便达人', icon: '🌅', ...),
    Achievement(id: 'morning_30', name: '晨便守护者', icon: '⛅', ...),
    // ... 共13个
  ];
}
```

### 成就解锁条件表

| ID | 名称 | 条件 | 类别 |
|----|------|------|------|
| morning_7 | 晨便达人 | 7天内>=7次晨便(6-9点) | milestone |
| morning_30 | 晨便守护者 | 30天内>=30次晨便 | milestone |
| regular_7 | 规律7天 | 规律指数>=80达7天 | regularity |
| regular_30 | 规律大师 | 规律指数>=80达30天 | regularity |
| first_big | 初次出库 | 第1次大号记录 | milestone |
| paid_pooper | 带薪拉屎 | 第1次标记带薪 | fun |
| score_100 | 百分达人 | 赛季积分>=100 | score |
| score_1000 | 千分社长 | 赛季积分>=1000 | score |
| bristol_gold | 黄金标准 | 布里斯托3-4占比>70% | health |
| duration_master | 时长大师 | 平均时长3-8分钟且>=10次 | health |
| all_star | 全勤之星 | 连续7天有大号 | milestone |
| streak_7 | 连击7天 | 连续7天至少1次大号 | regularity |
| streak_30 | 连击30天 | 连续30天至少1次大号 | regularity |

## 相关依赖

| 依赖模块 | 说明 |
|---------|------|
| [04-ranking-score.md](04-ranking-score.md) | 积分触发成就检查 |
| [07-backend-integration.md](07-backend-integration.md) | 成就同步API |
| [09-notification-reminder.md](09-notification-reminder.md) | 解锁通知 |
| [06-data-layer.md](06-data-layer.md) | 成就持久化 |