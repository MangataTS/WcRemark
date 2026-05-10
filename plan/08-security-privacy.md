# 安全与隐私模块

## 功能描述

安全与隐私模块保障用户数据的本地优先策略和访问控制，包含：
- 生物识别解锁（Face ID / 指纹）
- 应用锁（启动时/敏感操作时要求认证）
- 隐私模式（最近任务卡片空白化）
- 匿名排行（排行榜中隐藏昵称和头像）
- SQLite 数据库加密（AES-256）
- API Key 安全存储

## 当前实现状态

### 已完成
- [x] `security_page.dart` - UI框架（应用锁/隐私模式/匿名排行开关）
- [x] `FlutterSecureStorage` 用于 AI API Key 存储
- [x] `Encrypt` 相关依赖声明（`encrypt` 包）

### 未完成
- **[关键]** `_checkBiometric()` 使用 `Future.delayed(500ms)` 模拟，**未接入 `local_auth` 插件**
- [ ] 应用锁功能：启动时检测设置 → 要求认证
- [ ] 开关持久化（`appLockEnabled` 等设置项未与 `SettingsService` 打通）
- [ ] 隐私模式实现（`privacyModeEnabled` = 隐藏最近任务内容）
- [ ] 匿名排行实现（`anonymousRanking` = 排行榜显示"匿名肠友"）
- [ ] SQLite 数据库加密
- [ ] 敏感操作三级确认中的生物识别步骤（清空数据时的第三级确认）
- [ ] `flutter_secure_storage` 2.0 迁移（Android Keystore安全层）

## 实现步骤

### 1. 集成 local_auth 生物识别（P1）

```dart
// lib/services/biometric_service.dart
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final _localAuth = LocalAuthentication();

  static Future<bool> isDeviceSupported() async {
    return await _localAuth.isDeviceSupported();
  }

  static Future<List<BiometricType>> getAvailableBiometrics() async {
    return await _localAuth.getAvailableBiometrics();
  }

  static Future<bool> authenticate({
    String reason = '请验证身份以继续',
  }) async {
    if (!await isDeviceSupported()) return false;
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: '身份验证',
            cancelButton: '取消',
            biometricHint: '请验证生物特征',
          ),
          IOSAuthMessages(
            cancelButton: '取消',
            goToSettingsButton: '去设置',
          ),
        ],
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } on PlatformException {
      return false;
    }
  }
}
```

**pubspec.yaml 添加**：
```yaml
local_auth: ^2.3.0
```

### 2. 应用锁流程（P1）

```dart
// main.dart - 在 MyApp 外层包装
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_CN', null);
  await initDatabaseFactory();

  final settings = await SettingsService.instance.load();
  if (settings.appLockEnabled) {
    final authenticated = await BiometricService.authenticate(reason: '解锁「拉了么」');
    if (!authenticated) {
      // 显示锁定界面，不允许进入
    }
  }

  runApp(const MyApp());
}
```

### 3. 敏感操作验证（P1）

```dart
// 替换 data_management_page.dart 中的模拟延迟
Future<bool> _verifyForSensitiveAction(String action) async {
  final settings = await SettingsService.instance.load();
  if (!settings.appLockEnabled) return true;
  return await BiometricService.authenticate(reason: '验证身份以$action');
}
```

### 4. 隐私模式（P2）

```dart
// main.dart - 隐私模式：最近任务卡片空白
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final settings = ref.watch(settingsProvider);
      return MaterialApp(
        theme: ThemeData(),
        builder: (context, child) {
          if (settings.privacyModeEnabled) {
            return PrivacyScreen(child: child!);
          }
          return child!;
        },
      );
    });
  }
}

class PrivacyScreen extends StatelessWidget {
  // 当App进入后台时显示空白遮罩
  // 使用 AppLifecycleState 监听
}
```

### 5. SQLite 加密（P2）

```yaml
# pubspec.yaml - 替换依赖
# sqflite: ^2.3.0  →  sqflite_sqlcipher: ^2.3.0
```

```dart
// database_service.dart - 加密打开
import 'package:sqflite_sqlcipher/sqflite_sqlcipher.dart';

Future<Database> _initDatabase() async {
  final encryptionKey = await _getEncryptionKey();
  return await openDatabase(
    path,
    version: _currentVersion,
    password: encryptionKey,
    onCreate: _onCreate,
  );
}

Future<String> _getEncryptionKey() async {
  final storage = FlutterSecureStorage();
  var key = await storage.read(key: 'db_encryption_key');
  if (key == null) {
    key = base64Url.encode(Random.secure().nextBytes(32));
    await storage.write(key: 'db_encryption_key', value: key);
  }
  return key;
}
```

## 接口定义

### BiometricService

```dart
abstract class BiometricService {
  static Future<bool> isDeviceSupported();
  static Future<List<BiometricType>> getAvailableBiometrics();
  static Future<bool> authenticate({String reason});
}
```

### SettingsService 关联

| 设置项 | 说明 | 存储位置 |
|--------|------|---------|
| appLockEnabled | 应用锁开关 | SharedPreferences |
| preferredBiometric | 首选识别类型 | SharedPreferences |
| privacyModeEnabled | 隐私模式 | SharedPreferences |
| anonymousRanking | 匿名排行 | SharedPreferences |
| dbEncryptionKey | 数据库加密密钥 | FlutterSecureStorage |
| aiApiKey | 大模型API Key | FlutterSecureStorage |
| jwtToken | 认证令牌 | FlutterSecureStorage |

## 数据安全矩阵

| 数据类型 | 存储位置 | 加密方式 | 服务端可见 |
|---------|---------|---------|----------|
| 原始如厕记录 | 本地SQLite | AES-256 | ❌ |
| 三围数据 | 本地SQLite | AES-256 | ❌ |
| API Key | Keychain/Keystore | 系统级 | ❌ |
| 积分流水 | PostgreSQL | TLS | ✅ |
| 用户昵称 | PostgreSQL | TLS | ✅ |
| 备份文件 | 对象存储 | 客户端AES-256-GCM | ⚠️加密blob |

## 相关依赖

| 依赖模块 | 说明 |
|---------|------|
| [06-data-layer.md](06-data-layer.md) | 数据库加密 |
| [05-settings-profile.md](05-settings-profile.md) | 设置开关 |
| [13-backup-restore.md](13-backup-restore.md) | 备份文件加密 |
| [03-ai-analysis.md](03-ai-analysis.md) | API Key安全存储 |