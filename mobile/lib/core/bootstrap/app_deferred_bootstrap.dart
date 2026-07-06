import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../../features/fortune/data/services/rewarded_ad_service.dart';
import '../../features/voice_hub/data/services/voice_room_debug_log.dart';
import '../crash/crash_reporting_bootstrap.dart';
import '../firebase/firebase_bootstrap.dart';
import '../network/api.dart';
import '../onesignal/onesignal_bootstrap.dart';
import 'app_startup_log.dart';
import 'startup_perf.dart';

/// runApp sonrası ağır init — ilk kareyi bloklamaz.
void scheduleDeferredAppBootstrap() {
  SchedulerBinding.instance.scheduleFrameCallback((_) {
    unawaited(_run());
  });
}

Future<void> _run() async {
  await Future<void>.delayed(StartupPerf.deferredSdkDelay);
  unawaited(_probeApiHealth());
  await _initPushAndCrashReporting();
  await FirebaseBootstrap.runDeferredTasks();
  try {
    await RewardedAdService.ensureInitialized();
    RewardedAdService.instance.preload();
  } catch (e) {
    debugPrint('AdMob deferred init failed: $e');
  }
}

/// OneSignal + Firebase + Sentry — soğuk açılışta runApp öncesi beklenmez.
Future<void> _initPushAndCrashReporting() async {
  try {
    await OneSignalBootstrap.init();
    AppStartupLog.log('OneSignal init done (deferred)');
  } catch (e) {
    debugPrint('OneSignal deferred init failed: $e');
  }
  try {
    await FirebaseBootstrap.init();
    AppStartupLog.log('Firebase init done (deferred)');
  } catch (e) {
    debugPrint('Firebase deferred init failed: $e');
  }
  try {
    await CrashReportingBootstrap.init();
    AppStartupLog.log('Crash reporting init done (deferred)');
  } catch (e) {
    debugPrint('Crash reporting deferred init failed: $e');
  }
}

Future<void> _probeApiHealth() async {
  try {
    final ok = await Api.healthy();
    debugPrint('API health: ${ok ? 'ok' : 'unreachable'}');
  } catch (e) {
    debugPrint('API health probe failed: $e');
  }
}
