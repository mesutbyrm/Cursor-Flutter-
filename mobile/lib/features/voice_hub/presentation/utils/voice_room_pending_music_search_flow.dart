import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/entities/chat_room_dj_state.dart';
import '../../music/presentation/widgets/music_search_picker_sheet.dart';
import '../providers/chat_room_providers.dart';
import '../sheets/music_mode_picker_sheet.dart';
import 'voice_music_access.dart';
import 'voice_music_submit.dart';
import 'voice_room_error_display.dart';

/// `pendingMusicSearchQuery` SSE/aksiyonundan müzik seçim sheet akışı.
Future<void> runVoiceRoomPendingMusicSearchFlow({
  required BuildContext context,
  required WidgetRef ref,
  required String liveRoomKey,
  required String query,
  required bool skipPayment,
  required ChatRoomDjState dj,
}) async {
  final ctrl = ref.read(voiceRoomLiveProvider(liveRoomKey).notifier);
  ctrl.clearPendingMusicSearch();
  await showMusicSearchPickerSheet(
    context,
    ref,
    query: query,
    onSelected: (hit) async {
      if (!context.mounted) return;
      final withVideo = await showMusicModePickerSheet(
        context,
        audioCost: VoiceMusicAccess.audioRequestCost(dj),
        videoCost: VoiceMusicAccess.videoRequestCost(dj),
        songTitle: hit.title,
      );
      if (!context.mounted || withVideo == null) return;
      final messenger = ScaffoldMessenger.of(context);
      final songTitle = hit.title;
      deferVoiceMusicSubmit(
        submit: () => ctrl.submitSelectedSong(
          hit,
          withVideo: withVideo,
          skipPayment: skipPayment,
        ),
        onComplete: (err) {
          if (!context.mounted) return;
          if (err != null) {
            showJetonAwareError(context, err, ref: ref);
          } else {
            final liveNow = ref.read(voiceRoomLiveProvider(liveRoomKey));
            final queuedOnly = liveNow.dj.playing &&
                liveNow.dj.nowPlaying?.videoIdField != hit.videoId;
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  queuedOnly
                      ? '«$songTitle» kuyruğa eklendi'
                      : '«$songTitle» çalmaya başladı',
                ),
              ),
            );
          }
        },
      );
    },
  );
}
