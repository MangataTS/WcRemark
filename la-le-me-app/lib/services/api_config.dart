class ApiConfig {
  static const String _devBaseUrl = 'http://10.0.2.2:8080';
  static const String _stagingBaseUrl = 'https://staging-api.laleme.app';
  static const String _prodBaseUrl = 'https://api.laleme.app';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static String get baseUrl {
    const env = String.fromEnvironment('ENV', defaultValue: 'dev');
    switch (env) {
      case 'prod': return _prodBaseUrl;
      case 'staging': return _stagingBaseUrl;
      default: return _devBaseUrl;
    }
  }

  static String get wsBaseUrl {
    const env = String.fromEnvironment('ENV', defaultValue: 'dev');
    switch (env) {
      case 'prod': return 'wss://api.laleme.app/ws';
      case 'staging': return 'wss://staging-api.laleme.app/ws';
      default: return 'ws://10.0.2.2:8080/ws';
    }
  }

  static String get envLabel {
    const env = String.fromEnvironment('ENV', defaultValue: 'dev');
    switch (env) {
      case 'prod': return '生产环境';
      case 'staging': return '测试环境';
      default: return '开发环境';
    }
  }

  static bool get isDev {
    const env = String.fromEnvironment('ENV', defaultValue: 'dev');
    return env == 'dev';
  }
}