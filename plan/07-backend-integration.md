# 后端API集成

## 功能描述

后端集成模块负责客户端与Go服务端的全部HTTP通信，包含：
- 设备注册与JWT认证
- 积分异步上报
- 排行榜查询（全球/同城/好友）
- 云端备份（上传/下载/列表/删除）
- 好友系统
- WebSocket实时推送

## 当前实现状态

### 已完成
- [x] `ApiService` - 完整的REST API客户端（基于Dio）
- [x] JWT认证流程（注册/刷新Token/Token存储）
- [x] 用户接口（getProfile/updateProfile）
- [x] 积分同步接口（syncScore）
- [x] 排行榜接口（getGlobalRanking/getCityRanking/getFriendsRanking）
- [x] 备份接口（uploadBackup/getBackupList/getBackupDownloadUrl/deleteBackup）
- [x] 好友接口（addFriend/getFriendList）
- [x] 错误处理与异常分类

### 未完成
- **[关键]** Base URL硬编码为 `10.0.2.2:8080`（模拟器地址），无环境切换机制
- [ ] API环境配置（开发/测试/生产）
- [ ] Token自动刷新拦截器（Dio Interceptor）
- [ ] 离线队列（网络不可用时缓存积分上报请求）
- [ ] WebSocket连接管理
- [ ] API调用在各个页面中的实际使用（排行榜/备份等用Mock数据）

## 实现步骤

### 1. 环境配置管理（P0）

```dart
// lib/services/api_config.dart
class ApiConfig {
  static const String _devBaseUrl = 'http://10.0.2.2:8080';
  static const String _stagingBaseUrl = 'https://staging-api.la-le-me.app';
  static const String _prodBaseUrl = 'https://api.la-le-me.app';

  static String get baseUrl {
    const env = String.fromEnvironment('ENV', defaultValue: 'dev');
    switch (env) {
      case 'prod': return _prodBaseUrl;
      case 'staging': return _stagingBaseUrl;
      default: return _devBaseUrl;
    }
  }

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
```

### 2. Token自动刷新拦截器（P1）

```dart
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await SecureStorage.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final newToken = await _tryRefreshToken();
      if (newToken != null) {
        err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        handler.resolve(await _retry(err.requestOptions));
        return;
      }
    }
    handler.next(err);
  }
}
```

### 3. 离线队列（P2）

```dart
class OfflineQueue {
  static const _queueKey = 'offline_requests';

  static Future<void> enqueue(Map<String, dynamic> request) async {
    final queue = await _getQueue();
    queue.add({
      ...request,
      'enqueued_at': DateTime.now().toIso8601String(),
    });
    await _saveQueue(queue);
  }

  static Future<void> flush() async {
    final queue = await _getQueue();
    for (final req in queue) {
      try {
        await ApiService.instance.syncScore(req);
      } catch (_) {
        break; // 网络仍不可用，停止发送
      }
    }
    await _saveQueue([]);
  }
}
```

### 4. WebSocket连接管理（P2）

```dart
class WebSocketService {
  WebSocketChannel? _channel;
  String? _token;

  Future<void> connect() async {
    _token = await SecureStorage.getToken();
    final uri = Uri.parse('ws://${ApiConfig.baseUrl}/ws/rankings?token=$_token');
    _channel = WebSocketChannel.connect(uri);
    _channel!.stream.listen(_onMessage, onError: _onError, onDone: _onDone);
  }

  void _onMessage(dynamic data) {
    final json = jsonDecode(data);
    switch (json['type']) {
      case 'rank_update': _handleRankUpdate(json); break;
      case 'friend_surpass': _handleFriendSurpass(json); break;
      case 'achievement_unlock': _handleAchievementUnlock(json); break;
      case 'season_change': _handleSeasonChange(json); break;
    }
  }
}
```

## 接口定义

### 已实现API（api_service.dart）

| 方法 | 端点 | 状态 |
|------|------|------|
| POST /api/v1/auth/register | 设备注册 | ✅ |
| POST /api/v1/auth/refresh | 刷新Token | ✅ |
| GET /api/v1/user/profile | 获取资料 | ✅ |
| PUT /api/v1/user/profile | 更新资料 | ✅ |
| POST /api/v1/records/sync | 积分上报 | ✅ |
| GET /api/v1/rankings/global | 全球排行 | ✅ |
| GET /api/v1/rankings/city | 同城排行 | ✅ |
| GET /api/v1/rankings/friends | 好友排行 | ✅ |
| POST /api/v1/backup | 上传备份 | ✅ |
| GET /api/v1/backup/list | 备份列表 | ✅ |
| GET /api/v1/backup/:id/download | 下载备份 | ✅ |
| DELETE /api/v1/backup/:id | 删除备份 | ✅ |
| POST /api/v1/friends/add | 添加好友 | ✅ |
| GET /api/v1/friends | 好友列表 | ✅ |

### 待实现API

| 端点 | 说明 |
|------|------|
| WS /ws/rankings | WebSocket实时推送 |
| GET /api/v1/achievements | 成就列表 |
| POST /api/v1/achievements/unlock | 解锁成就 |

## 相关依赖

| 依赖模块 | 说明 |
|---------|------|
| [01-home-record.md](01-home-record.md) | 记录后积分上报 |
| [04-ranking-score.md](04-ranking-score.md) | 排行榜数据 |
| [12-achievement.md](12-achievement.md) | 成就同步 |
| [13-backup-restore.md](13-backup-restore.md) | 云端备份 |
| 第三方库 `dio` | 已声明 |
| 第三方库 `web_socket_channel` | 已声明 |