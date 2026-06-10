import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/chat_room_providers.dart';

/// Uygulama tamamen kapanınca audio_service temizliği.
class VoiceRoomMusicLifecycleHost extends ConsumerStatefulWidget {
  const VoiceRoomMusicLifecycleHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<VoiceRoomMusicLifecycleHost> createState() =>
      _VoiceRoomMusicLifecycleHostState();
}

class _VoiceRoomMusicLifecycleHostState
    extends ConsumerState<VoiceRoomMusicLifecycleHost>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      ref.read(voiceRoomDjPlayerProvider).shutdown();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
