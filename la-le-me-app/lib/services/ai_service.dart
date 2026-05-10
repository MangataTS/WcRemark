import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/toilet_record.dart';
import '../services/database_service.dart';
import '../services/regularity_calculator.dart';

class AIProvider {
  final String name;
  final String icon;
  final String baseUrl;
  final List<String> models;

  const AIProvider({
    required this.name,
    required this.icon,
    required this.baseUrl,
    required this.models,
  });

  static const List<AIProvider> providers = [
    AIProvider(
      name: 'DeepSeek',
      icon: '🐋',
      baseUrl: 'https://api.deepseek.com',
      models: ['deepseek-chat', 'deepseek-reasoner'],
    ),
    AIProvider(
      name: 'OpenAI',
      icon: '🤖',
      baseUrl: 'https://api.openai.com',
      models: ['gpt-4o', 'gpt-4o-mini', 'gpt-3.5-turbo'],
    ),
    AIProvider(
      name: 'Claude',
      icon: '🧠',
      baseUrl: 'https://api.anthropic.com',
      models: ['claude-sonnet-4-20250514', 'claude-haiku-4-20250414'],
    ),
    AIProvider(
      name: '通义千问',
      icon: '🌟',
      baseUrl: 'https://dashscope.aliyuncs.com',
      models: ['qwen-turbo', 'qwen-plus', 'qwen-max'],
    ),
    AIProvider(
      name: '自定义',
      icon: '⚙️',
      baseUrl: '',
      models: [],
    ),
  ];
}

class AIConfig {
  final String provider;
  final String apiKey;
  final String baseUrl;
  final String model;
  final double temperature;
  final String customPrompt;
  final String analysisFrequency;

  const AIConfig({
    this.provider = 'DeepSeek',
    this.apiKey = '',
    this.baseUrl = 'https://api.deepseek.com',
    this.model = 'deepseek-chat',
    this.temperature = 0.3,
    this.customPrompt = '',
    this.analysisFrequency = 'manual',
  });

  Map<String, dynamic> toMap() {
    return {
      'provider': provider,
      'api_key': apiKey,
      'base_url': baseUrl,
      'model': model,
      'temperature': temperature,
      'custom_prompt': customPrompt,
      'analysis_frequency': analysisFrequency,
    };
  }

  factory AIConfig.fromMap(Map<String, dynamic> map) {
    return AIConfig(
      provider: map['provider'] as String? ?? 'DeepSeek',
      apiKey: map['api_key'] as String? ?? '',
      baseUrl: map['base_url'] as String? ?? 'https://api.deepseek.com',
      model: map['model'] as String? ?? 'deepseek-chat',
      temperature: (map['temperature'] as num?)?.toDouble() ?? 0.3,
      customPrompt: map['custom_prompt'] as String? ?? '',
      analysisFrequency: map['analysis_frequency'] as String? ?? 'manual',
    );
  }
}

class AIAnalysisResult {
  final int healthScore;
  final String status;
  final String summary;
  final List<String> observations;
  final List<String> suggestions;
  final List<String> warnings;
  final String humorNote;
  final String benchmark;
  final String focusNextWeek;

  const AIAnalysisResult({
    required this.healthScore,
    required this.status,
    required this.summary,
    required this.observations,
    required this.suggestions,
    required this.warnings,
    required this.humorNote,
    required this.benchmark,
    required this.focusNextWeek,
  });

  factory AIAnalysisResult.fromJson(Map<String, dynamic> json) {
    return AIAnalysisResult(
      healthScore: json['health_score'] as int? ?? 50,
      status: json['status'] as String? ?? '未知',
      summary: json['summary'] as String? ?? '',
      observations: (json['observations'] as List?)?.cast<String>() ?? [],
      suggestions: (json['suggestions'] as List?)?.cast<String>() ?? [],
      warnings: (json['warnings'] as List?)?.cast<String>() ?? [],
      humorNote: json['humor_note'] as String? ?? '',
      benchmark: json['benchmark'] as String? ?? '',
      focusNextWeek: json['focus_next_week'] as String? ?? '',
    );
  }
}

class AIService {
  static const _secureStorage = FlutterSecureStorage();
  static final Dio _dio = Dio();

  static const String _defaultPromptTemplate = '''# 角色设定
你是一位专业的消化健康顾问，擅长用轻松幽默但专业准确的语言与用户交流。
你的建议基于循证医学，但表达方式要像一位关心朋友健康的老友。

# 用户数据摘要（过去7天）
{aggregated_data}

# 输出格式（严格JSON）
请直接输出JSON，不要包含任何其他文字：

{
  "health_score": <0-100的整数>,
  "status": <状态描述>,
  "summary": <一句话幽默总结，20字以内>,
  "observations": [<观察点1>, <观察点2>],
  "suggestions": [<建议1>, <建议2>, <建议3>],
  "warnings": [<如有异常必须提醒就医，正常为空数组>],
  "humor_note": <一句轻松的调侃>,
  "benchmark": <与同龄人群的对比描述>,
  "focus_next_week": <下周建议关注的重点>
}''';

