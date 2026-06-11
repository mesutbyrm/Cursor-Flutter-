import 'package:flutter/foundation.dart';

/// Soğuk açılış — splash, auth guard, overlay teşhisi.
abstract final class AppStartupLog {
  static const _tag = '[AppStartup]';

  static void log(String message) {
    debugPrint('$_tag $message');
  }

  static void route(String from, String to, {String? reason}) {
    final extra = reason == null ? '' : ' ($reason)';
    log('route $from → $to$extra');
  }

  static void auth({
    required bool loading,
    required bool hasUser,
    required bool hasError,
  }) {
    log(
      'auth loading=$loading user=$hasUser error=$hasError',
    );
  }

  static void overlay({
    required String action,
    required int popupRoutesPopped,
    required bool canStillPop,
  }) {
    log(
      'overlay $action popped=$popupRoutesPopped canPop=$canStillPop',
    );
  }
}
