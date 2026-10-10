import '../onesignal/onesignal_bootstrap.dart';
import '../onesignal/onesignal_config.dart';
import 'push_config.dart';

/// Hangi push kanalının aktif olduğu (çift bildirim / çift kayıt önleme).
abstract final class PushDelivery {
  static bool get usesOneSignal =>
      !PushConfig.useFcmOnly && OneSignalConfig.enabled;

  static bool get oneSignalActive =>
      usesOneSignal && OneSignalBootstrap.isReady;
}
