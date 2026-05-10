# 状态管理架构

## 功能描述

状态管理是当前最关键的缺失模块。目前所有页面直接调用 `DatabaseService` 静态方法，缺乏全局状态管理，导致：
- 页面间数据不同步（首页修改数据后统计页不会自动刷新）
- 无法共享数据（排行榜数据在多处重复查询）
- 缺少加载/错误状态处理（数据加载时无loading状态，出错无友好提示）

采用 **Riverpod 2.x** 作为状态管理方案（已在 pubspec.yaml 中声明依赖）。

## 当前实现状态

### 问题
- 每个页面独立从DB读取数据，页面切换时数据不会自动更新
- 无全局状态缓存，相同查询重复执行
- 无统一的加载/错误状态管理
- UI与数据层紧耦合，难以测试和维护

### 已依赖
- `flutter_riverpod: ^2.5.0` 已在 pubspec.yaml 中声明

## 实现步骤

### 1. Provider 体系搭建（P0-最高优先级）

```dart
// lib/providers/database_provider.dart
@Riverpod(keepAlive: true)
DatabaseService databaseService(DatabaseServiceRef ref) {
  return DatabaseService.instance;
}

// lib/providers/record_provider.dart
@Riverpod(keepAlive: true)
class TodayRecords extends _$TodayRecords {
  @override
  Future<List<ToiletRecord>> build() async {
    final db = ref.watch(databaseServiceProvider);
    return await db.getTodayRecords();
  }

  Future<void> addRecord(ToiletRecord record) async {
    final db = ref.read(databaseServiceProvider);
    await db.insertRecord(record);
    // 计算积分
    final history = await db.getRecentRecords(days: 30);
    final score = ScoreCalculator.calculate(record, history);
    // 刷新状态
    ref.invalidateSelf();
  }

  Future<void> deleteRecord(String id) async {
    final db = ref.read(databaseServiceProvider);
    await db.deleteRecord(id);
    ref.invalidateSelf();
  }
}

// lib/providers/stats_provider.dart
@Riverpod
class WeeklyStats extends _$WeeklyStats {
  @override
  Future<WeeklyStatsData> build() async {
    final records = await ref.watch(todayRecordsProvider.future);
    final db = ref.read(databaseServiceProvider);
    final weekRecords = await db.getRecentRecords(days: 7);
    return WeeklyStatsData.fromRecords(weekRecords);
  }
}

// lib/providers/ranking_provider.dart
@Riverpod
class GlobalRanking extends _$GlobalRanking {
  @override
  Future<RankingPageResult> build() async {
    return await ApiService.instance.getGlobalRanking(page: 1, limit: 20);
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null) return;
    final next = await ApiService.instance.getGlobalRanking(
      page: (current.items.length ~/ 20) + 1,
      limit: 20,
    );
    state = AsyncData(RankingPageResult(
      items: [...current.items, ...next.items],
      total: next.total,
      page: next.page,
    ));
  }
}

// lib/providers/settings_provider.dart
@Riverpod(keepAlive: true)
class AppSettingsNotifier extends _$AppSettingsNotifier {
  @override
  Future<AppSettings> build() async {
    return await SettingsService.instance.load();
  }

  Future<void> update(AppSettings settings) async {
    await SettingsService.instance.save(settings);
    state = AsyncData(settings);
  }
}
```

### 2. 页面迁移到 Riverpod（P0）

```dart
// 改造前 (直接调用DB)
class _HomePageState extends State<HomePage> {
  List<ToiletRecord> _todayRecords = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _todayRecords = await DatabaseService.instance.getTodayRecords();
    setState(() {});
  }
}

// 改造后 (使用 Riverpod)
class HomePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(todayRecordsProvider);

    return recordsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('加载失败: $e')),
      data: (records) => _buildContent(context, ref, records),
    );
  }
}
```

### 3. Provider 清单

| Provider | 类型 | 保持 alive | 说明 |
|----------|------|-----------|------|
| `databaseServiceProvider` | DatabaseService | ✅ | DB单例 |
| `todayRecordsProvider` | List\<ToiletRecord\> | ✅ | 今日记录 |
| `weeklyRecordsProvider` | List\<ToiletRecord\> | ❌ | 近7天记录 |
| `weeklyStatsProvider` | WeeklyStatsData | ❌ | 周统计数据 |
| `monthlyStatsProvider` | MonthlyStatsData | ❌ | 月统计数据 |
| `yearlyStatsProvider` | YearlyStatsData | ❌ | 年统计数据 |
| `globalRankingProvider` | RankingPageResult | ❌ | 全球排行 |
| `cityRankingProvider` | RankingPageResult | ❌ | 同城排行 |
| `friendsRankingProvider` | RankingPageResult | ❌ | 好友排行 |
| `appSettingsProvider` | AppSettings | ✅ | 应用设置 |
| `profileProvider` | ProfileModel | ✅ | 用户档案 |
| `aiConfigProvider` | AIConfig | ✅ | AI配置 |
| `seasonProvider` | String | ✅ | 当前赛季 |

## 相关依赖

| 依赖模块 | 说明 |
|---------|------|
| 所有其他模块 | 所有模块都通过 Provider 获取数据 |
| 第三方库 `flutter_riverpod` | 已声明依赖 |
| 第三方库 `riverpod_annotation` | 代码生成注解（需添加） |
| 第三方库 `build_runner` | dev依赖（需添加） |
| 第三方库 `riverpod_generator` | dev依赖（需添加） |