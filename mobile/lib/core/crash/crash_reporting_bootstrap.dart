import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../firebase/firebase_bootstrap.dart';
import '../firebase/firebase_options.dart';
import '../../features/voice_hub/data/services/voice_room_debug_log.dart';
import 'sentry_bootstrap.dart';

/// Yakalanmamış hatalar — Crashlytics + Sentry (hazır).
abstract final class CrashReportingBootstrap {
  static var _ready = false;

  static bool get isReady => _ready;

  static Future<void> init() async {
    if (_ready) return;

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      VoiceRoomDebugLog.recordFlutterError(
        details.exception,
        details.stack,
      );
      _recordFlutterError(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      VoiceRoomDebugLog.recordPlatformError(error, stack);
      _recordError(error, stack, fatal: true);
      return true;
    };

    await SentryBootstrap.init();
    _ready = true;
  }

  static void _recordFlutterError(FlutterErrorDetails details) {
    final ex = details.exception;
    final stack = details.stack;
    _recordError(ex, stack, fatal: false);
  }

  static void _recordError(
    Object error,
    StackTrace? stack, {
    required bool fatal,
  }) {
    if (kDebugMode) {
      debugPrint('CrashReporting: $error\n$stack');
    }

    if (FirebaseBootstrap.isReady && DefaultFirebaseOptions.enabled) {
      unawaited(
        FirebaseCrashlytics.instance.recordError(
          error,
          stack,
          fatal: fatal,
        ),
      );
    }

    SentryBootstrap.captureException(error, stackTrace: stack);
  }

  static void log(String message) {
    if (FirebaseBootstrap.isReady && DefaultFirebaseOptions.enabled) {
      FirebaseCrashlytics.instance.log(message);
    }
    SentryBootstrap.addBreadcrumb(message);
  }

  static Future<void> setUserId(String? userId) async {
    if (userId == null || userId.isEmpty) return;
    if (FirebaseBootstrap.isReady && DefaultFirebaseOptions.enabled) {
      await FirebaseCrashlytics.instance.setUserIdentifier(userId);
    }
    await SentryBootstrap.setUserId(userId);
  }
}
