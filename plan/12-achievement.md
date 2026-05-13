# 成就系统

## 功能描述

成就系统通过游戏化机制增强用户粘性：
- 25 个预定义成就（里程碑/规律/健康/趣味/积分五类）
- 在 `assets/data/app_content.json` 中集中管理，编辑 JSON 即可新增/修改
- 自动解锁条件判定
- 解锁通知与展示
- 进度追踪

## 当前实现状态

### 已完成
- [x] `Achievement` / `AchievementDef` 模型类
- [x] `AppContentLoader` 从 `assets/data/app_content.json` 加载成就定义
- [x] `AchievementService` 24 个成就的自动检测与解锁逻辑
- [x] `AchievementPage` 成就殿堂展示页面（分类+进度+解锁时间）
- [x] 成就解锁通知（SnackBar + 水滴提示音 + 震动）
- [x] 数据库 `achievements` 表（`id TEXT PK`, `unlocked_at INTEGER`, `synced INTEGER`）

### 未完成
- [ ] 成就与服务端同步（上报/拉取）

## 如何新增/修改成就

编辑 `assets/data/app_content.json` 文件，在 `achievements` 数组中添加新条目：

```json
{
  "id": "your_achievement_id",
  "name": "成就名称",
  "description": "成就描述",
  "icon": "🎯",
  "category": "milestone|regular|health|fun|score",
  "difficulty": "easy|medium|hard|epic",
  "target": 10
}
```

**注意**：新增成就需要在 `AchievementService.checkAndUnlock()` 和 `_calcProgress()` 中添加对应的检测逻辑。

## JSON 配置文件结构

文件位置：`assets/data/app_content.json`

```json
{
  "achievements": [
    { "id": "...", "name": "...", "description": "...", "icon": "🏁", "category": "milestone", "difficulty": "easy", "target": 0 }
  ],
  "daily_tips": [
    { "condition": "no_record", "text": "肠道日报：今日尚未出库..." },
    { "condition": "regularity_high", "text": "肠道日报：规律指数优秀..." },
    { "condition": "regularity_medium", "text": "肠道日报：规律指数尚可..." },
    { "condition": "constipation_risk", "text": "肠道日报：已经超过2天..." },
    { "condition": "default", "text": "肠道日报：保持每日规律..." }
  ]
}
```

## 数据结构

### AchievementDef 模型

```dart
class AchievementDef {
  final String id;
  final String name;
  final String description;
  final String icon;       // emoji
  final String category;   // milestone/regular/health/fun/score
  final String difficulty; // easy/medium/hard/epic
  final int target;        // 目标数值（0 表示无计数）
}
```

### 成就分类

| 类别 | ID | 数量 |
|------|-----|------|
| milestone | 里程碑 | 5 |
| regular | 规律健康 | 5 |
| health | 健康指标 | 4 |
| fun | 趣味挑战 | 8 |
| score | 积分段位 | 3 |

### 成就列表（25 个）

| ID | 名称 | 条件 | 类别 | 难度 |
|----|------|------|------|------|
| first_big | 初出茅庐 | 第1次大号记录 | milestone | easy |
| first_10 | 渐入佳境 | 累计10次大号 | milestone | easy |
| first_50 | 肠道常客 | 累计50次大号 | milestone | medium |
| first_100 | 百战老将 | 累计100次大号 | milestone | hard |
| first_365 | 一年之约 | 累计365次大号 | milestone | epic |
| morning_7 | 晨便达人 | 连续7天6:00-9:00大号 | regular | medium |
| morning_21 | 日出而作 | 累计21天6:00-9:00大号 | regular | hard |
| streak_7 | 一周规律 | 连续7天每天大号 | regular | medium |
| streak_30 | 规律大师 | 连续30天每天大号 | regular | hard |
| streak_100 | 生物钟活化石 | 连续100天每天大号 | regular | epic |
| perfect_bristol | 黄金便便 | 10次以上大号且70%为3-4型 | health | hard |
| bristol_master | 便便百科全书 | 集齐7种布里斯托分型 | health | epic |
| fiber_rich | 膳食纤维大使 | 连续3天布里斯托3-4型 | health | medium |
| health_a_7 | 模范肠道 | 连续7周健康A评级 | health | hard |
| paid_pooper | 带薪拉屎 | 10次带薪记录 | fun | easy |
| paid_king | 摸鱼之神 | 50次带薪记录+总时长>5h | fun | hard |
| speed_king | 闪电侠 | 5次时长1-3分钟 | fun | easy |
| marathon | 持久战 | 单次>15分钟 | fun | medium |
| week_warrior | 周末战士 | 30天周末记录>工作日 | fun | medium |
| mood_recorder | 情绪管理师 | 5种不同心情 | fun | medium |
| night_owl | 夜猫子 | 3次凌晨0-5点大号 | fun | medium |
| double_kill | 双杀 | 同天大号+小号 | fun | easy |
| score_500 | 规律达人 | 赛季积分≥500 | score | medium |
| score_2000 | 肠道大师 | 赛季积分≥2000 | score | hard |
| score_10000 | 传奇所长 | 赛季积分≥10000 | score | epic |

## 相关依赖

| 依赖模块 | 说明 |
|---------|------|
| [04-ranking-score.md](04-ranking-score.md) | 积分触发成就检查 |
| [07-backend-integration.md](07-backend-integration.md) | 成就同步API |
| [09-notification-reminder.md](09-notification-reminder.md) | 解锁通知 |
| [06-data-layer.md](06-data-layer.md) | 成就持久化 |

## 加载流程

```
main() → AppContentLoader.initialize()
       → rootBundle.loadString('assets/data/app_content.json')
       → 解析 JSON → AchievementDef.fromJson()
       → Achievement.definitionsOverride = [定义列表]
       → Achievement.definitions 返回 JSON 数据
       → AchievementService 基于 definitions 检测解锁
```
