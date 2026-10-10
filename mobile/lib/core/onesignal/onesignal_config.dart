import '../push/push_config.dart';

/// OneSignal uygulama kimliği — Dashboard → Settings → Keys & IDs.
abstract final class OneSignalConfig {
  /// Varsayılan App ID (override: `--dart-define=ONESIGNAL_APP_ID=...`).
  static const String defaultAppId = '578518ed-7b16-46a9-a1e6-7692d3ba55d8';

  static const String appId = String.fromEnvironment(
    'ONESIGNAL_APP_ID',
    defaultValue: defaultAppId,
  );

  /// FCM-only modda SDK başlatılmaz (`PushConfig.useFcmOnly`).
  static bool get enabled =>
      !PushConfig.useFcmOnly && appId.trim().isNotEmpty;
}
