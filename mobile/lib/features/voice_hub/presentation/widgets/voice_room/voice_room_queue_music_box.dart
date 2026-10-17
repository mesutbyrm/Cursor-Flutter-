import 'dart:async';

import 'package:canlifal_social/core/images/canlifal_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../video/presentation/room_video_controller.dart';
import '../../../video/presentation/widgets/youtube_video_background.dart';
import '../../providers/chat_room_providers.dart';

/// Sağ paneldeki müzik kısmından istenen şarkı çalarken son iki koltuğun
/// yerini alan dikdörtgen kutu. Videolu istekte video kutunun içinde oynar;
/// sesli istekte kapak + başlık görünür (ses gizli oynatıcıdan gelir).
/// Yetkili DJ / oda sahibi kutuya dokununca Durdur / Devam / Sonraki / Kapat.
class VoiceRoomQueueMusicBox extends ConsumerWidget {
  const VoiceRoomQueueMusicBox({
    super.key,
    required this.roomKey,
    required this.canControl,
  });

  final String roomKey;
  /// Yetkili DJ / oda sahibi / admin.
  final bool canControl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dj = ref.watch(voiceRoomLiveProvider(roomKey).select((s) => s.dj));
    final np = dj.nowPlaying;
    if (np == null) return const SizedBox.shrink();
    final video = ref.watch(roomVideoControllerProvider(roomKey));
    final showsVideo = video.showsVideo;
    final screenW = MediaQuery.sizeOf(context).width.clamp(280.0, 900.0);
    final height = ((screenW - 12) / 4 * 0.86).clamp(70.0, 140.0);
    final by = np.requestedBy?.displayName.trim();
    final thumb = np.thumbUrl?.trim();

    return GestureDetector(
      onTap: canControl ? () => _openControls(context, ref) : null,
      child: Container(
        width: double.infinity,
        height: height,
        margin: const EdgeInsets.only(top: 6, left: 4, right: 4),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.black,
          border: Border.all(color: Colors.white24),
          boxShadow: const [
            BoxShadow(color: Color(0x668E2DE2), blurRadius: 14),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (!showsVideo && thumb != null && thumb.isNotEmpty)
              CanlifalNetworkImage(url: thumb, fit: BoxFit.cover),
            // Videolu istekte video kutuda; sesli istekte gizli 1×1 oynatıcı.
            if (video.hasActiveVideo && showsVideo)
              YoutubeVideoBackground(roomKey: roomKey, fillBackground: true)
            else if (video.hasActiveVideo)
              Positioned(
                left: 0,
                top: 0,
                width: 1,
                height: 1,
                child: YoutubeVideoBackground(roomKey: roomKey),
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xCC000000)],
                  stops: [0.45, 1],
                ),
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '🎶 ${np.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (by != null && by.isNotEmpty)
                    Text(
                      'isteyen @$by',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                ],
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  dj.playing
                      ? (showsVideo ? '🎬 Çalıyor' : '🎧 Çalıyor')
                      : '⏸ Durdu',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openControls(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(voiceRoomLiveProvider(roomKey).notifier);
    final playing = ref.read(voiceRoomLiveProvider(roomKey)).dj.playing;
    void toast(String? err, String ok) {
      final m = ScaffoldMessenger.maybeOf(context);
      m?.hideCurrentSnackBar();
      m?.showSnackBar(SnackBar(content: Text(err ?? ok)));
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF15102A),
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                playing ? Icons.pause_circle_rounded : Icons.play_circle_rounded,
                color: Colors.white,
              ),
              title: Text(
                playing ? 'Durdur' : 'Devam et',
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () async {
                Navigator.of(ctx).pop();
                final err =
                    playing ? await ctrl.pauseMusic() : await ctrl.resumeMusic();
                toast(err, playing ? 'Müzik durduruldu' : 'Müzik devam ediyor');
              },
            ),
            ListTile(
              leading: const Icon(Icons.skip_next_rounded, color: Colors.white),
              title: const Text('Sonraki şarkı',
                  style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.of(ctx).pop();
                final err = await ctrl.skipMusic();
                toast(err, 'Sıradaki şarkıya geçildi');
              },
            ),
            ListTile(
              leading: const Icon(Icons.close_rounded, color: Colors.redAccent),
              title: const Text('Kapat',
                  style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.of(ctx).pop();
                unawaited(ctrl.closeMusicPlayer());
              },
            ),
          ],
        ),
      ),
    );
  }
}
