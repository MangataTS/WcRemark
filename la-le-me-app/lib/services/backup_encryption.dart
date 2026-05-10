import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';

class BackupEncryption {
  static String encryptSimple(String jsonData, String password) {
    final combined = '$password:$jsonData';
    final bytes = utf8.encode(combined);
    return base64Encode(bytes);
  }

  static String decryptSimple(String base64Data, String password) {
    final decoded = utf8.decode(base64Decode(base64Data));
    final colonIndex = decoded.indexOf(':');
    if (colonIndex == -1) {
      throw const FormatException('Invalid backup format');
    }
    final storedPassword = decoded.substring(0, colonIndex);
    if (storedPassword != password) {
      throw const FormatException('密码错误');
    }
    return decoded.substring(colonIndex + 1);
  }

  static String computeSha256(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return 'sha256:$digest';
  }

  static bool verifySha256(String data, String expectedHash) {
    final actual = computeSha256(data);
    return actual == expectedHash;
  }
}

class BackupService {
  static Future<Map<String, dynamic>> exportToMap() async {
    final db = await DatabaseService.database;

    final records = await db.query('toilet_records', orderBy: 'timestamp ASC');
    final profile = await db.query('user_profile', limit: 1);
    final settings = await db.query('app_settings');
    final aiReports = await db.query('ai_reports');
    final seasonHistory = await db.query('season_history');
    final achievements = await db.query('achievements');

    final coreData = jsonEncode({
      'records': records,
      'profile': profile.isNotEmpty ? profile.first : null,
    });

    return {
      'version': '1.0',
      'export_date': DateTime.now().toIso8601String(),
      'app_version': '1.0.0',
      'checksum': BackupEncryption.computeSha256(coreData),
      'metadata': {
        'record_count': records.length,
        'profile_present': profile.isNotEmpty,
      },
      'records': records,
      'profile': profile.isNotEmpty ? profile.first : null,
      'settings': settings,
      'ai_reports': aiReports,
      'season_history': seasonHistory,
      'achievements': achievements,
    };
  }

  static Future<String> exportJson({String? password}) async {
    final data = await exportToMap();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

    if (password != null && password.isNotEmpty) {
      return BackupEncryption.encryptSimple(jsonStr, password);
    }
    return jsonStr;
  }

  static Future<bool> importFromJson(
    String content, {
    String? password,
    bool overwrite = false,
  }) async {
    try {
      String jsonStr;
      if (password != null && password.isNotEmpty) {
        jsonStr = BackupEncryption.decryptSimple(content, password);
      } else {
        jsonStr = content;
      }

      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      if (data['version'] != '1.0') {
        throw FormatException('Unsupported backup version: ${data['version']}');
      }

      final db = await DatabaseService.database;

      if (overwrite) {
        await db.delete('toilet_records');
        await db.delete('ai_reports');
        await db.delete('app_settings');
        await db.delete('achievements');
      }

      if (data['records'] != null) {
        for (final record in data['records'] as List) {
          await db.insert('toilet_records', record as Map<String, dynamic>,
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      if (data['ai_reports'] != null) {
        for (final report in data['ai_reports'] as List) {
          await db.insert('ai_reports', report as Map<String, dynamic>,
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      if (data['settings'] != null) {
        for (final setting in data['settings'] as List) {
          await db.insert('app_settings', setting as Map<String, dynamic>,
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      if (data['achievements'] != null) {
        for (final achievement in data['achievements'] as List) {
          await db.insert('achievements', achievement as Map<String, dynamic>,
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      if (data['profile'] != null) {
        await db.update('user_profile', data['profile'] as Map<String, dynamic>,
            where: 'id = ?', whereArgs: [1]);
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}