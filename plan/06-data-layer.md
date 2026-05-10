# 数据持久化层

## 功能描述

数据持久化层是所有模块的基础，负责：
- SQLite 本地数据库管理（5张核心表+3索引）
- 多平台数据库初始化（IO/Web条件导入）
- CRUD操作封装
- 数据同步标记管理
- 设置项持久化（SharedPreferences + FlutterSecureStorage）

## 当前实现状态

### 已完成
- [x] `DatabaseService` - 完整的5表3索引数据库初始化
- [x] `toilet_records` 完整CRUD（insert/getRecords/getRecentRecords/getTodayRecords/update/delete/getUnsyncedRecords/markRecordSynced）
- [x] `user_profile` 读写（getProfile/saveProfile）
- [x] `season_history` 读写（saveSeasonHistory/getSeasonHistories）
- [x] `ai_reports` 读写（saveAIReport/getLatestAIReport）
- [x] `app_settings` 读写（getSetting/setSetting）
- [x] `clearAllData` / `deleteDatabase`
- [x] Web平台条件导入（database_factory_stub/io/web.dart）
- [x] `SettingsService` - 14项设置完整持久化（SharedPreferences）
- [x] `AIService` 配置存储（FlutterSecureStorage）

### 存在的问题
- **[Bug]** `saveAIReport()` 中 `result.toString()` 应为 `jsonEncode(result)`，导致AI报告存储为Dart Map的toString格式，后续无法正确解析
- [ ] `database_factory_io.dart` 为空函数（移动端依赖 sqflite 默认工厂）
- [ ] 无数据库迁移策略（版本升级时自动迁移）
- [ ] 无数据库加密（文档要求AES-256）
- [ ] 缺少批量查询优化（统计数据需要多次查询，应合并为SQL聚合）

## 实现步骤

### 1. 修复 saveAIReport bug（P0-紧急）

```dart
// database_service.dart - 修复 line 262-268
Future<void> saveAIReport({
  required String reportId,
  required Map<String, dynamic> result,
  required DateTime validUntil,
}) async {
  final db = await database;
  await db.insert('ai_reports', {
    'id': reportId,
    'created_at': DateTime.now().millisecondsSinceEpoch,
    'result': jsonEncode(result),  // 修复: 使用 jsonEncode 而非 toString
    'valid_until': validUntil.millisecondsSinceEpoch,
  });
}
```

### 2. 添加数据库迁移机制（P1）

```dart
// database_service.dart - 版本升级策略
static const int _currentVersion = 2;

Future<Database> _initDatabase() async {
  return await openDatabase(
    path,
    version: _currentVersion,
    onCreate: _onCreate,
    onUpgrade: _onUpgrade,
  );
}

Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    // v1→v2: 添加新字段
    await db.execute('ALTER TABLE toilet_records ADD COLUMN mood TEXT');
  }
}
```

### 3. 统计查询优化（P1）

```dart
// 添加聚合查询方法，减少内存中的数据加载
Future<Map<String, dynamic>> getWeeklyStatsRaw(DateTime weekStart) async {
  final db = await database;
  final results = await db.rawQuery('''
    SELECT
      COUNT(*) as total_count,
      SUM(CASE WHEN type = 1 THEN 1 ELSE 0 END) as big_count,
      SUM(CASE WHEN type = 0 THEN 1 ELSE 0 END) as small_count,
      AVG(CASE WHEN type = 1 AND duration IS NOT NULL THEN duration ELSE NULL END) as avg_big_duration,
      SUM(CASE WHEN is_paid_poop = 1 AND type = 1 THEN duration ELSE 0 END) as paid_duration
    FROM toilet_records
    WHERE timestamp >= ? AND timestamp < ?
  ''', [weekStart.millisecondsSinceEpoch, weekStart.add(Duration(days: 7)).millisecondsSinceEpoch]);
  return results.first;
}
```

### 4. 数据库加密（P2）

- 使用 `sqflite_sqlcipher` 替代 `sqflite`
- 密钥从 `FlutterSecureStorage` 获取
- Web端使用已有的 `sqflite_common_ffi_web`（无需加密）

## 数据库Schema

### toilet_records（主记录表）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | TEXT PK | UUID v4 |
| type | INTEGER | 0:小号 1:大号 |
| timestamp | INTEGER | 毫秒时间戳 |
| duration | INTEGER | 时长(秒)，可null |
| bristol_type | INTEGER | 1-7，仅大号 |
| color | INTEGER | 0:brown 1:black 2:red 3:other |
| smoothness | INTEGER | 1-5顺畅度 |
| is_work_hours | INTEGER | 0/1 |
| is_paid_poop | INTEGER | 0/1 |
| location_hash | TEXT | 地点哈希 |
| note | TEXT | 备注，最大200字 |
| mood | TEXT | 心情emoji |
| created_at | INTEGER | 创建时间 |
| updated_at | INTEGER | 更新时间 |
| is_synced | INTEGER | 0/1 是否已上报 |
| sync_uuid | TEXT | 上报UUID |

### 索引

```sql
CREATE INDEX idx_records_timestamp ON toilet_records(timestamp);
CREATE INDEX idx_records_type ON toilet_records(type);
CREATE INDEX idx_records_date ON toilet_records(date(timestamp/1000, 'unixepoch'));
CREATE INDEX idx_records_sync ON toilet_records(is_synced);
```

### user_profile / season_history / ai_reports / app_settings

（见 DatabaseService 已实现的建表SQL）

## 相关依赖

| 依赖模块 | 说明 |
|---------|------|
| [01-home-record.md](01-home-record.md) | 记录CRUD |
| [02-stats-analysis.md](02-stats-analysis.md) | 聚合查询 |
| [03-ai-analysis.md](03-ai-analysis.md) | AI报告存储 |
| [04-ranking-score.md](04-ranking-score.md) | 赛季积分 |
| [08-security-privacy.md](08-security-privacy.md) | 数据库加密 |
| [13-backup-restore.md](13-backup-restore.md) | 数据导出/导入 |