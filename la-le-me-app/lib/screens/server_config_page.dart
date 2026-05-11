import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/database_service.dart';

class ServerConfigPage extends StatefulWidget {
  const ServerConfigPage({super.key});

  @override
  State<ServerConfigPage> createState() => _ServerConfigPageState();
}

class _ServerConfigPageState extends State<ServerConfigPage> {
  final _serverUrlController = TextEditingController();
  bool _isLoading = true;
  bool _isChecking = false;
  String _statusText = '';
  Color _statusColor = Colors.grey;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final savedUrl = await DatabaseService.getSetting('custom_server_url');
    if (mounted) {
      setState(() {
        _serverUrlController.text = savedUrl ?? 'http://10.0.2.2:8080';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveConfig() async {
    final url = _serverUrlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入服务器地址')),
      );
      return;
    }

    await DatabaseService.setSetting('custom_server_url', url);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('服务器地址已保存 ✅')),
      );
    }
  }

  Future<void> _checkHealth() async {
    final url = _serverUrlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先输入服务器地址')),
      );
      return;
    }

    setState(() {
      _isChecking = true;
      _statusText = '正在检测...';
      _statusColor = Colors.orange;
      _isConnected = false;
    });

    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));

      final healthUrl = '$url/health';
      final response = await dio.get(healthUrl);

      if (response.statusCode == 200) {
        setState(() {
          _statusText = '🟢 服务器运行正常';
          _statusColor = Colors.green;
          _isConnected = true;
        });
      } else {
        setState(() {
          _statusText = '🟡 服务器响应异常 (${response.statusCode})';
          _statusColor = Colors.orange;
          _isConnected = false;
        });
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        setState(() {
          _statusText = '🔴 连接超时，请检查服务器地址';
          _statusColor = Colors.red;
          _isConnected = false;
        });
      } else if (e.type == DioExceptionType.connectionError) {
        setState(() {
          _statusText = '🔴 无法连接到服务器';
          _statusColor = Colors.red;
          _isConnected = false;
        });
      } else {
        setState(() {
          _statusText = '🔴 连接失败: ${e.message}';
          _statusColor = Colors.red;
          _isConnected = false;
        });
      }
    } catch (e) {
      setState(() {
        _statusText = '🔴 检测失败: $e';
        _statusColor = Colors.red;
        _isConnected = false;
      });
    } finally {
      setState(() => _isChecking = false);
    }
  }

  Future<void> _connectAndVerify() async {
    await _saveConfig();
    await _checkHealth();

    if (mounted && _isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已连接到服务器: ${_serverUrlController.text.trim()}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('服务器配置'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '后端服务器地址',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              '填写「拉了么」后端服务的地址，用于积分上报、排行榜同步和数据备份',
              style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _serverUrlController,
              decoration: InputDecoration(
                hintText: 'http://your-server:8080',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.dns),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _serverUrlController.clear(),
                ),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: _statusColor.withValues(alpha: 0.1),
                border: Border.all(color: _statusColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        _isConnected ? Icons.check_circle : Icons.info_outline,
                        color: _statusColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _statusText.isEmpty ? '尚未检测' : _statusText,
                          style: TextStyle(
                            fontSize: 14,
                            color: _statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_statusText.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '地址: ${_serverUrlController.text.trim()}/health',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isChecking ? null : _checkHealth,
                    icon: _isChecking
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.favorite_border),
                    label: const Text('健康检查'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF795548),
                      side: const BorderSide(color: Color(0xFF795548)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isChecking ? null : _connectAndVerify,
                    icon: const Icon(Icons.wifi_find),
                    label: const Text('连接服务器'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF795548),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Card(
              color: Color(0xFFE3F2FD),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Color(0xFF1565C0)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '连接成功后，积分数据将自动上报到服务器，排行榜数据也将实时同步。'
                        '原始如厕记录仍仅存储在本地。',
                        style: TextStyle(fontSize: 12, color: Color(0xFF1565C0)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
