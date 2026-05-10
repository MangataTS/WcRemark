import 'package:flutter/material.dart';
import '../services/ai_service.dart';

class AIConfigPage extends StatefulWidget {
  const AIConfigPage({super.key});

  @override
  State<AIConfigPage> createState() => _AIConfigPageState();
}

class _AIConfigPageState extends State<AIConfigPage> {
  String _selectedProvider = 'DeepSeek';
  final _apiKeyController = TextEditingController();
  final _baseUrlController = TextEditingController();
  String _selectedModel = 'deepseek-chat';
  double _temperature = 0.3;
  String _analysisFrequency = 'manual';
  bool _obscureApiKey = true;
  bool _isTesting = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await AIService.getConfig();
    if (mounted) {
      setState(() {
        _selectedProvider = config.provider;
        _apiKeyController.text = config.apiKey;
        _baseUrlController.text = config.baseUrl;
        _selectedModel = config.model;
        _temperature = config.temperature;
        _analysisFrequency = config.analysisFrequency;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('AI 肠道顾问')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('服务商', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AIProvider.providers.map((p) {
              return ChoiceChip(
                label: Text('${p.icon} ${p.name}'),
                selected: _selectedProvider == p.name,
                onSelected: (_) {
                  setState(() {
                    _selectedProvider = p.name;
                    _baseUrlController.text = p.baseUrl;
                    if (p.models.isNotEmpty) {
                      _selectedModel = p.models.first;
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          const Text('API Key', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _apiKeyController,
            obscureText: _obscureApiKey,
            decoration: InputDecoration(
              hintText: 'sk-xxxxxxxx...',
              helperText: '您的 API Key 仅存储在本地，不会上传到我们的服务器',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscureApiKey ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscureApiKey = !_obscureApiKey),
              ),
            ),
          ),
          const SizedBox(height: 8),

          if (_selectedProvider == '自定义') ...[
            const Text('Base URL', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _baseUrlController,
              decoration: const InputDecoration(
                labelText: 'Base URL',
                hintText: 'https://your-api.com/v1',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          const Text('模型', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedModel,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: _getCurrentProviderModels().map((m) =>
              DropdownMenuItem(value: m, child: Text(m)),
            ).toList(),
            onChanged: (v) => setState(() => _selectedModel = v ?? _selectedModel),
          ),
          const SizedBox(height: 20),

          const Text('Temperature', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          Slider(
            value: _temperature,
            min: 0,
            max: 1,
            divisions: 10,
            label: _temperature.toStringAsFixed(1),
            onChanged: (v) => setState(() => _temperature = v),
          ),
          const SizedBox(height: 12),

          const Text('分析频率', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _analysisFrequency,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'manual', child: Text('手动触发')),
              DropdownMenuItem(value: 'daily', child: Text('每日晚9点')),
              DropdownMenuItem(value: 'per_record', child: Text('每次记录后')),
            ],
            onChanged: (v) => setState(() => _analysisFrequency = v ?? 'manual'),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isTesting ? null : _testConnection,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF795548),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isTesting
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('测试连接'),
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF795548),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('保存配置'),
            ),
          ),
          const SizedBox(height: 16),

          Card(
            color: Colors.amber.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, size: 16, color: Color(0xFFF57C00)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '⚠️ 安全提示：您的 API Key 使用设备级加密存储（iOS Keychain / Android Keystore）。'
                      '分析请求直接从您的设备发送至大模型厂商，「拉了么」服务器不会触碰您的数据。',
                      style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getCurrentProviderModels() {
    final provider = AIProvider.providers.firstWhere(
      (p) => p.name == _selectedProvider,
      orElse: () => AIProvider.providers.first,
    );
    return provider.models.isNotEmpty ? provider.models : [_selectedModel];
  }

  Future<void> _testConnection() async {
    if (_apiKeyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先输入 API Key')),
      );
      return;
    }

    setState(() => _isTesting = true);
    try {
      final config = AIConfig(
        provider: _selectedProvider,
        apiKey: _apiKeyController.text.trim(),
        baseUrl: _baseUrlController.text.trim(),
        model: _selectedModel,
        temperature: _temperature,
        analysisFrequency: _analysisFrequency,
      );
      await AIService.saveConfig(config);

      final success = await AIService.testConnection();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? '连接测试成功 ✅' : '连接失败，请检查 API Key 和网络设置 ❌')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('连接失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  Future<void> _save() async {
    final config = AIConfig(
      provider: _selectedProvider,
      apiKey: _apiKeyController.text,
      baseUrl: _baseUrlController.text,
      model: _selectedModel,
      temperature: _temperature,
      analysisFrequency: _analysisFrequency,
    );
    await AIService.saveConfig(config);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('配置已保存 ✅')),
      );
      Navigator.pop(context);
    }
  }
}