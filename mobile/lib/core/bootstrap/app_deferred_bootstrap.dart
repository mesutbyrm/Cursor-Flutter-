import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../../features/fortune/data/services/rewarded_ad_service.dart';
import '../firebase/firebase_bootstrap.dart';
import 'startup_perf.dart';

/// runApp sonrası ağır init — ilk kareyi bloklamaz.
void scheduleDeferredAppBootstrap() {
  SchedulerBinding.instance.scheduleFrameCallback((_) {
    unawaited(_run());
  });
}

Future<void> _run() async {
  await Future<void>.delayed(StartupPerf.deferredSdkDelay);
  await FirebaseBootstrap.runDeferredTasks();
  try {
    await RewardedAdService.ensureInitialized();
    RewardedAdService.instance.preload();
  } catch (e) {
    debugPrint('AdMob deferred init failed: $e');
  }
}
