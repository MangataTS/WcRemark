import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/security_service.dart';
import 'settings_page.dart' show settingsNotifierProvider;

class SecurityPage extends ConsumerStatefulWidget {
  const SecurityPage({super.key});

  @override
  ConsumerState<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends ConsumerState<SecurityPage> {
  bool _isChecking = true;
  bool _deviceSupported = false;
  String _biometricLabel = '生物识别';

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    setState(() => _isChecking = true);
    final available = await SecurityService.isBiometricAvailable();
    if (available) {
      final types = await SecurityService.getAvailableBiometrics();
      if (mounted) {
        setState(() {
          _deviceSupported = true;
          _biometricLabel = SecurityService.biometricLabel(types);
          _isChecking = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _deviceSupported = false;
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _testFingerprint() async {
    final success = await SecurityService.authenticate(
      reason: '测试$_biometricLabel功能',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '$_biometricLabel验证成功 ✅' : '$_biometricLabel验证失败 ❌'),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
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
          if (_isChecking)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            Card(
              child: SwitchListTile(
                secondary: const Icon(Icons.fingerprint, color: Color(0xFF795548)),
                title: const Text('应用锁'),
                subtitle: Text(_deviceSupported
                    ? '使用 $_biometricLabel 解锁应用'
                    : '此设备不支持生物识别'),
                value: settings.appLockEnabled && _deviceSupported,
                onChanged: _deviceSupported
                    ? (v) {
                        ref.read(settingsNotifierProvider.notifier).update(
                              settings.copyWith(appLockEnabled: v),
                            );
                      }
                    : null,
              ),
            ),
            if (_deviceSupported)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _testFingerprint,
                    icon: const Icon(Icons.fingerprint, size: 18),
                    label: Text('测试 $_biometricLabel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF795548),
                      side: const BorderSide(color: Color(0xFF795548)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
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
                  SecurityService.setPrivacyMode(v);
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
                        _deviceSupported
                            ? '启用应用锁后，每次打开「拉了么」都需要通过 $_biometricLabel 验证身份。'
                                '如果 $_biometricLabel 失败，可使用设备密码解锁。\n\n'
                                '隐私模式开启后，在最近任务列表中将隐藏应用内容，防止他人窥视。\n\n'
                                '匿名排行开启后，在排行榜中将显示"匿名肠友"代替您的昵称。'
                            : '此设备不支持生物识别功能。\n\n'
                                '隐私模式开启后，在最近任务列表中将隐藏应用内容，防止他人窥视。\n\n'
                                '匿名排行开启后，在排行榜中将显示"匿名肠友"代替您的昵称。',
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