# AI智能分析模块

## 功能描述

AI智能分析模块让用户配置大模型服务商，从本地SQLite聚合脱敏数据，构建Prompt，直连大模型API获取健康分析建议。核心原则：**API Key仅存本地，数据不出客户端**。

## 当前实现状态

### 已完成
- [x] `AIProvider` 五大服务商定义（DeepSeek/OpenAI/Claude/通义千问/自定义）
- [x] `AIConfig` 完整配置模型，含 `toMap`/`fromMap`
- [x] `AIAnalysisResult` 结构化结果模型，含 `fromJson`
- [x] `AIService` 配置读写（FlutterSecureStorage）
- [x] `AIService.analyze()` 完整分析流程
  - 获取近7天记录 → `_aggregateWeekly()` 数据脱敏聚合 → 构建Prompt → 调API → 存报告 → 返回
- [x] 异常处理 `AIException`（401/超时等分类）
- [x] `ai_config_page.dart` UI完整（服务商选择/Key输入/参数配置/安全提示）
- [x] AI报告本地缓存（写入 `ai_reports` 表）

### 未完成
- [ ] **AI连接测试未真实验证**：`_testConnection()` 只是保存配置并显示成功，未发送测试请求
- [ ] AI分析结果展示页面（查看历史报告、趋势对比）
- [ ] AI分析自动触发（设置中选择了"每日晚9点"或"每次记录后"）
- [ ] AnomalyDetector 异常预警自动检测未接入
- [ ] 自定义Prompt编辑功能（UI中是ExpansionTile但功能为占位）

## 实现步骤

### 1. 修复测试连接逻辑（P1）

```dart
Future<bool> testConnection() async {
  final config = await getConfig();
  if (config == null || config.apiKey.isEmpty) return false;

  try {
    final dio = Dio();
    final response = await dio.post(
      '${config.baseUrl}/chat/completions',
      options: Options(
        headers: {
          'Authorization': 'Bearer ${config.apiKey}',
          'Content-Type': 'application/json',
        },
        sendTimeout: Duration(seconds: 10),
        receiveTimeout: Duration(seconds: 15),
      ),
      data: {
        'model': config.model,
        'messages': [
          {'role': 'user', 'content': '请回复"连接成功"'}
        ],
        'max_tokens': 20,
      },
    );
    return response.statusCode == 200;
  } catch (e) {
    return false;
  }
}
```

### 2. AI报告展示页面（P1）

- 新建 `AIReportPage`
- 列表展示历史分析报告
- 点击查看详情：健康评分环形图、观察点、建议、预警
- 7天缓存有效期显示

### 3. 自定义Prompt功能（P2）

- `ExpandedTile` 中的文本框保存到 `AIConfig.customPrompt`
- "恢复默认"按钮重置为内置模板
- 分析时：`customPrompt.isNotEmpty ? customPrompt : defaultTemplate`

### 4. 分析频率自动触发（P2）

- "手动触发"：默认，用户主动点击分析
- "每日晚9点"：`flutter_local_notifications` 定时触发
- "每次记录后"：记录保存后检查是否需要新分析（距上次>24h才触发）

### 5. AnomalyDetector 集成（P2）

- 记录保存后自动运行异常检测
- 便秘5天+、腹泻3天+、血便/黑便 → 本地通知 + 强制建议AI分析

## 接口定义

### AI分析请求

```dart
// 已实现，存在于 ai_service.dart
Future<AIAnalysisResult> analyze() async {
  // 1. 读取配置
  // 2. 获取7天记录并聚合
  // 3. 构建Prompt
  // 4. 调用大模型API
  // 5. 解析JSON响应
  // 6. 缓存到本地
  // 7. 返回结构化结果
}
```

### AI分析结果模型

```dart
class AIAnalysisResult {
  final int healthScore;           // 0-100
  final String status;             // "运转良好" / "略有波动" / "需要关注"
  final String summary;            // 一句话幽默总结
  final List<String> observations; // 观察点
  final List<String> suggestions;  // 建议
  final List<String> warnings;     // 预警（异常必须提醒就医）
  final String humorNote;          // 幽默调侃
  final String benchmark;          // 同龄对比
  final String focusNextWeek;      // 下周关注重点
}
```

### Prompt模板（内置默认）

```
角色设定 → 专业消化健康顾问
用户数据摘要 → {aggregated_data} 脱敏聚合
输出格式 → 严格JSON
重要规则 → 异常就医提醒、不暴露精确时间、温暖语气
```

## 数据结构

### AI数据聚合输出（`_aggregateWeekly`）

```json
{
  "period": "过去7天",
  "total_count": 21,
  "big_count": 14,
  "small_count": 7,
  "avg_big_per_day": "2.0",
  "avg_big_duration_minutes": "6.5",
  "bristol_distribution": {"1":0, "2":1, "3":4, "4":6, "5":2, "6":1, "7":0},
  "period_distribution": {"早晨(6-9点)":5, "上午(9-12点)":3, ...},
  "regularity_score": 85,
  "daily_big_count": {"5月10日":2, "5月9日":1, ...},
  "user_profile": {"age_range": "26-35", "gender": "male", "bmi_category": "normal"}
}
```

### AI报告存储（ai_reports表）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | TEXT | UUID |
| created_at | INTEGER | 创建时间戳 |
| result | TEXT | JSON字符串（需修复：应为jsonEncode而非toString） |
| valid_until | INTEGER | 有效期截止 |

## 相关依赖

| 依赖模块 | 说明 |
|---------|------|
| [06-data-layer.md](06-data-layer.md) | AI报告存储/读取 |
| [09-notification-reminder.md](09-notification-reminder.md) | 定时分析触发/异常预警 |
| [10-state-management.md](10-state-management.md) | AI配置/分析状态管理 |
| [08-security-privacy.md](08-security-privacy.md) | API Key安全存储 |
| 第三方库 `flutter_secure_storage` | 已声明依赖 |
| 第三方库 `dio` | 已声明依赖 |