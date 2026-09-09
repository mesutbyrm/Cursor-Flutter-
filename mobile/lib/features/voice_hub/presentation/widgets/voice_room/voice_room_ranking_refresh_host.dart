import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/voice_room_ranking_provider.dart';
import '../../providers/voice_room_session_registry.dart';

/// Aktif sesli oda oturumunda sıralama listesini periyodik yeniler.
class VoiceRoomRankingRefreshHost extends ConsumerStatefulWidget {
  const VoiceRoomRankingRefreshHost({super.key, required this.child});

  final Widget child;

  static const refreshInterval = Duration(minutes: 5);

  @override
  ConsumerState<VoiceRoomRankingRefreshHost> createState() =>
      _VoiceRoomRankingRefreshHostState();
}

class _VoiceRoomRankingRefreshHostState
    extends ConsumerState<VoiceRoomRankingRefreshHost> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(VoiceRoomRankingRefreshHost.refreshInterval, (_) {
      _refreshIfInRoom();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _refreshIfInRoom() {
    final key = ref.read(voiceRoomActiveLiveKeyProvider)?.trim() ?? '';
    if (key.isEmpty) return;
    unawaited(ref.read(voiceRoomRankingProvider.notifier).refresh());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
