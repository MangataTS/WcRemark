# 备份与恢复模块

## 功能描述

备份与恢复模块保障用户数据安全，包含：
- 本地加密备份（AES-256-GCM）
- 备份文件导出到手机/云盘
- 从备份文件恢复数据
- 云端备份（上传到对象存储）
- 备份历史管理与删除
- 清空数据（三级确认+生物识别）

## 当前实现状态

### 已完成
- [x] `backup_page.dart` - UI框架（加密说明卡片、创建备份按钮、备份历史列表）
- [x] `data_management_page.dart` - UI框架（导出/恢复/同步/导入/清空）
- [x] `ApiService` 备份接口方法（uploadBackup/getBackupList/getBackupDownloadUrl/deleteBackup）

### 未完成（所有核心操作均为"开发中"占位）
- [ ] 备份文件生成（从DB导出JSON）
- [ ] AES-256-GCM 加密/解密
- [ ] 备份文件保存到手机文件系统
- [ ] 从备份文件选择并恢复
- [ ] 云端备份上传
- [ ] 备份历史列表展示
- [ ] 清空数据的二级/三级确认逻辑
- [ ] CSV 导入

## 实现步骤

### 1. 备份数据序列化（P1）

```dart
// lib/services/backup_service.dart
class BackupService {
  static Future<String> exportBackup({String? password}) async {
    final db = await DatabaseService.instance.database;

    // 1. 导出所有记录
    final records = await db.query('toilet_records', orderBy: 'timestamp ASC');
    // 2. 导出用户档案
    final profile = await db.query('user_profile', limit: 1);
    // 3. 导出设置
    final settings = await db.query('app_settings');
    // 4. 导出AI报告
    final aiReports = await db.query('ai_reports');
    // 5. 导出赛季历史
    final seasonHistory = await db.query('season_history');
    // 6. 导出成就
    final achievements = await db.query('achievements');

    final backupData = {
      'version': '1.0',
      'export_date': DateTime.now().toIso8601String(),
      'app_version': '1.0.0',
      'metadata': {
        'record_count': records.length,
        'first_record_date': records.isNotEmpty
          ? DateTime.fromMillisecondsSinceEpoch(records.first['timestamp'] as int).toIso8601String()
          : null,
        'last_record_date': records.isNotEmpty
          ? DateTime.fromMillisecondsSinceEpoch(records.last['timestamp'] as int).toIso8601String()
          : null,
        'profile_present': profile.isNotEmpty,
      },
      'records': records,
      'profile': profile.isNotEmpty ? profile.first : null,
      'settings': settings,
      'ai_reports': aiReports,
      'season_history': seasonHistory,
      'achievements': achievements,
    };

    final jsonStr = jsonEncode(backupData);

    // 7. 如有密码则加密
    if (password != null && password.isNotEmpty) {
      return await BackupEncryption.encrypt(jsonStr, password);
    }

    return jsonStr;
  }

  static Future<String> getChecksum(String data) async {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return 'sha256:$digest';
  }
}
```

### 2. AES-256-GCM 加密/解密（P1）

