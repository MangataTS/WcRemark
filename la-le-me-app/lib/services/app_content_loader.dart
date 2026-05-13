import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/achievement.dart';

class AppContentLoader {
  static Map<String, dynamic>? _cachedData;
  static List<AchievementDef>? _achievementDefs;
  static List<Map<String, String>>? _dailyTips;

  static Future<void> initialize() async {
    if (_cachedData != null) return;
    final jsonStr = await rootBundle.loadString('assets/data/app_content.json');
    _cachedData = jsonDecode(jsonStr) as Map<String, dynamic>;
    _parseAchievements();
    _parseDailyTips();
    Achievement.definitionsOverride = _achievementDefs;
  }

  static void _parseAchievements() {
    final list = _cachedData!['achievements'] as List<dynamic>;
    _achievementDefs = list.map((item) {
      final m = item as Map<String, dynamic>;
      return AchievementDef.fromJson(m);
    }).toList();
  }

  static void _parseDailyTips() {
    final list = _cachedData!['daily_tips'] as List<dynamic>;
    _dailyTips = list.map((item) {
      final m = item as Map<String, dynamic>;
      return {
        'condition': m['condition'] as String,
        'text': m['text'] as String,
      };
    }).toList();
  }

  static List<Map<String, String>> get dailyTips {
    if (_dailyTips == null) {
      throw StateError('AppContentLoader 未初始化，请先调用 initialize()');
    }
    return _dailyTips!;
  }

  static String getDailyTipText(String condition) {
    try {
      return dailyTips.firstWhere((t) => t['condition'] == condition)['text']!;
    } catch (_) {
      return dailyTips.firstWhere((t) => t['condition'] == 'default')['text']!;
    }
  }
}
