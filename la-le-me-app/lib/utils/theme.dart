import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF795548);
  static const Color primaryLight = Color(0xFFD4A574);
  static const Color primaryDark = Color(0xFF4E342E);
  static const Color accent = Color(0xFFA1887F);
  static const Color surface = Color(0xFFF7F7F7);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF999999);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  static const Map<int, Color> bristolColors = {
    1: Color(0xFFE57373),
    2: Color(0xFFFFB74D),
    3: Color(0xFFFFD54F),
    4: Color(0xFF81C784),
    5: Color(0xFF64B5F6),
    6: Color(0xFF9575CD),
    7: Color(0xFF90A4AE),
  };
}

class AppStyles {
  static const TextStyle heading = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static TextStyle score(double value) {
    return TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.bold,
      color: value >= 80
          ? AppColors.success
          : value >= 60
              ? AppColors.warning
              : AppColors.error,
    );
  }
}

class AppDimens {
  static const double cardRadius = 16;
  static const double buttonRadius = 12;
  static const double cardPadding = 16;
  static const double pagePadding = 20;
  static const double listItemHeight = 56;
  static const double miniCardWidth = 130;
  static const double miniCardHeight = 100;
}

class AppStrings {
  static const String appName = '拉了么';
  static const String appSlogan = '隐私优先的生理健康记录';

  static const Map<String, String> rankIcons = {
    '便秘青铜': '🥉',
    '通畅白银': '🥈',
    '规律黄金': '🥇',
    '铂金肠王': '💎',
    '钻石所长': '👑',
    '星耀肠道长': '🌟',
    '最强王者': '🏆',
  };

  static String getWeekdayName(int weekday) {
    const days = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return days[weekday - 1];
  }

  static String getTimePeriod(int hour) {
    if (hour >= 5 && hour < 9) return '早晨';
    if (hour >= 9 && hour < 12) return '上午';
    if (hour >= 12 && hour < 14) return '中午';
    if (hour >= 14 && hour < 18) return '下午';
    if (hour >= 18 && hour < 21) return '晚上';
    return '凌晨';
  }
}