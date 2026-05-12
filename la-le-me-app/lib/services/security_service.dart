import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class SecurityService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> isBiometricAvailable() async {
    try {
      return await _auth.canCheckBiometrics &&
          await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  static String biometricLabel(List<BiometricType> types) {
    if (types.contains(BiometricType.face)) return 'Face ID';
    if (types.contains(BiometricType.iris)) return '虹膜识别';
    if (types.contains(BiometricType.fingerprint)) return '指纹识别';
    if (types.contains(BiometricType.strong)) return '生物识别';
    if (types.contains(BiometricType.weak)) return '生物识别';
    return '生物识别';
  }

  static Future<bool> authenticate({
    required String reason,
    bool stickyAuth = false,
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: stickyAuth,
          biometricOnly: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  static const _channel = MethodChannel('com.laleime/privacy');

  static Future<void> setPrivacyMode(bool enabled) async {
    try {
      await _channel.invokeMethod('setPrivacyMode', enabled);
    } catch (_) {}
  }
}