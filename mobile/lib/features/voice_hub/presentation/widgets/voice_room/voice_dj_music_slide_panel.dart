import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme_colors.dart';
import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../domain/entities/music_queue_item.dart';
import '../../providers/chat_room_providers.dart';
import '../../sheets/voice_room_dj_sheet.dart';
import '../../sheets/voice_youtube_song_sheet.dart';
import '../../theme/voice_room_tokens.dart';
import '../../utils/voice_music_access.dart';
import '../../utils/voice_room_permissions.dart';
import '../premium/voice_glass.dart';

/// Sağ ‹ ok — DJ & müzik paneli (yalnızca DJ / oda sahibi / admin).
class VoiceDjMusicSlidePanel extends ConsumerStatefulWidget {
  const VoiceDjMusicSlidePanel({
    super.key,
    required this.room,
    required this.live,
    required this.perms,
    required this.isOwner,
    required this.isDj,
  });

  final VoiceRoomEntity room;
  final VoiceRoomLiveState live;
  final VoiceRoomPermissions perms;
  final bool isOwner;
  final bool isDj;

  @override
  ConsumerState<VoiceDjMusicSlidePanel> createState() =>
      _VoiceDjMusicSlidePanelState();
}

class _VoiceDjMusicSlidePanelState extends ConsumerState<VoiceDjMusicSlidePanel> {
  var _expanded = false;
  var _busy = false;

  bool get _visible => VoiceMusicAccess.canShowDjMusicPanel(
        perms: widget.perms,
        isDj: widget.isDj,
      );

  Future<void> _run(Future<String?> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    final err = await action();
    if (mounted) setState(() => _busy = false);
    if (!mounted || err == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    final panelW = (MediaQuery.sizeOf(context).width * 0.58).clamp(220.0, 280.0);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final dj = widget.live.dj;
    final np = dj.nowPlaying;
    final ctrl = ref.read(voiceRoomLiveProvider(widget.room.liveKey).notifier);

    return Positioned(
      top: MediaQuery.paddingOf(context).top + 88,
      right: 0,
      bottom: bottom + 220,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.centerRight,
            child: _expanded
                ? SizedBox(
                    width: panelW,
                    child: VoiceGlass(
                      borderRadius: 16,
                      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.headphones_rounded,
                                size: 16,
                                color: VoiceRoomTokens.neonPurple,
                              ),
                              const SizedBox(width: 6),
                              const Expanded(
                                child: Text(
                                  'DJ & Müzik',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                onPressed: () => setState(() => _expanded = false),
                                icon: const Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                          if (np != null) ...[
                            _NowPlayingCard(item: np, playing: dj.playing),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _MiniBtn(
                                    icon: dj.playing
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    label: dj.playing ? 'Duraklat' : 'Devam',
                                    onTap: _busy
                                        ? null
                                        : () => _run(
                                              () => dj.playing
                                                  ? ctrl.pauseMusic()
                                                  : ctrl.resumeMusic(),
                                            ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: _MiniBtn(
                                    icon: Icons.skip_next_rounded,
                                    label: 'Geç',
                                    onTap: _busy
                                        ? null
                                        : () => _run(ctrl.skipMusic),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: _MiniBtn(
                                    icon: Icons.stop_rounded,
                                    label: 'Durdur',
                                    color: AppThemeColors.liveRed,
                                    onTap: _busy
                                        ? null
                                        : () => _run(ctrl.stopMusic),
                                  ),
                                ),
                              ],
                            ),
                          ] else
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'Şu an çalan parça yok',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          const SizedBox(height: 10),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF7B2FF7),
                              minimumSize: const Size.fromHeight(40),
                            ),
                            onPressed: () {
                              setState(() => _expanded = false);
                              showVoiceMusicControlHub(
                                context,
                                ref,
                                room: widget.room,
                                perms: widget.perms,
                                isOwner: widget.isOwner,
                              );
                            },
                            icon: const Icon(Icons.library_music_rounded, size: 18),
                            label: const Text(
                              'Müzik Aç',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(38),
                              foregroundColor: VoiceRoomTokens.gold,
                              side: BorderSide(
                                color: VoiceRoomTokens.gold.withValues(alpha: 0.5),
                              ),
                            ),
                            onPressed: () {
                              setState(() => _expanded = false);
                              showVoiceRoomDjSheet(
                                context,
                                ref,
                                room: widget.room,
                                live: widget.live,
                                perms: widget.perms,
                                isOwner: widget.isOwner,
                              );
                            },
                            icon: const Icon(Icons.group_rounded, size: 16),
                            label: Text(
                              'DJ Yönet (${dj.djCount}/5)',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          if (dj.musicQueue.length > 1) ...[
                            const SizedBox(height: 10),
                            Text(
                              'Kuyruk: ${dj.musicQueue.length - 1} şarkı',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white.withValues(alpha: 0.65),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : const SizedBox(width: 0, height: 0),
          ),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              width: 10,
              height: 40,
              margin: const EdgeInsets.only(top: 96),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(8),
                ),
                border: Border.all(
                  color: VoiceRoomTokens.neonPurple.withValues(alpha: 0.35),
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                _expanded
                    ? Icons.chevron_right_rounded
                    : Icons.chevron_left_rounded,
                color: Colors.white.withValues(alpha: 0.85),
                size: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NowPlayingCard extends StatelessWidget {
  const _NowPlayingCard({required this.item, required this.playing});

  final MusicQueueItem item;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    final thumb = item.thumbUrl?.trim();
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(
          color: VoiceRoomTokens.neonPurple.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          if (thumb != null && thumb.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: thumb,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: VoiceRoomTokens.neonPurple.withValues(alpha: 0.25),
              ),
              child: const Icon(Icons.music_note_rounded, color: Colors.white70),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playing ? 'Çalıyor' : 'Duraklatıldı',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: playing
                        ? const Color(0xFF22C55E)
                        : Colors.white.withValues(alpha: 0.55),
                  ),
                ),
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: Colors.white,
                  ),
                ),
                if (item.artistLine.trim().isNotEmpty)
                  Text(
                    item.artistLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBtn extends StatelessWidget {
  const _MiniBtn({
    required this.icon,
    required this.label,
    this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? VoiceRoomTokens.neonPurple;
    return Material(
      color: c.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              Icon(icon, size: 16, color: c),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
