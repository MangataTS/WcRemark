# 统计分析模块

## 功能描述

统计分析模块提供用户历史健康数据的多维度可视化，包含：
- 周统计：规律指数环形图、7日趋势图、时段热力图、关键指标卡片、布里斯托分布
- 月统计：日历热力图、月度时段饼图、健康等级评定
- 年统计：12月折线图、年度关键词、季度对比

## 当前实现状态

### 已完成
- [x] `stats_page.dart` - 入口页（3张导航卡片：周报/月报/年报）
- [x] `WeeklyStatsPage` - UI框架（规律指数卡片、7日趋势柱状图、布里斯托分布条形图、迷你统计卡片）
- [x] `RegularityCalculator` - 规律指数算法（环形时间标准差）
- [x] `HealthGradeCalculator` - 月度健康评级算法（频率/规律/布里斯托/时长四维评分）
- [x] `YearlyKeywordGenerator` - 年度关键词生成
- [x] `PaidPoopCalculator` - 带薪收益计算

### 未完成
- **WeekStatsPage 所有数据为硬编码Mock**：counts=[1,2,1,0,2,3,1]、规律指数=85等
- [ ] MonthlyStatsPage - 纯占位，仅显示"月度统计 - 开发中"
- [ ] YearlyStatsPage - 纯占位，仅显示"年度报告 - 开发中"
- [ ] 本周概览卡片（首页）的"状态: 良好"硬编码 → 应接入真实健康评级
- [ ] 统计页缺少 fl_chart 图表组件的实际使用
- [ ] 日历热力图组件未实现
- [ ] 时段热力图未实现
- [ ] 月度健康等级展示未实现

## 实现步骤

### 1. 状态管理 + 数据层对接（P0）

```dart
// 创建 WeeklyStatsProvider
@riverpod
class WeeklyStats extends _$WeeklyStats {
  @override
  Future<WeeklyStatsData> build() async {
    final records = await DatabaseService.instance.getRecentRecords(days: 7);
    return WeeklyStatsData.fromRecords(records);
  }
}

class WeeklyStatsData {
  final int bigCount;
  final int smallCount;
  final List<int> dailyBigCounts;  // 7天
  final Map<int, int> bristolDistribution;
  final int regularityScore;
  final String healthGrade;
  final double avgDuration;
  final double paidHours;
  final Map<String, int> periodDistribution;
}
```

### 2. WeeklyStatsPage 真实数据替换（P0）

- 新建 `WeeklyStatsData` 数据类 → 聚合7天记录的统计算法
- 用 `ConsumerWidget` 重写 `WeeklyStatsPage`
- 替换所有硬编码数据为 Provider 中的计算结果
- 柱状图用 fl_chart `BarChart`，传入 `dailyBigCounts`

### 3. MonthlyStatsPage 开发（P0）

- 日历热力图组件 `MonthlyCalendarView`
- 月度时段饼图
- 健康等级评定展示（A/B/C/D + 雷达图或柱状图）
- 带薪收益月度汇总

### 4. YearlyStatsPage 开发（P0）

- 12个月折线图（月大号次数）
- 年度关键词卡片 `YearlyKeywordGenerator`
- 季度时段对比
- 年度健康评级趋势

### 5. 统计页图表组件库（P0）

| 组件 | 关联 | 用途 |
|------|------|------|
| `WeekScoreRing` | 周报 | 规律指数环形进度条 |
| `WeekTrendChart` | 周报 | 7日柱状+折线混合图 |
| `WeekHeatMap` | 周报 | 7×24时段热力图 |
| `StatCard` | 通用 | 可滑动指标卡片 |
| `BristolDistributionChart` | 周报/月报 | 布里斯托分型分布 |
| `MonthlyCalendarView` | 月报 | 日历热力图 |
| `HealthGradeCard` | 月报 | 健康等级评定卡片 |
| `YearlyLineChart` | 年报 | 12月折线图 |

## 接口定义

### 统计数据聚合接口

```dart
abstract class StatsRepository {
  Future<WeeklyStatsData> getWeeklyStats(DateTime weekStart);
  Future<MonthlyStatsData> getMonthlyStats(int year, int month);
  Future<YearlyStatsData> getYearlyStats(int year);
}

class WeeklyStatsData {
  final int totalBig;
  final int totalSmall;
  final List<int> dailyBigCounts;        // 7天
  final Map<int, int> bristolDist;       // {1:0, 2:1, 3:5, 4:3, 5:1, 6:0, 7:0}
  final int regularityScore;             // 0-100
  final String healthGrade;             // A/B/C/D
  final double avgBigDuration;          // 分钟
  final double paidEarnings;            // 元
  final Map<String, int> periodDist;     // {"早晨":3, "上午":2, ...}
}

class MonthlyStatsData {
  final Map<int, int> dailyBigCounts;    // {1:0, 2:1, ..., 30:2}
  final String healthGrade;
  final Map<String, double> gradeBreakdown;
  final int totalBig;
  final Map<String, int> periodDist;
  final double paidEarnings;
}

class YearlyStatsData {
  final Map<int, int> monthlyBigCounts;  // {1:45, 2:52, ...}
  final List<String> keywords;
  final Map<String, dynamic> quarterComparison;
}
```

## 数据结构

### 规律指数算法（已实现）

输入：`List<ToiletRecord>` 7天记录
输出：`int` 0-100分
算法：提取每日第一次大号时间 → 环形标准差展开 → 映射到0-100

### 健康等级评定（已实现）

输入：`List<ToiletRecord>` 月度记录
输出：`HealthGrade(grade, title, score, breakdown)`
维度：频率(30%) + 规律(25%) + 布里斯托(25%) + 时长(20%)

### 年度关键词（已实现）

输入：`List<ToiletRecord>` 年度记录
输出：`List<String>` 关键词列表

## 相关依赖

| 依赖模块 | 说明 |
|---------|------|
| [10-state-management.md](10-state-management.md) | Riverpod Provider 管理统计数据 |
| [06-data-layer.md](06-data-layer.md) | DatabaseService 提供记录查询 |
| [01-home-record.md](01-home-record.md) | 首页引用健康评级数据 |
| 第三方库 `fl_chart` | pubspec.yaml 已声明依赖 |