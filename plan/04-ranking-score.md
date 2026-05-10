# 排名与积分模块

## 功能描述

排名与积分模块是游戏化健康管理的核心驱动力，包含：
- 六维乘数积分体系（R/H/T/P/S/M）
- 七级段位系统（便秘青铜 → 最强王者）
- 月度赛季管理与赛季切换重置
- 排行榜四档（全球/同城/好友/趣味）
- 积分异步上报与结算反馈

## 当前实现状态

### 已完成
- [x] `ScoreCalculator.calculate()` - 六维乘数完整计算
  - R（规律性）：30天大号时间标准差 → 0.8~1.5
  - H（健康）：布里斯托分型 → 0.5~1.2
  - T（时长）：3-8分钟最优 → 0.7~1.1
  - P（带薪）：1.0~1.2
  - S（连击）：连续规律天数 → 1.0~2.0
  - M（晨便）：6-9点 → 1.0~1.15
  - 单次积分上限25.0
- [x] `PaidPoopCalculator` - 带薪收益计算
- [x] `Rank.getRankNameByScore()` / `getRankLevelByScore()` - 段位查询
- [x] `ScoreSettlementResult` - 结算结果模型（含 `fromJson`）
- [x] `SeasonHistory` - 赛季历史模型
- [x] `SeasonManager.getCurrentSeason()` - 当前赛季标识
- [x] `ranking_page.dart` - 三Tab UI框架（全球/同城/好友）
- [x] `ApiService` - 排行榜API方法（getGlobalRanking/getCityRanking/getFriendsRanking）

### 未完成
- **全球排行榜使用50条Mock数据**，未调用 `ApiService.getGlobalRanking()`
- [ ] 同城排行榜：纯占位页
- [ ] 好友排行榜：纯占位页
- [ ] 趣味排行榜：文档规划了6个分类（小号频率/效率/带薪/晨便/周末/规律），未开发
- [ ] 赛季切换检测与重置逻辑：`SeasonManager` 只有 `getCurrentSeason()`，缺少 `checkSeasonRollover()`
- [ ] 积分上报流程：记录保存后 → 计算积分 → 调用 `ApiService.syncScore()` 未串联
- [ ] 排行榜分页加载与下拉刷新
- [ ] 当前用户排名高亮卡片
- [ ] 段位信息查看页（设置中的"段位"点击占位）
- [ ] WebSocket 实时排名推送

## 实现步骤

### 1. 全球榜对接真实API（P0）

```dart
// ranking_page.dart - GlobalRankingTab
class _GlobalRankingTabState extends ConsumerStatefulWidget<GlobalRankingTab> {
  int _page = 1;
  bool _hasMore = true;
  List<RankingItem> _items = [];

  Future<void> _loadRankings() async {
    try {
      final result = await ApiService.instance.getGlobalRanking(
        page: _page,
        limit: 20,
      );
      setState(() {
        if (_page == 1) _items = result.items;
        else _items.addAll(result.items);
        _hasMore = _items.length < result.total;
        _page++;
      });
    } catch (e) {
      // 处理未登录/网络错误
    }
  }
}
```

### 2. 赛季切换检测（P1）

```dart
// season.dart - 补充 SeasonManager
class SeasonManager {
  static Future<void> checkSeasonRollover() async {
    final currentSeason = getCurrentSeason();
    final lastKnown = await DatabaseService.instance.getSetting('last_known_season');

    if (lastKnown != currentSeason) {
      // 保存上赛季数据
      final lastScore = await DatabaseService.instance.getSetting('season_score') ?? '0';
      final lastRank = await _calculateCurrentRank(int.parse(lastScore));

      await DatabaseService.instance.saveSeasonHistory(
        SeasonHistory(
          season: lastKnown ?? currentSeason,
          finalScore: int.parse(lastScore),
          finalRank: lastRank,
        ),
      );

      // 重置本赛季积分
      await DatabaseService.instance.setSetting('season_score', '0');
      await DatabaseService.instance.setSetting('last_known_season', currentSeason);

      // 通知服务端
      try {
        await ApiService.instance.resetSeason(currentSeason);
      } catch (_) {}
    }
  }
}
```

### 3. 保留积分上报串联（P1）

```
记录保存 → ScoreCalculator.calculate(record, history)
    → 得到 finalScore + 各乘数
    → 构建 ScoreSettlementRequest
    → ApiService.syncScore(request)
    → 接收 ScoreSettlementResult
    → 更新本地赛季积分
    → 更新UI显示
```

### 4. 同城榜/好友榜/趣味榜（P2）

- 同城榜：依赖用户设置 `city_code` → 调用 `getCityRanking(cityCode)`
- 好友榜：依赖好友系统 → 调用 `getFriendsRanking()`
- 趣味榜：需后端新增API或客户端本地计算

### 5. WebSocket实时推送（P2）

- 建立 `ws://host/ws/rankings?token=JWT` 连接
- 监听 `rank_update` / `friend_surpass` / `achievement_unlock` / `season_change`
- 更新UI对应位置

## 接口定义

### 积分结算请求（已定义于 api_service.dart）

```dart
// POST /api/v1/records/sync
{
  "record_uuid": "uuid",
  "type": "big",
  "timestamp": 1715328000000,
  "duration": 300,
  "is_work_hours": true,
  "is_paid_poop": true,
  "bristol_type": 4,
  "base_score": 5.0,
  "multipliers": {"r": 1.3, "h": 1.2, "t": 1.1, "p": 1.2, "s": 1.2, "m": 1.15},
  "final_score": 14.9,
  "achievement_ids": ["morning_7"],
  "location_hash": "hash"
}
```

### 排行榜查询接口（已定义于 api_service.dart）

```dart
// GET /api/v1/rankings/global?season=2026-05&page=1&limit=20
// GET /api/v1/rankings/city?city_code=510100&season=2026-05&page=1&limit=20
// GET /api/v1/rankings/friends?season=2026-05
```

## 数据结构

### 积分乘数模型 (已有)

```dart
class Multipliers {
  double r;  // 规律性 0.8~1.5
  double h;  // 健康 0.5~1.2
  double t;  // 时长 0.7~1.1
  double p;  // 带薪 1.0~1.2
  double s;  // 连击 1.0~2.0
  double m;  // 晨便 1.0~1.15

  double get total => r * h * t * p * s * m;
}
```

### 段位定义 (已有)

| 段位 | 积分范围 | 图标 |
|------|---------|------|
| 便秘青铜 | 0-99 | 🥉 |
| 通畅白银 | 100-499 | 🥈 |
| 规律黄金 | 500-1999 | 🥇 |
| 铂金肠王 | 2000-4999 | 💎 |
| 钻石所长 | 5000-9999 | 👑 |
| 星耀肠道长 | 10000-19999 | 🌟 |
| 最强王者 | 20000+ | 🏆 |

## 相关依赖

| 依赖模块 | 说明 |
|---------|------|
| [10-state-management.md](10-state-management.md) | 排行榜状态/积分状态 |
| [07-backend-integration.md](07-backend-integration.md) | API调用 |
| [11-anti-cheat.md](11-anti-cheat.md) | 积分上报前预检 |
| [01-home-record.md](01-home-record.md) | 记录后触发积分计算 |
| [12-achievement.md](12-achievement.md) | 积分触发成就检查 |