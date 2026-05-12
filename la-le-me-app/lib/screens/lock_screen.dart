import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/security_service.dart';
import '../screens/settings_page.dart' show settingsNotifierProvider;

class AppLockWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const AppLockWrapper({super.key, required this.child});

  @override
  ConsumerState<AppLockWrapper> createState() => _AppLockWrapperState();
}

class _AppLockWrapperState extends ConsumerState<AppLockWrapper>
    with WidgetsBindingObserver {
  bool _isLocked = false;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkLock();
    } else if (state == AppLifecycleState.paused) {
      final settings = ref.read(settingsNotifierProvider);
      if (settings.appLockEnabled) {
        _isLocked = true;
      }
    }
  }

  void _checkLock() {
    final settings = ref.read(settingsNotifierProvider);
    if (settings.appLockEnabled && _isLocked && !_isAuthenticating) {
      _authenticate();
    }
  }

  Future<void> _authenticate() async {
    _isAuthenticating = true;
    setState(() {});

    final success = await SecurityService.authenticate(
      reason: '请验证身份以解锁拉了么',
      stickyAuth: true,
    );

    if (mounted) {
      _isAuthenticating = false;
      if (success) {
        _isLocked = false;
        setState(() {});
      } else {
        _isLocked = true;
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider);

    if (!settings.appLockEnabled) {
      return widget.child;
    }

    if (_isLocked) {
      return _LockScreen(onUnlock: _authenticate);
    }

    return widget.child;
  }
}

class _LockScreen extends StatelessWidget {
  final VoidCallback onUnlock;

  const _LockScreen({required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF795548), Color(0xFFA1887F)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🚽', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                const Text(
                  '拉了么',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '应用已锁定',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 48),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.fingerprint,
                      size: 48,
                      color: Colors.white,
                    ),
                    onPressed: onUnlock,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '轻触解锁',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}