  static Future<AIConfig> getConfig() async {
    String? json = await _secureStorage.read(key: 'ai_config');
    if (json == null) return const AIConfig();
    return AIConfig.fromMap(jsonDecode(json));
  }

  static Future<void> saveConfig(AIConfig config) async {
    await _secureStorage.write(key: 'ai_config', value: jsonEncode(config.toMap()));
  }

  static Future<bool> testConnection() async {
    final config = await getConfig();
    if (config.apiKey.isEmpty) return false;

    try {
      final response = await _dio.post(
        '${config.baseUrl}/v1/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${config.apiKey}',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
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
    } catch (_) {
      return false;
    }
  }

  static Future<AIAnalysisResult> analyze() async {
    AIConfig config = await getConfig();
    if (config.apiKey.isEmpty) throw AIException('请先配置 API Key');

    List<ToiletRecord> records = await DatabaseService.getRecentRecords(days: 7);
    Map<String, dynamic> aggregated = _aggregateWeekly(records);

    String prompt = config.customPrompt.isNotEmpty
        ? config.customPrompt
        : _defaultPromptTemplate;
    prompt = prompt.replaceAll('{aggregated_data}', jsonEncode(aggregated));

    try {
      var response = await _dio.post(
        '${config.baseUrl}/v1/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${config.apiKey}',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
        ),
        data: {
          'model': config.model,
          'messages': [
            {'role': 'system', 'content': 'You are a health advisor. Output valid JSON only.'},
            {'role': 'user', 'content': prompt},
          ],
          'temperature': config.temperature,
          'max_tokens': 1500,
        },
      );

      String content = response.data['choices'][0]['message']['content'];
      Map<String, dynamic> result = jsonDecode(content);

      await DatabaseService.saveAIReport(
        reportId: DateTime.now().millisecondsSinceEpoch.toString(),
        result: result,
        validUntil: DateTime.now().add(const Duration(days: 7)),
      );

      return AIAnalysisResult.fromJson(result);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw AIException('API Key 无效，请检查配置');
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw AIException('连接超时，请检查网络或 Base URL');
      }
      throw AIException('分析失败: ${e.message}');
    }
  }

  static Map<String, dynamic> _aggregateWeekly(List<ToiletRecord> records) {
    DateTime now = DateTime.now();

    int totalCount = records.length;
    int bigCount = records.where((r) => r.type == RecordType.big).length;
    int smallCount = totalCount - bigCount;

    Map<String, int> dailyBigCount = {};
    for (int i = 0; i < 7; i++) {
      DateTime day = now.subtract(Duration(days: i));
      String dayKey = '${day.month}月${day.day}日';
      int count = records.where((r) {
        DateTime dt = DateTime.fromMillisecondsSinceEpoch(r.timestamp);
        return dt.day == day.day && dt.month == day.month && r.type == RecordType.big;
      }).length;
      dailyBigCount[dayKey] = count;
    }

    Map<int, int> bristolDist = {};
    for (int i = 1; i <= 7; i++) {
      bristolDist[i] = records.where((r) => r.bristolType == i).length;
    }

    Map<String, int> periodDist = {
      '早晨(6-9点)': 0,
      '上午(9-12点)': 0,
      '下午(12-18点)': 0,
      '晚上(18-24点)': 0,
      '凌晨(0-6点)': 0,
    };
    for (var r in records) {
      DateTime dt = DateTime.fromMillisecondsSinceEpoch(r.timestamp);
      int hour = dt.hour;
      if (hour >= 6 && hour < 9) {
        periodDist['早晨(6-9点)'] = periodDist['早晨(6-9点)']! + 1;
      } else if (hour >= 9 && hour < 12) {
        periodDist['上午(9-12点)'] = periodDist['上午(9-12点)']! + 1;
      } else if (hour >= 12 && hour < 18) {
        periodDist['下午(12-18点)'] = periodDist['下午(12-18点)']! + 1;
      } else if (hour >= 18) {
        periodDist['晚上(18-24点)'] = periodDist['晚上(18-24点)']! + 1;
      } else {
        periodDist['凌晨(0-6点)'] = periodDist['凌晨(0-6点)']! + 1;
      }
    }

    double avgBigDuration = _avgDuration(
      records.where((r) => r.type == RecordType.big).toList(),
    );

    int regularityScore = RegularityCalculator.calculate(records);

    return {
      'period': '过去7天',
      'total_count': totalCount,
      'big_count': bigCount,
      'small_count': smallCount,
      'avg_big_per_day': (bigCount / 7).toStringAsFixed(1),
      'avg_big_duration_minutes': avgBigDuration.toStringAsFixed(1),
      'bristol_distribution': bristolDist,
      'period_distribution': periodDist,
      'regularity_score': regularityScore,
      'daily_big_count': dailyBigCount,
    };
  }

  static double _avgDuration(List<ToiletRecord> records) {
    if (records.isEmpty) return 0;
    int totalSeconds = records.fold(0, (sum, r) => sum + (r.duration ?? 0));
    return (totalSeconds / records.length) / 60;
  }
}

class AIException implements Exception {
  final String message;
  AIException(this.message);

  @override
  String toString() => message;
}