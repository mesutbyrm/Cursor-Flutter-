import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../music/presentation/widgets/room_music_queue_sheet.dart';
import '../providers/chat_room_providers.dart';
import '../sheets/voice_youtube_song_sheet.dart';
import '../utils/voice_music_access.dart';
import '../utils/voice_room_permissions.dart';
import '../widgets/voice_room/voice_room_premium_music_card.dart';
import '../widgets/voice_room/voice_room_music_queue_section.dart';
import '../widgets/voice_room/voice_room_music_request_flash.dart';

/// Web parity müzik — !istek, kuyruk, premium müzik kartı.
class VoiceRoomBasicMusicSection extends ConsumerWidget {
  const VoiceRoomBasicMusicSection({
    super.key,
    required this.room,
    required this.liveKey,
    required this.live,
    required this.istekController,
    required this.onSendIstek,
    required this.canControlMusic,
    required this.perms,
  });

  final VoiceRoomEntity room;
  final String liveKey;
  final VoiceRoomLiveState live;
  final TextEditingController istekController;
  final VoidCallback onSendIstek;
  final bool canControlMusic;
  final VoiceRoomPermissions perms;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dj = live.dj;
    final musicSession = ref.watch(voiceRoomMusicSessionProvider);
    final showMiniPlayer = (dj.playing || dj.nowPlaying != null || dj.musicQueue.isNotEmpty) &&
        !musicSession.dismissed &&
        !musicSession.userDismissedPlayer;
    final user = ref.watch(authControllerProvider).valueOrNull;
    final canCloseMusic = VoiceMusicAccess.canStopMusic(
      user: user,
      perms: perms,
      nowPlaying: dj.nowPlaying,
    );
    final jeton = ref.watch(
      walletBalancesProvider.select((a) => a.valueOrNull?.jeton ?? 0),
    );
    final canRequest = VoiceMusicAccess.canRequestSongs(
      dj: dj,
      perms: perms,
      jetonBalance: jeton,
    );
    final isDj = user != null &&
        (room.djUserIds.contains(user.id) ||
            dj.djUsers.any((u) => u.id == user.id));
    final showDjHub = VoiceMusicAccess.canShowDjMusicPanel(
      perms: perms,
      isDj: isDj,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        VoiceRoomMusicRequestFlash(message: live.musicRequestFlash),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: istekController,
                  enabled: canRequest || dj.musicEnabled,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSendIstek(),
                  decoration: InputDecoration(
                    hintText: '!istek Sanatçı - Şarkı',
                    isDense: true,
                    prefixIcon: const Icon(Icons.music_note_rounded, size: 20),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search_rounded),
                      tooltip: 'Şarkı ara',
                      onPressed: canRequest || dj.musicEnabled
                          ? () => showVoiceYoutubeSongSheet(
                                context,
                                ref,
                                room: room,
                                perms: perms,
                              )
                          : null,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: canRequest || dj.musicEnabled ? onSendIstek : null,
                child: const Text('!istek'),
              ),
            ],
          ),
        ),
        if (showDjHub)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => showVoiceMusicControlHub(
                  context,
                  ref,
                  room: room,
                  perms: perms,
                ),
                icon: const Icon(Icons.headphones_rounded, size: 18),
                label: const Text('DJ paneli'),
              ),
            ),
          ),
        if (dj.musicQueue.isNotEmpty || dj.nowPlaying != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: VoiceRoomMusicQueueSection(
              dj: dj,
              coinCost: dj.musicRequestCost,
              maxItems: 3,
            ),
          ),
        if (showMiniPlayer)
          VoiceRoomPremiumMusicCard(
            room: room,
            liveKey: liveKey,
            dj: dj,
            canClose: canCloseMusic,
            listenerCount: live.onlineCountFor(room),
            likeCount: live.musicLikeCount,
            onQueueTap: () => showRoomMusicQueueSheet(
              context,
              ref,
              liveKey: liveKey,
              dj: dj,
              canControlMusic: canControlMusic,
              canStopMusic: canCloseMusic,
            ),
          ),
        if (dj.musicQueue.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: OutlinedButton.icon(
              onPressed: () => showRoomMusicQueueSheet(
                context,
                ref,
                liveKey: liveKey,
                dj: dj,
                canControlMusic: canControlMusic,
                canStopMusic: canCloseMusic,
              ),
              icon: const Icon(Icons.queue_music_rounded),
              label: Text('Kuyruk (${dj.musicQueue.length})'),
            ),
          ),
      ],
    );
  }
}