```dart
// lib/services/backup_encryption.dart
import 'package:encrypt/encrypt.dart';
import 'package:crypto/crypto.dart';
import 'dart:typed_data';

class BackupEncryption {
  static Future<String> encrypt(String jsonData, String password) async {
    // 1. 生成随机盐值（16字节）
    final salt = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final saltBytes = Uint8List.fromList(salt);

    // 2. PBKDF2 派生密钥（10万次迭代）
    final key = _deriveKey(password, saltBytes);

    // 3. 生成随机IV（12字节，GCM推荐）
    final iv = List<int>.generate(12, (_) => Random.secure().nextInt(256));
    final ivBytes = IV.fromUint8Array(Uint8List.fromList(iv));

    // 4. AES-256-GCM 加密
    final encrypter = Encrypter(AES(Key(key), mode: AESMode.gcm));
    final encrypted = encrypter.encrypt(jsonData, iv: ivBytes);

    // 5. 组装：salt(16) + iv(12) + ciphertext + tag(16)
    final result = Uint8List(salt.length + iv.length + encrypted.base64.length);
    // ... bytes assembly logic

    return base64Encode(result);
  }

  static Future<String> decrypt(String base64Data, String password) async {
    final data = base64Decode(base64Data);

    // 1. 提取 salt, iv, ciphertext
    final salt = Uint8List.sublistView(data, 0, 16);
    final iv = Uint8List.sublistView(data, 16, 28);
    final ciphertext = Uint8List.sublistView(data, 28);

    // 2. 重新派生密钥
    final key = _deriveKey(password, salt);

    // 3. 解密
    final encrypter = Encrypter(AES(Key(key), mode: AESMode.gcm));
    final decrypted = encrypter.decrypt(
      Encrypted.fromUint8Array(Uint8List.fromList(ciphertext)),
      iv: IV.fromUint8Array(Uint8List.fromList(iv)),
    );

    return decrypted;
  }

  static Uint8List _deriveKey(String password, Uint8List salt) {
    // PBKDF2 with 100,000 iterations
    // 使用 pointycastle 的 PBKDF2
    // ... implementation
  }
}
```

### 3. 文件选存（P1）

```dart
// 使用 file_picker 和 path_provider
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

class BackupFileService {
  static Future<String?> saveBackupToFile(String encryptedData) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'la_le_me_backup_$timestamp.enc';
    final file = File('${directory.path}/backups/$fileName');

    await file.parent.create(recursive: true);
    await file.writeAsString(encryptedData);

    // 可选：分享到其他App
    await Share.shareXFiles([XFile(file.path)], text: '拉了么备份文件');

    return file.path;
  }

  static Future<String?> pickBackupFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['enc', 'json'],
    );
    if (result != null && result.files.isNotEmpty) {
      return result.files.first.path;
    }
    return null;
  }
}
```

### 4. 清空数据三级确认（P1）

```dart
// data_management_page.dart - 替换占位代码
Future<void> _confirmClearAll() async {
  // 一级确认：弹窗
  final confirm1 = await showDialog<bool>(/* ... */);
  if (confirm1 != true) return;

  // 二级确认：输入"确认清空"
  final input = await showTextInputDialog(/* ... */);
  if (input != '确认清空') return;

  // 三级确认：生物识别
  final bioAuth = await BiometricService.authenticate(reason: '清空数据');
  if (!bioAuth) return;

  // 执行清空
  await DatabaseService.instance.clearAll();
  await FlutterSecureStorage().deleteAll();

  // 重启
  Phoenix.rebirth(context);
}
```

### 5. 云端备份（P2）

- 调用 `ApiService.uploadBackup()` 上传加密文件
- 备份列表展示、下载、删除

## 备份文件格式

```json
{
  "version": "1.0",
  "export_date": "2026-05-10T16:54:00Z",
  "app_version": "1.2.0",
  "checksum": "sha256:abc123...",
  "metadata": {
    "record_count": 1523,
    "first_record_date": "2025-01-01",
    "last_record_date": "2026-05-10",
    "profile_present": true
  },
  "records": [...],
  "profile": {...},
  "settings": [...],
  "ai_reports": [...],
  "season_history": [...],
  "achievements": [...]
}
```

## 相关依赖

| 依赖模块 | 说明 |
|---------|------|
| [06-data-layer.md](06-data-layer.md) | 数据库读取与清空 |
| [08-security-privacy.md](08-security-privacy.md) | 加密/生物识别 |
| [07-backend-integration.md](07-backend-integration.md) | 云端备份上传/下载 |
| 第三方库 `encrypt` | 已声明依赖 |
| 第三方库 `file_picker` | 需添加 |
| 第三方库 `share_plus` | 需添加 |
| 第三方库 `path_provider` | 需添加 |