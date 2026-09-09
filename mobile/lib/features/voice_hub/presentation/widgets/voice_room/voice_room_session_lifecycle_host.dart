import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/chat_room_providers.dart';
import '../../providers/voice_room_session_registry.dart';

/// Uygulama arka plana geçince heartbeat durur; uzun süre sonra koltuk boşaltılır.
class VoiceRoomSessionLifecycleHost extends ConsumerStatefulWidget {
  const VoiceRoomSessionLifecycleHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<VoiceRoomSessionLifecycleHost> createState() =>
      _VoiceRoomSessionLifecycleHostState();
}

class _VoiceRoomSessionLifecycleHostState
    extends ConsumerState<VoiceRoomSessionLifecycleHost>
    with WidgetsBindingObserver {
  static const _backgroundSeatRelease = Duration(seconds: 45);
  Timer? _backgroundTimer;
  var _backgrounded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _backgroundTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  String? _activeLiveKey() {
    final key = ref.read(voiceRoomActiveLiveKeyProvider)?.trim() ?? '';
    return key.isEmpty ? null : key;
  }

  void _cancelBackgroundTimer() {
    _backgroundTimer?.cancel();
    _backgroundTimer = null;
  }

  void _onBackgrounded() {
    if (_backgrounded) return;
    _backgrounded = true;
    final liveKey = _activeLiveKey();
    if (liveKey == null) return;
    _cancelBackgroundTimer();
    _backgroundTimer = Timer(_backgroundSeatRelease, () {
      if (!_backgrounded) return;
      final key = _activeLiveKey();
      if (key == null) return;
      unawaited(
        ref.read(voiceRoomLiveProvider(key).notifier).leaveRoomSession(
              source: 'app_background',
              awaitBackend: true,
            ),
      );
    });
  }

  void _onForegrounded() {
    if (!_backgrounded) return;
    _backgrounded = false;
    _cancelBackgroundTimer();
    final liveKey = _activeLiveKey();
    if (liveKey == null) return;
    final ctrl = ref.read(voiceRoomLiveProvider(liveKey).notifier);
    unawaited(ctrl.resyncAfterSseReconnect());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        _onBackgrounded();
      case AppLifecycleState.resumed:
        _onForegrounded();
      case AppLifecycleState.detached:
        _cancelBackgroundTimer();
        final liveKey = _activeLiveKey();
        if (liveKey != null) {
          unawaited(
            ref.read(voiceRoomLiveProvider(liveKey).notifier).leaveRoomSession(
                  source: 'app_detached',
                  awaitBackend: true,
                  force: true,
                ),
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
