import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';

class DataManagementPage extends StatelessWidget {
  const DataManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('数据管理')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.save_alt, color: Color(0xFF795548)),
            title: const Text('导出本地备份'),
            subtitle: const Text('导出为 JSON 文件，可分享到其他应用'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _exportBackup(context),
          ),
          ListTile(
            leading: const Icon(Icons.restore, color: Color(0xFF795548)),
            title: const Text('从备份恢复'),
            subtitle: const Text('选择备份文件并恢复数据'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _restoreFromBackup(context),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.cloud_sync, color: Color(0xFF795548)),
            title: const Text('云端同步（仅积分与排名）'),
            subtitle: const Text('原始记录不上传，保护隐私'),
            value: false,
            onChanged: (v) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('云端同步功能开发中')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.file_upload, color: Color(0xFF795548)),
            title: const Text('从其他APP导入'),
            subtitle: const Text('支持 CSV 格式'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('导入功能开发中')),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('清空所有数据', style: TextStyle(color: Colors.red)),
            subtitle: const Text('此操作不可恢复'),
            onTap: () => _confirmClearAll(context),
          ),
        ],
      ),
    );
  }

  Future<void> _exportBackup(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正在导出数据...')),
      );

      final db = await DatabaseService.database;
      final records = await db.query('toilet_records', orderBy: 'timestamp ASC');
      final profile = await db.query('user_profile', limit: 1);
      final settings = await db.query('app_settings');
      final aiReports = await db.query('ai_reports');
      final seasonHistory = await db.query('season_history');

      final backupData = {
        'version': '1.0',
        'export_date': DateTime.now().toIso8601String(),
        'app_version': '1.0.0',
        'metadata': {
          'record_count': records.length,
          'profile_present': profile.isNotEmpty,
        },
        'records': records,
        'profile': profile.isNotEmpty ? profile.first : null,
        'settings': settings,
        'ai_reports': aiReports,
        'season_history': seasonHistory,
      };

      final jsonStr = const JsonEncoder.withIndent('  ').convert(backupData);
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'la_le_me_backup_$timestamp.json';

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/backups/$fileName');
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonStr);

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('备份成功！共 ${records.length} 条记录'),
            action: SnackBarAction(
              label: '分享',
              onPressed: () {
                Share.shareXFiles(
                  [XFile(file.path)],
                  text: '拉了么备份文件',
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }

  void _restoreFromBackup(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('备份恢复功能开发中，将支持加密 JSON 文件导入')),
    );
  }

  void _confirmClearAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ 危险操作'),
        content: const Text('您确定要清空所有本地数据吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showSecondConfirm(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('继续'),
          ),
        ],
      ),
    );
  }

  void _showSecondConfirm(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('二次确认'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('请输入「确认清空」以继续'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: '确认清空',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.dispose();
              Navigator.pop(ctx);
            },
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (controller.text == '确认清空') {
                await _clearAllData(context);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('输入不正确，操作已取消')),
                  );
                }
              }
              controller.dispose();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData(BuildContext context) async {
    try {
      await DatabaseService.clearAllData();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('所有数据已清空')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('清空失败: $e')),
        );
      }
    }
  }
}