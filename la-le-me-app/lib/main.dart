import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/main_shell.dart';
import 'screens/settings_page.dart';
import 'screens/stats_pages.dart';
import 'screens/record_detail_page.dart';
import 'screens/profile_page.dart';
import 'screens/ai_config_page.dart';
import 'screens/security_page.dart';
import 'screens/data_management_page.dart';
import 'screens/backup_page.dart';
import 'screens/server_config_page.dart';
import 'screens/achievement_page.dart';
import 'screens/timeline_page.dart';
import 'screens/lock_screen.dart';
import 'services/theme_service.dart';
import 'services/security_service.dart';
import 'services/app_content_loader.dart';
import 'services/database_factory_stub.dart'
    if (dart.library.io) 'services/database_factory_io.dart'
    if (dart.library.html) 'services/database_factory_web.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_CN', null);
  await initDatabaseFactory();
  await AppContentLoader.initialize();
  runApp(const ProviderScope(child: LaLeMeApp()));
}

class LaLeMeApp extends ConsumerStatefulWidget {
  const LaLeMeApp({super.key});

  @override
  ConsumerState<LaLeMeApp> createState() => _LaLeMeAppState();
}

class _LaLeMeAppState extends ConsumerState<LaLeMeApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initPrivacyMode());
  }

  void _initPrivacyMode() {
    final settings = ref.read(settingsNotifierProvider);
    if (settings.privacyModeEnabled) {
      SecurityService.setPrivacyMode(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider);

    return AppLockWrapper(
      child: MaterialApp(
        title: '拉了么',
        debugShowCheckedModeBanner: false,
        theme: ThemeService.getTheme(ThemeMode.light),
        darkTheme: ThemeService.getTheme(ThemeMode.dark,
            useOledDark: settings.useOledDark),
        themeMode: settings.themeMode,
        initialRoute: '/',
        routes: {
          '/': (ctx) => const MainShell(),
          '/stats/weekly': (ctx) => const WeeklyStatsPage(),
          '/stats/monthly': (ctx) => const MonthlyStatsPage(),
          '/stats/yearly': (ctx) => const YearlyStatsPage(),
          '/record/detail': (ctx) => const RecordDetailPage(),
          '/settings/profile': (ctx) => const ProfilePage(),
          '/settings/ai-config': (ctx) => const AIConfigPage(),
          '/settings/security': (ctx) => const SecurityPage(),
          '/settings/data': (ctx) => const DataManagementPage(),
          '/settings/backup': (ctx) => const BackupPage(),
          '/settings/server': (ctx) => const ServerConfigPage(),
          '/stats/achievements': (ctx) => const AchievementPage(),
          '/stats/timeline': (ctx) => const TimelinePage(),
        },
      ),
    );
  }
}
