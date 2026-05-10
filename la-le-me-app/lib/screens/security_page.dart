import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_page.dart' show settingsNotifierProvider;

class SecurityPage extends ConsumerStatefulWidget {
  const SecurityPage({super.key});

  @override
  ConsumerState<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends ConsumerState<SecurityPage> {
  bool _isCheckingBiometric = true;
  bool _deviceSupported = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    setState(() => _isCheckingBiometric = true);
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        setState(() {
          _deviceSupported = true;
          _isCheckingBiometric = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isCheckingBiometric = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('安全设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_isCheckingBiometric)
            const Center(child: CircularProgressIndicator())
          else ...[
            Card(
              child: SwitchListTile(
                secondary: const Icon(Icons.fingerprint, color: Color(0xFF795548)),
                title: const Text('应用锁'),
                subtitle: Text(_deviceSupported
                    ? '使用 Face ID / 指纹解锁应用'
                    : '此设备不支持生物识别'),
                value: settings.appLockEnabled,
                onChanged: _deviceSupported ? (v) {
                  ref.read(settingsNotifierProvider.notifier).update(
                    settings.copyWith(appLockEnabled: v),
                  );
                } : null,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: SwitchListTile(
                secondary: const Icon(Icons.visibility_off, color: Color(0xFF795548)),
                title: const Text('隐私模式'),
                subtitle: const Text('最近任务卡片不显示内容'),
                value: settings.privacyModeEnabled,
                onChanged: (v) {
                  ref.read(settingsNotifierProvider.notifier).update(
                    settings.copyWith(privacyModeEnabled: v),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: SwitchListTile(
                secondary: const Icon(Icons.hide_source, color: Color(0xFF795548)),
                title: const Text('匿名排行'),
                subtitle: const Text('在排行榜中使用匿名昵称'),
                value: settings.anonymousRanking,
                onChanged: (v) {
                  ref.read(settingsNotifierProvider.notifier).update(
                    settings.copyWith(anonymousRanking: v),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Color(0xFFF57C00)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '启用应用锁后，每次打开「拉了么」都需要通过生物识别验证身份。'
                        '如果生物识别失败，可使用设备密码解锁。\n\n'
                        '隐私模式开启后，在最近任务列表中将隐藏应用内容。',
                        style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}