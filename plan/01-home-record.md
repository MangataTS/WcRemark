# 首页记录模块

## 功能描述

首页记录模块是用户的核心交互入口，包含：
- 动态问候语（基于时间段/上下文）
- 今日核心数据卡片（出库次数、健康状态）
- 本周概览卡片
- 肠道日报小贴士
- 快速记录按钮（小号一键、大号详情、自定义）
- 记录详情页（QuickDetail / FullDetail）

## 当前实现状态

### 已完成
- [x] 动态问候语文案逻辑 (`app_utils.dart` → `_getGreeting`)
- [x] 今日记录数据加载（从DB读取大号/小号数量）
- [x] 核心数据卡片UI（今日出库次数）
- [x] 本周概览双卡片UI
- [x] 肠道日报区域UI
- [x] 快速记录ActionSheet（小号一键、大号跳转详情）
- [x] 记录详情页完整表单（类型/时长/布里斯托/顺畅度/带薪/心情/备注）
- [x] 下拉刷新

### 未完成/有Bug
- **[关键Bug]** `record_detail_page.dart` 返回值未被 `home_page.dart` 持久化到数据库
  - `_save()` 使用 `Navigator.pop(context, record)` 返回数据
  - 但 `home_page.dart` 中的 `.then((_) => _loadData())` 忽略了返回值
  - 需要接收返回值并调用 `DatabaseService.insertRecord()`
- [ ] 本周概览卡片"状态: 良好"为硬编码，应接入 `HealthGradeCalculator`
- [x] 肠道日报小贴士已从 `assets/data/app_content.json` 动态加载
- [ ] 快速详情面板（QuickDetail）未实现（文档规约：小号记录后可选弹QuickDetail）
- [ ] 自定义记录类型未实现
- [ ] 记录保存后触发积分计算流程未串联
- [ ] 核心卡片副文案 `getSubTitle` 逻辑在首页有简化版，但文档中有更完整的规则

## 实现步骤

### 1. 修复记录持久化（P0-紧急）

```dart
// home_page.dart - 修复 _showRecordActionSheet 中大号记录跳转
Navigator.pushNamed(context, '/record/detail').then((result) {
  if (result != null && result is Map<String, dynamic>) {
    _saveRecordToDatabase(result);
  }
  _loadData();
});

Future<void> _saveRecordToDatabase(Map<String, dynamic> data) async {
  final record = ToiletRecord.fromMap(data);
  await DatabaseService.instance.insertRecord(record);
  // 触发积分计算
  final score = ScoreCalculator.calculate(record, _allRecords);
  // 异步上报
  _syncScoreToServer(record, score);
}
```

### 2. 接入健康状态动态数据（P0）

- 本周概览卡片"状态"字段使用 `HealthGradeCalculator.calculateWeekly()` 替换硬编码
- 从DB获取近7天记录 → 计算健康评级 → 显示对应文案

### 3. 实现QuickDetail面板（P1）

- 创建 `QuickDetailSheet` 组件
- 可选字段：时长（单选）、顺畅度（滑块）、带薪开关
- 点击"完成"直接保存到DB
- 点击"详细记录"跳转 FullDetail

### 4. 接入 AnomalyDetector 动态提示（P2）

- 检查便秘/腹泻异常 → 替换硬编码小贴士

## 接口定义

### 记录保存流程

```
用户操作 → QuickDetail/FullDetail → ToiletRecord Map
    ↓
DatabaseService.insertRecord(record) → 本地持久化
    ↓
ScoreCalculator.calculate(record, history) → 积分计算
    ↓
ApiService.syncScore(ScoreSettlementRequest) → 异步上报
```

### HomePage 需要的状态数据

| 数据 | 来源 | 类型 |
|------|------|------|
| 今日大号数 | DB查询 | `int` |
| 今日小号数 | DB查询 | `int` |
| 距上次大号小时数 | DB计算 | `int` |
| 本周大号总数 | DB查询 | `int` |
| 本周健康评级 | HealthGradeCalculator | `String` |
| 每日小贴士 | AnomalyDetector / 固定文案 | `String` |

## 数据结构

### ToiletRecord (已有)

```dart
class ToiletRecord {
  String id;
  RecordType type;       // small / big
  int timestamp;
  int? duration;
  int? bristolType;
  int? color;
  int? smoothness;
  bool isWorkHours;
  bool isPaidPoop;
  String? locationHash;
  String? note;
  String? mood;
  bool isSynced;
  String? syncUuid;
}
```

### QuickDetailSheet (待实现)

```dart
class QuickDetailData {
  final RecordType type;
  int? duration;        // 秒数，预设档位
  int? smoothness;      // 1-5
  bool? isPaidPoop;
}
```

## 相关依赖

| 依赖模块 | 说明 |
|---------|------|
| [10-state-management.md](10-state-management.md) | Riverpod Provider 提供记录列表 |
| [06-data-layer.md](06-data-layer.md) | DatabaseService CRUD |
| [04-ranking-score.md](04-ranking-score.md) | ScoreCalculator 积分计算 |
| [07-backend-integration.md](07-backend-integration.md) | 积分异步上报 |
| [09-notification-reminder.md](09-notification-reminder.md) | 异常检测触发通知 |