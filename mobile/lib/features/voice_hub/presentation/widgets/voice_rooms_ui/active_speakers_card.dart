import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/images/canlifal_network_image.dart';
import '../../../../../core/providers/auth_selectors.dart';
import '../../../../profile/presentation/providers/profile_providers.dart';
import 'voice_rooms_mock_data.dart';
import 'voice_rooms_ui_tokens.dart';

/// En aktif konuşmacılar — oda sahipleri (dinleyici ve oda sayısı canlı veriden).
class ActiveSpeakersCard extends StatelessWidget {
  const ActiveSpeakersCard({super.key, required this.speakers});

  final List<ActiveSpeakerItem> speakers;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(VoiceRoomsUiTokens.radiusLg),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A1252), Color(0xFF150A2B)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.workspace_premium_rounded,
                  color: VoiceRoomsUiTokens.gold, size: 22),
              SizedBox(width: 8),
              Text(
                'En Aktif Konuşmacılar',
                style: TextStyle(
                  color: VoiceRoomsUiTokens.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final s in speakers) _SpeakerRow(speaker: s),
        ],
      ),
    );
  }
}

class _SpeakerRow extends ConsumerStatefulWidget {
  const _SpeakerRow({required this.speaker});

  final ActiveSpeakerItem speaker;

  @override
  ConsumerState<_SpeakerRow> createState() => _SpeakerRowState();
}

class _SpeakerRowState extends ConsumerState<_SpeakerRow> {
  var _followed = false;
  var _busy = false;

  ActiveSpeakerItem get speaker => widget.speaker;

  Future<void> _follow() async {
    final id = speaker.userId;
    if (id == null || _busy || _followed) return;
    setState(() => _busy = true);
    try {
      await ref.read(profileRepositoryProvider).follow(id);
      if (mounted) setState(() => _followed = true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Takip edilemedi, tekrar dene.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Color get _rank => switch (speaker.rank) {
        1 => VoiceRoomsUiTokens.gold,
        2 => VoiceRoomsUiTokens.purpleGlow,
        3 => VoiceRoomsUiTokens.blue,
        4 => VoiceRoomsUiTokens.onlineGreen,
        _ => VoiceRoomsUiTokens.magenta,
      };

  @override
  Widget build(BuildContext context) {
    final url = speaker.avatarUrl?.trim();
    final myId = ref.watch(currentUserIdProvider);
    final canFollow = speaker.userId != null && speaker.userId != myId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, color: _rank),
            child: Text(
              '${speaker.rank}',
              style: TextStyle(
                color: speaker.rank == 1 ? Colors.black : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: speaker.avatarColor,
              border: Border.all(color: _rank.withValues(alpha: 0.8), width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            child: url != null && url.isNotEmpty
                ? CanlifalNetworkImage(
                    url: url,
                    width: 42,
                    height: 42,
                    fit: BoxFit.cover,
                    thumbnailWidth: 96,
                    fadeIn: false,
                    errorWidget: _initial(),
                  )
                : _initial(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  speaker.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: VoiceRoomsUiTokens.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  speaker.onlineLabel ?? '${speaker.listeners} dinleyici',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: VoiceRoomsUiTokens.textMuted,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          if (canFollow)
            OutlinedButton(
              onPressed: _followed || _busy ? null : _follow,
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                minimumSize: const Size(0, 30),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                foregroundColor: VoiceRoomsUiTokens.purpleGlow,
                side: BorderSide(
                  color: VoiceRoomsUiTokens.purpleGlow.withValues(alpha: 0.7),
                ),
              ),
              child: Text(
                _followed ? 'Takipte' : 'Takip Et',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            )
          else
            const Icon(
              Icons.graphic_eq_rounded,
              color: VoiceRoomsUiTokens.onlineGreen,
              size: 22,
            ),
        ],
      ),
    );
  }

  Widget _initial() => Text(
        speaker.name.characters.first.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      );
}
