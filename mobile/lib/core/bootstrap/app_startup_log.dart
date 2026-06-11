import 'package:flutter/foundation.dart';

/// Soğuk açılış — splash, auth guard, overlay teşhisi.
abstract final class AppStartupLog {
  static const _tag = '[AppStartup]';

  static void log(String message) {
    debugPrint('$_tag $message');
  }

  static void appStart() => log('APP_START');

  static void authStart() => log('AUTH_START');

  static void authFinish({
    required bool hasUser,
    bool error = false,
  }) {
    log('AUTH_FINISH user=$hasUser error=$error');
  }

  static void homeScreenRender(String path) {
    log('HOME_SCREEN_RENDER path=$path');
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

  static void overlayShow({
    required String source,
    String? detail,
  }) {
    log('OVERLAY_SHOW source=$source${detail == null ? '' : ' $detail'}');
  }

  static void overlayHide({
    required String reason,
    int popped = 0,
    bool? canStillPop,
    String? note,
  }) {
  final tail = [
      if (popped > 0) 'popped=$popped',
      if (canStillPop != null) 'canPop=$canStillPop',
      if (note != null) note,
    ].join(' ');
    log('OVERLAY_HIDE reason=$reason${tail.isEmpty ? '' : ' $tail'}');
  }

  @Deprecated('Use overlayHide')
  static void overlay({
    required String action,
    required int popupRoutesPopped,
    required bool canStillPop,
  }) {
    overlayHide(
      reason: action,
      popped: popupRoutesPopped,
      canStillPop: canStillPop,
    );
  }
}
