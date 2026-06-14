import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/navigation/wallet_navigation.dart';
import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../../profile/presentation/providers/profile_providers.dart';
import '../../providers/chat_room_providers.dart';
import '../../sheets/voice_youtube_song_sheet.dart';
import '../../theme/voice_room_tokens.dart';
import '../../utils/voice_room_permissions.dart';
import '../premium/voice_glass.dart';

/// Sağ kaydırma paneli — kapalı ok, açık kurallar / yetkiler / jeton / yasaklı kelimeler.
class VoiceRoomRightSlidePanel extends ConsumerStatefulWidget {
  const VoiceRoomRightSlidePanel({
    super.key,
    required this.room,
    required this.perms,
    required this.isOwner,
  });

  final VoiceRoomEntity room;
  final VoiceRoomPermissions perms;
  final bool isOwner;

  @override
  ConsumerState<VoiceRoomRightSlidePanel> createState() =>
      _VoiceRoomRightSlidePanelState();
}

class _VoiceRoomRightSlidePanelState
    extends ConsumerState<VoiceRoomRightSlidePanel> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final panelW = (MediaQuery.sizeOf(context).width * 0.58).clamp(220.0, 280.0);
    final bottom = MediaQuery.paddingOf(context).bottom;

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
                    child: Column(
                      children: [
                        Expanded(
                          child: _PanelBody(
                            room: widget.room,
                            perms: widget.perms,
                            isOwner: widget.isOwner,
                            onClose: () => setState(() => _expanded = false),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: VoiceRoomTokens.neonPurple,
                              minimumSize: const Size.fromHeight(42),
                            ),
                            onPressed: () => showVoiceYoutubeSongSheet(
                              context,
                              ref,
                              room: widget.room,
                            ),
                            icon: const Icon(Icons.music_note_rounded, size: 18),
                            label: const Text(
                              'Ücretli Şarkı İste',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
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

class _PanelBody extends ConsumerStatefulWidget {
  const _PanelBody({
    required this.room,
    required this.perms,
    required this.isOwner,
    required this.onClose,
  });

  final VoiceRoomEntity room;
  final VoiceRoomPermissions perms;
  final bool isOwner;
  final VoidCallback onClose;

  @override
  ConsumerState<_PanelBody> createState() => _PanelBodyState();
}

class _PanelBodyState extends ConsumerState<_PanelBody> {
  var _loadingWords = true;
  List<String> _words = const [];

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    final words = await ref
        .read(voiceRoomLiveProvider(widget.room.stableSessionKey).notifier)
        .fetchBannedWords();
    if (mounted) {
      setState(() {
        _words = words;
        _loadingWords = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final coins = ref.watch(coinBalanceProvider).valueOrNull ?? 0;
    final coinLabel = NumberFormat.decimalPattern('tr').format(coins);
    final rules = (widget.room.rulesTr ?? widget.room.descTr ?? '').trim();
    final canModerate = widget.perms.canModerate || widget.isOwner;

    return VoiceGlass(
      borderRadius: 16,
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      child: ListView(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Oda Paneli',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: widget.onClose,
                icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white54),
              ),
            ],
          ),
          _section('Kurallar', Icons.article_outlined),
          Text(
            rules.isNotEmpty
                ? rules
                : 'Saygılı olun, spam yapmayın. Yetkililerin uyarılarına uyun.',
            style: TextStyle(
              fontSize: 10,
              height: 1.35,
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
          const SizedBox(height: 12),
          _section('Yetkiler', Icons.admin_panel_settings_outlined),
          ..._roleTags(),
          const SizedBox(height: 12),
          _section('Jeton Yükle', Icons.monetization_on_rounded),
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Bakiye: $coinLabel',
              style: const TextStyle(fontSize: 11, color: Colors.white),
            ),
            trailing: FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                backgroundColor: VoiceRoomTokens.neonPurple,
              ),
              onPressed: () => openJetonStore(context, ref: ref),
              child: const Text('Yükle', style: TextStyle(fontSize: 10)),
            ),
          ),
          if (canModerate) ...[
            const SizedBox(height: 8),
            _section('Yasaklı Kelimeler', Icons.block_rounded),
            if (_loadingWords)
              const Padding(
                padding: EdgeInsets.all(8),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (_words.isEmpty)
              Text(
                'Liste boş',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              )
            else
              ..._words.take(8).map(
                    (w) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• $w',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                  ),
          ],
        ],
      ),
    );
  }

  Widget _section(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: VoiceRoomTokens.gold),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 11,
              color: VoiceRoomTokens.gold,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _roleTags() {
    const tags = [
      ('~', 'Founder', Color(0xFFFFD700)),
      ('%', 'SuperAdmin', Color(0xFFFF4FD8)),
      ('&', 'SOP', Color(0xFFFF6B35)),
      ('@', 'OP', Color(0xFF25F4EE)),
      ('+', 'Voice', Color(0xFF3B82F6)),
    ];
    return tags
        .map(
          (t) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: t.$3.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    t.$1,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      color: t.$3,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  t.$2,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }
}
