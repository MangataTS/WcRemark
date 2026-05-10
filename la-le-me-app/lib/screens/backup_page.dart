import 'package:flutter/material.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  final List<Map<String, String>> _backups = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('云端备份')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              color: const Color(0xFFE8F5E9),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_done, color: Color(0xFF2E7D32), size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('安全保障', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1B5E20))),
                          const SizedBox(height: 4),
                          Text(
                            '备份文件使用 AES-256-GCM 加密\n只有您知道密码，服务器无法解密',
                            style: TextStyle(fontSize: 12, color: Colors.green.shade800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                onPressed: _createBackup,
                icon: const Icon(Icons.cloud_upload),
                label: const Text('创建备份'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF795548),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('备份历史', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 8),
          if (_backups.isEmpty)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_off, size: 64, color: Color(0xFFBDBDBD)),
                    SizedBox(height: 16),
                    Text('暂无备份', style: TextStyle(fontSize: 16, color: Color(0xFF999999))),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _backups.length,
                itemBuilder: (context, index) {
                  final backup = _backups[index];
                  return ListTile(
                    leading: const Icon(Icons.backup, color: Color(0xFF795548)),
                    title: Text(backup['date'] ?? ''),
                    subtitle: Text(backup['size'] ?? ''),
                    trailing: PopupMenuButton(
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 'download', child: Text('下载')),
                        const PopupMenuItem(value: 'delete', child: Text('删除', style: TextStyle(color: Colors.red))),
                      ],
                      onSelected: (v) {
                        if (v == 'download') _downloadBackup(index);
                        if (v == 'delete') _deleteBackup(index);
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _createBackup() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('备份创建功能开发中')),
    );
  }

  void _downloadBackup(int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('备份下载功能开发中')),
    );
  }

  void _deleteBackup(int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('备份删除功能开发中')),
    );
  }
}