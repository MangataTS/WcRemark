import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ranking.dart';
import '../services/settings_service.dart';
import '../services/database_service.dart';

final settingsFutureProvider = FutureProvider<AppSettings>((ref) async {
  return await AppSettings.load();
});

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier(super.settings);

  Future<void> update(AppSettings newSettings) async {
    await AppSettings.save(newSettings);
    state = newSettings;
  }
}

final settingsNotifierProvider = StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  final asyncSettings = ref.watch(settingsFutureProvider);
  return AppSettingsNotifier(asyncSettings.when(
    data: (s) => s,
    loading: () => AppSettings.defaults(),
    error: (_, __) => AppSettings.defaults(),
  ));
});

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          _buildSectionHeader('个人'),
          ListTile(
            leading: const Icon(Icons.person, color: Color(0xFF795548)),
            title: const Text('个人档案'),
            subtitle: const Text('昵称、头像、基本信息'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/settings/profile'),
          ),
          ListTile(
            leading: const Icon(Icons.star, color: Color(0xFFFFD700)),
            title: const Text('我的段位'),
            subtitle: FutureBuilder<String>(
              future: _getCurrentRankTitle(),
              builder: (_, snap) => Text(snap.data ?? '便秘青铜'),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showRankInfo(context),
          ),

          _buildSectionHeader('安全与隐私'),
          ListTile(
            leading: const Icon(Icons.fingerprint, color: Color(0xFF795548)),
            title: const Text('安全设置'),
            subtitle: const Text('应用锁、指纹解锁'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/settings/security'),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.visibility_off, color: Color(0xFF795548)),
            title: const Text('隐私模式'),
            subtitle: const Text('最近任务卡片不显示内容'),
            value: settings.privacyModeEnabled,
            onChanged: (v) => ref.read(settingsNotifierProvider.notifier).update(settings.copyWith(privacyModeEnabled: v)),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.hide_source, color: Color(0xFF795548)),
            title: const Text('匿名排行'),
            subtitle: const Text('在排行榜显示匿名昵称'),
            value: settings.anonymousRanking,
            onChanged: (v) => ref.read(settingsNotifierProvider.notifier).update(settings.copyWith(anonymousRanking: v)),
          ),

          _buildSectionHeader('AI'),
          ListTile(
            leading: const Icon(Icons.smart_toy, color: Color(0xFF795548)),
            title: const Text('AI 肠道顾问'),
            subtitle: const Text('配置大模型 API Key'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/settings/ai-config'),
          ),

          _buildSectionHeader('数据'),
          ListTile(
            leading: const Icon(Icons.storage, color: Color(0xFF795548)),
            title: const Text('数据管理'),
            subtitle: const Text('导出、恢复、同步'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/settings/data'),
          ),
          ListTile(
            leading: const Icon(Icons.cloud_upload, color: Color(0xFF795548)),
            title: const Text('云端备份'),
            subtitle: const Text('加密备份到云存储'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/settings/backup'),
          ),

          _buildSectionHeader('偏好'),
          ListTile(
            leading: const Icon(Icons.palette, color: Color(0xFF795548)),
            title: const Text('主题'),
            subtitle: Text(_themeLabel(settings.themeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemePicker(context, ref, settings),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.volume_up, color: Color(0xFF795548)),
            title: const Text('音效'),
            subtitle: Text(_soundLabel(settings.soundEffect)),
            value: settings.soundEffect != SoundEffect.none,
            onChanged: (v) {
              final newEffect = v ? SoundEffect.waterDrop : SoundEffect.none;
              ref.read(settingsNotifierProvider.notifier).update(settings.copyWith(soundEffect: newEffect));
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications, color: Color(0xFF795548)),
            title: const Text('晨间提醒'),
            subtitle: const Text('每日 07:30 提醒'),
            value: settings.morningReminderEnabled,
            onChanged: (v) => ref.read(settingsNotifierProvider.notifier).update(settings.copyWith(morningReminderEnabled: v)),
          ),

          _buildSectionHeader('关于'),
          const ListTile(
            leading: Icon(Icons.info_outline, color: Color(0xFF795548)),
            title: Text('版本'),
            subtitle: Text('v1.0.0 (1)'),
          ),
          ListTile(
            leading: const Icon(Icons.description, color: Color(0xFF795548)),
            title: const Text('隐私政策'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showPrivacyPolicy(context),
          ),
          ListTile(
            leading: const Icon(Icons.medical_services, color: Color(0xFF795548)),
            title: const Text('医疗免责声明'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showMedicalDisclaimer(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF999999)),
      ),
    );
  }

  Future<String> _getCurrentRankTitle() async {
    try {
      final score = int.tryParse(await DatabaseService.getSetting('season_score') ?? '0') ?? 0;
      return Rank.getRankNameByScore(score);
    } catch (_) {
      return '便秘青铜';
    }
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system: return '跟随系统';
      case ThemeMode.light: return '浅色模式';
      case ThemeMode.dark: return '深色模式';
    }
  }

  String _soundLabel(SoundEffect effect) {
    switch (effect) {
      case SoundEffect.none: return '关闭';
      case SoundEffect.waterDrop: return '水滴声 💧';
      case SoundEffect.flush: return '冲水声 🚿';
      case SoundEffect.fart: return '屁声 💨';
    }
  }

  void _showRankInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🏆 段位系统'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('通过记录如厕获取积分，积分决定段位：'),
            SizedBox(height: 12),
            _RankRow(rank: '🥉 便秘青铜', range: '0 - 99 分'),
            _RankRow(rank: '🥈 通畅白银', range: '100 - 499 分'),
            _RankRow(rank: '🥇 规律黄金', range: '500 - 1999 分'),
            _RankRow(rank: '💎 铂金肠王', range: '2000 - 4999 分'),
            _RankRow(rank: '👑 钻石所长', range: '5000 - 9999 分'),
            _RankRow(rank: '🌟 星耀肠道长', range: '10000 - 19999 分'),
            _RankRow(rank: '🏆 最强王者', range: '20000+ 分'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  void _showThemePicker(BuildContext context, WidgetRef ref, AppSettings settings) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('选择主题'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              ref.read(settingsNotifierProvider.notifier).update(settings.copyWith(themeMode: ThemeMode.system));
              Navigator.pop(ctx);
            },
            child: const Text('跟随系统'),
          ),
          SimpleDialogOption(
            onPressed: () {
              ref.read(settingsNotifierProvider.notifier).update(settings.copyWith(themeMode: ThemeMode.light));
              Navigator.pop(ctx);
            },
            child: const Text('浅色模式'),
          ),
          SimpleDialogOption(
            onPressed: () {
              ref.read(settingsNotifierProvider.notifier).update(settings.copyWith(themeMode: ThemeMode.dark));
              Navigator.pop(ctx);
            },
            child: const Text('深色模式'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🔒 隐私政策'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('数据本地优先', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('您的如厕记录、三围数据、AI分析报告等敏感信息仅存储在本地设备上，不会上传至"拉了么"服务器。'),
              SizedBox(height: 12),
              Text('服务器仅存储', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('• 匿名积分流水（不含原始记录）\n• 排行榜昵称（可匿名）\n• 设备标识（用于认证）'),
              SizedBox(height: 12),
              Text('API Key 安全', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('您的AI服务商API Key使用设备级加密存储（iOS Keychain/Android Keystore），分析请求直接从您的设备发送至大模型厂商。'),
              SizedBox(height: 12),
              Text('数据删除', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('您可以随时在「数据管理」中一键清空所有本地数据，清空后无法恢复。'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('我已了解'),
          ),
        ],
      ),
    );
  }

  void _showMedicalDisclaimer(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ 医疗免责声明'),
        content: const Text(
          '「拉了么」提供的所有健康分析、建议和评分仅供信息参考和娱乐目的，'
          '不能替代专业医疗诊断、治疗或建议。如果您有任何健康疑虑，特别是：\n\n'
          '• 持续便秘超过5天\n'
          '• 持续腹泻超过3天\n'
          '• 发现血便或黑便\n'
          '• 严重腹痛伴随排便异常\n\n'
          '请立即咨询专业医疗人员。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('我已了解'),
          ),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final String rank;
  final String range;
  const _RankRow({required this.rank, required this.range});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(rank, style: const TextStyle(fontSize: 14)),
          Text(range, style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
        ],
      ),
    );
  }
}