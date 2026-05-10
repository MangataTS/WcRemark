# 通知与提醒模块

## 功能描述

通知与提醒模块提供主动推送能力，增强用户粘性和健康关怀：
- 晨间提醒（可配置时间，默认07:00-09:00窗口）
- 久坐提醒（可配置间隔，默认120分钟）
- 异常健康预警（便秘5天+、腹泻3天+、血便/黑便）
- 赛季切换通知
- 成就解锁通知
- 排名变化推送

## 当前实现状态

### 已完成
- [ ] 无任何通知/提醒相关代码

### 需依赖
- `flutter_local_notifications` 插件
- 移动端通知权限申请
- 后台执行调度

## 实现步骤

### 1. 添加依赖与权限配置（P1）

```yaml
# pubspec.yaml
dependencies:
  flutter_local_notifications: ^18.0.1
  timezone: ^0.9.2
```

**Android**（`android/app/src/main/AndroidManifest.xml`）：
```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
```

**iOS**（`ios/Runner/Info.plist`）：
```xml
<key>NSUserNotificationsUsageDescription</key>
<string>拉了么需要发送健康提醒通知</string>
```

### 2. 通知服务（P1）

```dart
// lib/services/notification_service.dart
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  static Future<void> show({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'la_le_me_channel',
      '拉了么通知',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }

  static Future<void> scheduleDaily({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    // 使用 zonedSchedule 实现每日定时通知
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
```

### 3. AnomalyDetector 集成（P1）

```dart
// lib/services/anomaly_detector.dart
class AnomalyDetector {
  static Future<void> checkAndAlert() async {
    final records = await DatabaseService.instance.getRecentRecords(days: 7);
    final allRecords = await DatabaseService.instance.getRecords();

    // 1. 便秘检测（5天无大号）
    final lastBig = allRecords.where((r) => r.type == RecordType.big).toList();
    if (lastBig.isNotEmpty) {
      final daysSince = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(lastBig.last.timestamp)
      ).inDays;
      if (daysSince >= 5) {
        await NotificationService.show(
          title: '⚠️ 肠道预警',
          body: '已经 $daysSince 天没有大号了，建议多吃膳食纤维，必要时就医。',
          payload: 'anomaly:constipation',
        );
      }
    }

    // 2. 腹泻检测（连续3天每天大号>=3次且bristol 5-7）
    if (_hasPersistentDiarrhea(records)) {
      await NotificationService.show(
        title: '⚠️ 腹泻预警',
        body: '检测到持续腹泻症状，请注意补水，如超过3天请立即就医。',
        payload: 'anomaly:diarrhea',
      );
    }

    // 3. 血便/黑便检测
    final bloodRecords = allRecords.where((r) =>
      r.type == RecordType.big && (r.color == 2 || r.color == 1) // red/black
    ).toList();
    if (bloodRecords.isNotEmpty) {
      await NotificationService.show(
        title: '🚨 重要健康提醒',
        body: '检测到异常便便颜色记录，建议尽快就医检查。',
        payload: 'anomaly:blood',
      );
    }
  }

  static bool _hasPersistentDiarrhea(List<ToiletRecord> records) {
    // 连续3天，每天大号>=3次且bristol 5-7
    // 实现逻辑...
    return false;
  }
}
```

### 4. 晨间/久坐提醒调度（P2）

```dart
// main.dart 启动时注册定时通知
static Future<void> scheduleReminders() async {
  final settings = await SettingsService.instance.load();

  if (settings.morningReminderEnabled) {
    final hour = settings.morningReminderTime.hour;
    final minute = settings.morningReminderTime.minute;
    await NotificationService.scheduleDaily(
      hour: hour,
      minute: minute,
      title: '🚽 早安！该出库了',
      body: '新的一天，肠道也该开始工作了～',
    );
  }

  // 久坐提醒 - 使用 WorkManager 或定时检查
  if (settings.sedentaryReminderEnabled) {
    // 注册周期性后台任务
  }
}
```

## 接口定义

### NotificationService

```dart
abstract class NotificationService {
  static Future<void> initialize();
  static Future<void> show({required String title, required String body, String? payload});
  static Future<void> scheduleDaily({required int hour, required int minute, required String title, required String body});
  static Future<void> scheduleDelayed({required Duration delay, required String title, required String body, String? payload});
  static Future<void> cancelAll();
  static Future<void> requestPermission();
}
```

### AnomalyDetector

```dart
abstract class AnomalyDetector {
  static Future<void> checkAndAlert();
  static bool hasConstipation(List<ToiletRecord> allRecords);
  static bool hasPersistentDiarrhea(List<ToiletRecord> recentRecords);
  static bool hasBloodInStool(List<ToiletRecord> allRecords);
}
```

## 通知类型定义

| 类型 | 通知标题 | 触发条件 | Payload |
|------|---------|---------|---------|
| 晨间提醒 | 🚽 早安！该出库了 | 每日定时(07:00-09:00) | `reminder:morning` |
| 久坐提醒 | 🚶 该动动了 | 坐了2小时+ | `reminder:sedentary` |
| 便秘预警 | ⚠️ 肠道预警 | 5天+无大号 | `anomaly:constipation` |
| 腹泻预警 | ⚠️ 腹泻预警 | 连续3天bristol 5-7 | `anomaly:diarrhea` |
| 血便预警 | 🚨 重要健康提醒 | 记录中color=red/black | `anomaly:blood` |
| 排名变化 | 🎉 排名上升 | WebSocket推送 | `rank:update` |
| 成就解锁 | 🏆 成就解锁 | WebSocket推送 | `achievement:unlock` |
| 赛季切换 | 🎉 新赛季开始 | 月初检测 | `season:change` |

## 相关依赖

| 依赖模块 | 说明 |
|---------|------|
| [01-home-record.md](01-home-record.md) | 记录后触发异常检测 |
| [05-settings-profile.md](05-settings-profile.md) | 提醒开关/时间设置 |
| [04-ranking-score.md](04-ranking-score.md) | 赛季切换/排名推送 |
| [12-achievement.md](12-achievement.md) | 成就解锁通知 |