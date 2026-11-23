import 'dart:io';

/// Where the Brief mock server lives.
///
/// On a physical phone, pass your Mac's address:
///   flutter run --dart-define=API_HOST=$(ipconfig getifaddr en0)
class AppConfig {
  static const _hostOverride = String.fromEnvironment('API_HOST');
  static const port = int.fromEnvironment('API_PORT', defaultValue: 8081);

  /// Android emulators reach the host machine via 10.0.2.2.
  static String get host => _hostOverride.isNotEmpty
      ? _hostOverride
      : (Platform.isAndroid ? '10.0.2.2' : 'localhost');

  static String get baseUrl => 'http://$host:$port';
}
