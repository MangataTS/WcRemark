# 设置与个人档案模块

## 功能描述

设置模块是应用的配置中心，包含：
- 个人档案（昵称/头像/性别/身高体重/三围/职业）
- AI配置（服务商/Key/参数）
- 安全设置（应用锁/隐私模式/匿名排行）
- 数据管理（导出/恢复/同步/清空）
- 云端备份（加密备份/历史列表）
- 其他设置（主题/音效/提醒/段位查看）

## 当前实现状态

### 已完成
- [x] `profile_page.dart` - 完整的个人档案编辑（昵称/性别/出生年/身高体重/腰围/职业）
- [x] `profile_page.dart` - 加载/保存与 `DatabaseService` 对接
- [x] `ai_config_page.dart` - AI配置页（服务商/Key/参数/测试）
- [x] `settings_page.dart` - 设置导航页
- [x] `settings_service.dart` - 14项设置完整持久化（SharedPreferences）

### 未完成
- [ ] 段位信息查看页（设置中点击"段位"弹出"开发中"）
- [ ] 隐私模式切换（占位）
- [ ] 匿名排行切换（占位）
- [ ] 主题设置（浅色/深色/OLED，占位）
- [ ] 隐私政策页（占位）
- [ ] 音效开关（UI有但onChanged为空）
- [ ] 晨间提醒开关（UI有但onChanged为空）
- [ ] 头像选择/裁剪（UI有相机图标但无功能）
- [ ] SettingsService 与 UI 层的对接（各页面未使用 SettingsService）
- [ ] 医疗免责声明弹窗内容（已有弹窗但内容简略）

## 实现步骤

### 1. 设置页面对接 SettingsService（P1）

```dart
// settings_page.dart - 将硬编码状态替换为 SettingsService
// 示例：音效开关
SwitchListTile(
  value: settings.soundEffectEnabled,
  onChanged: (v) async {
    settings = settings.copyWith(soundEffectEnabled: v);
    await SettingsService.instance.save(settings);
    setState(() {});
  },
)
```

需替换的设置项：
- 音效开关 → `settings.soundEffectEnabled`
- 晨间提醒 → `settings.morningReminderEnabled`
- 晨间提醒时间 → `settings.morningReminderTime`
- 应用锁 → `settings.appLockEnabled`
- 隐私模式 → `settings.privacyModeEnabled`
- 匿名排行 → `settings.anonymousRanking`
- 自动检测工作时间 → `settings.autoDetectWorkHours`
- 快速记录默认 → `settings.quickRecordDefault`
- 布里斯托提醒 → `settings.showBristolReminder`

### 2. 段位信息查看页（P1）

- 新建 `RankInfoPage`
- 展示当前段位/积分/距离下一段位所需积分
- 展示本赛季排名
- 段位历史列表（从 `season_history` 表读取）

### 3. 主题系统（P2）

- 浅色/深色/OLED三种模式
- `AppColors` 已定义但未被Screen统一使用
- 创建 `ThemeProvider` (Riverpod)
- 各页面替换硬编码颜色为 `Theme.of(context)` 扩展

### 4. 头像选择（P2）

- `image_picker` 插件选图片
- `image_cropper` 裁剪为圆形
- Base64编码存入 `ProfileModel.avatarBase64`
- 大小限制 100KB

### 5. 音效系统（P3）

- `audioplayers` / `just_audio` 插件
- 音效类型：水流声 / 冲水声 / 屁声 / 自定义
- 录音时播放
- 配合 `settings.soundVolume` 控制音量

### 6. 隐私政策页（P3）

- 新建 `PrivacyPolicyPage`
- 引用文档第十节的内容
- App Store 审核必需

## 接口定义

### AppSettings 数据结构（已实现）

```dart
class AppSettings {
  ThemeMode themeMode;         // system/light/dark
  bool useOledDark;            // OLED纯黑
  SoundEffect soundEffect;     // none/water_drop/flush/fart/custom
  double soundVolume;          // 0.0-1.0
  bool morningReminderEnabled;
  TimeOfDay morningReminderTime; // 默认07:00
  bool sedentaryReminderEnabled;
  int sedentaryReminderMinutes;  // 默认120
  bool irregularReminderEnabled;
  bool appLockEnabled;
  BiometricType preferredBiometric;
  bool privacyModeEnabled;
  bool anonymousRanking;
  bool autoDetectWorkHours;
  bool quickRecordDefault;
  bool showBristolReminder;
  EmojiStyle emojiStyle;       // cute/serious/minimal
}
```

### 段位信息接口（待实现）

```dart
class RankInfo {
  final String currentRankName;
  final int currentSeasonScore;
  final int nextRankMinScore;
  final int rankLevel;
  final String rankIcon;
  final List<SeasonHistory> seasonHistories;
}
```

## 相关依赖

| 依赖模块 | 说明 |
|---------|------|
| [06-data-layer.md](06-data-layer.md) | 设置/档案持久化 |
| [08-security-privacy.md](08-security-privacy.md) | 应用锁/生物识别 |
| [09-notification-reminder.md](09-notification-reminder.md) | 提醒时间设置 |
| [10-state-management.md](10-state-management.md) | 设置状态管理 |
| [04-ranking-score.md](04-ranking-score.md) | 段位信息查询 |