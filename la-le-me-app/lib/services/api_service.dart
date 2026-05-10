import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/ranking.dart';
import '../models/score.dart';
import 'api_config.dart';

class ApiService {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: '${ApiConfig.baseUrl}/api/v1',
    connectTimeout: ApiConfig.connectTimeout,
    receiveTimeout: ApiConfig.receiveTimeout,
    headers: {'Content-Type': 'application/json'},
  ));

  static const _secureStorage = FlutterSecureStorage();

  static Future<String?> getToken() async {
    return await _secureStorage.read(key: 'auth_token');
  }

  static Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: 'refresh_token');
  }

  static Future<void> setTokens(String token, String refreshToken) async {
    await _secureStorage.write(key: 'auth_token', value: token);
    await _secureStorage.write(key: 'refresh_token', value: refreshToken);
  }

  static Future<void> clearTokens() async {
    await _secureStorage.delete(key: 'auth_token');
    await _secureStorage.delete(key: 'refresh_token');
  }

  static Future<void> _ensureAuth() async {
    String? token = await getToken();
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  // ============ Auth ============

  static Future<Map<String, dynamic>> register({
    required String deviceId,
    String nickname = '',
    String platform = 'android',
    String appVersion = '1.0.0',
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'device_id': deviceId,
      'nickname': nickname,
      'platform': platform,
      'app_version': appVersion,
    });

    final data = response.data['data'];
    await setTokens(data['token'], data['refresh_token']);
    return data;
  }

  static Future<Map<String, dynamic>> refreshToken() async {
    String? refreshToken = await getRefreshToken();
    if (refreshToken == null) throw Exception('No refresh token');

    final response = await _dio.post('/auth/refresh', data: {
      'refresh_token': refreshToken,
    });

    final data = response.data['data'];
    await setTokens(data['token'], data['refresh_token'] ?? refreshToken);
    return data;
  }

  // ============ User ============

  static Future<Map<String, dynamic>> getProfile() async {
    await _ensureAuth();
    final response = await _dio.get('/user/profile');
    return response.data['data'];
  }

  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profile) async {
    await _ensureAuth();
    final response = await _dio.put('/user/profile', data: profile);
    return response.data['data'];
  }

  // ============ Score ============

  static Future<ScoreSettlementResult> syncScore(Map<String, dynamic> scoreData) async {
    await _ensureAuth();
    final response = await _dio.post('/records/sync', data: scoreData);
    return ScoreSettlementResult.fromJson(response.data);
  }

  // ============ Rankings ============

  static Future<RankingPageResult> getGlobalRanking({
    String? season,
    int page = 1,
    int limit = 20,
  }) async {
    await _ensureAuth();
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (season != null) queryParams['season'] = season;

    final response = await _dio.get('/rankings/global', queryParameters: queryParams);
    return RankingPageResult.fromJson(response.data);
  }

  static Future<RankingPageResult> getCityRanking({
    required String cityCode,
    String? season,
    int page = 1,
    int limit = 20,
  }) async {
    await _ensureAuth();
    final queryParams = <String, dynamic>{
      'city_code': cityCode,
      'page': page,
      'limit': limit,
    };
    if (season != null) queryParams['season'] = season;

    final response = await _dio.get('/rankings/city', queryParameters: queryParams);
    return RankingPageResult.fromJson(response.data);
  }

  static Future<RankingPageResult> getFriendsRanking({
    String? season,
  }) async {
    await _ensureAuth();
    final queryParams = <String, dynamic>{};
    if (season != null) queryParams['season'] = season;

    final response = await _dio.get('/rankings/friends', queryParameters: queryParams);
    return RankingPageResult.fromJson(response.data);
  }

  // ============ Backup ============

  static Future<Map<String, dynamic>> uploadBackup(String filePath) async {
    await _ensureAuth();
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });

    final response = await _dio.post('/backup', data: formData);
    return response.data['data'];
  }

  static Future<List<Map<String, dynamic>>> getBackupList() async {
    await _ensureAuth();
    final response = await _dio.get('/backup/list');
    return (response.data['data']['backups'] as List).cast<Map<String, dynamic>>();
  }

  static Future<String> getBackupDownloadUrl(int backupId) async {
    await _ensureAuth();
    final response = await _dio.get('/backup/$backupId/download');
    return response.data['data']['download_url'];
  }

  static Future<void> deleteBackup(int backupId) async {
    await _ensureAuth();
    await _dio.delete('/backup/$backupId');
  }

  // ============ Friends ============

  static Future<void> addFriend(String friendCode) async {
    await _ensureAuth();
    await _dio.post('/friends/add', data: {'friend_code': friendCode});
  }

  static Future<List<Map<String, dynamic>>> getFriendList() async {
    await _ensureAuth();
    final response = await _dio.get('/friends/list');
    return (response.data['data']['friends'] as List).cast<Map<String, dynamic>>();
  }
}