import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../video/presentation/room_video_controller.dart';
import '../../providers/chat_room_providers.dart';
import '../../providers/room_fragment_providers.dart';
import '../../theme/voice_room_tokens.dart';
import 'voice_room_music_queue_mini_card.dart';
import 'voice_room_youtube_embed_host.dart';

/// Müzik isteği videosu: koltukların hemen altında, sağ köşede küçük kare
/// pencere (≈ 2×2 koltuk). Video tam ekran arka plan yerine bunun içinde
/// oynar; sohbet/koltuklar donmaz ve örtülmez.
///
/// * Kutuya dokununca "Durdur" / "Kapat" seçenekleri çıkar.
/// * Kutunun altında sırada bekleyen istekler (varsa) listelenir.
/// * Sayfada TEK örnek olmalı (tek WebView).
class VoiceRoomMusicMiniVideo extends ConsumerWidget {
  const VoiceRoomMusicMiniVideo({
    super.key,
    required this.liveKey,
    required this.canControlMusic,
    required this.canStopMusic,
  });

  final String liveKey;
  final bool canControlMusic;
  final bool canStopMusic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (liveKey.isEmpty) return const SizedBox.shrink();
    final show = ref.watch(
      roomVideoControllerProvider(liveKey).select((s) => s.showsVideo),
    );
    if (!show) return const SizedBox.shrink();

    final dj = ref.watch(voiceRoomMusicSliceProvider(liveKey));
    final title = ref.watch(
      roomVideoControllerProvider(liveKey).select((s) => s.title),
    );
    final width = MediaQuery.sizeOf(context).width;
    final cell = ((width - 52) / 4).clamp(38.0, 54.0);
    final side = cell * 2 + 12;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Align(
        alignment: Alignment.centerRight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _showMenu(context, ref),
              child: Container(
                width: side,
                height: side,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: VoiceRoomTokens.neonPurple.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                  color: Colors.black,
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // WebView dokunuşu yutmasın: dokunma kutuya aittir.
                    IgnorePointer(
                      child: VoiceRoomYoutubeEmbedHost(
                        roomKey: liveKey,
                        fillBackground: true,
                      ),
                    ),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.more_horiz_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (title != null && title.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: SizedBox(
                  width: side,
                  child: Text(
                    title.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 4),
            VoiceRoomMusicQueueMiniCard(
              dj: dj,
              liveKey: liveKey,
              canControlMusic: canControlMusic,
              canStopMusic: canStopMusic,
            ),
          ],
        ),
      ),
    );
  }

  void _showMenu(BuildContext context, WidgetRef ref) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1B1030),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.stop_circle_outlined,
                  color: Colors.white),
              title:
                  const Text('Durdur', style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                'Çalan şarkıyı ve sırayı durdurur',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              onTap: () async {
                Navigator.of(sheetCtx).pop();
                final ctrl = ref.read(voiceRoomLiveProvider(liveKey).notifier);
                final err = await ctrl.stopMusic();
                if (err != null) {
                  messenger?.showSnackBar(SnackBar(content: Text(err)));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.close_rounded, color: Colors.white),
              title: const Text('Kapat', style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                'Videoyu yalnızca senin ekranında kapatır',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                unawaited(
                  ref
                      .read(voiceRoomLiveProvider(liveKey).notifier)
                      .closeMusicPlayer(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
