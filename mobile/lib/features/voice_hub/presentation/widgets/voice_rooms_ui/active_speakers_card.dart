import 'package:flutter/material.dart';

import '../../../../../core/images/canlifal_network_image.dart';
import 'voice_rooms_fx.dart';
import 'voice_rooms_mock_data.dart';
import 'voice_rooms_svg_icons.dart';
import 'voice_rooms_ui_tokens.dart';

class ActiveSpeakersCard extends StatelessWidget {
  const ActiveSpeakersCard({super.key, required this.speakers});

  final List<ActiveSpeakerItem> speakers;

  @override
  Widget build(BuildContext context) {
    return VoiceGlassFxContainer(
      radius: VoiceRoomsUiTokens.radiusLg,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      glowColor: VoiceRoomsUiTokens.purpleGlow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'En Aktif Konuşmacılar',
                  style: TextStyle(
                    color: VoiceRoomsUiTokens.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const VoiceLottieAccent(size: 20),
            ],
          ),
          const SizedBox(height: 10),
          ...speakers.map(_SpeakerRow.new),
          const SizedBox(height: 6),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Tümünü Gör',
                      style: TextStyle(
                        color: VoiceRoomsUiTokens.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    VoiceRoomsSvgIcons.icon(
                      'chevron_right',
                      size: 14,
                      color: VoiceRoomsUiTokens.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeakerRow extends StatelessWidget {
  const _SpeakerRow(this.speaker);

  final ActiveSpeakerItem speaker;

  Color get _rankColor => switch (speaker.rank) {
        1 => VoiceRoomsUiTokens.gold,
        2 => VoiceRoomsUiTokens.silver,
        _ => VoiceRoomsUiTokens.bronze,
      };

  @override
  Widget build(BuildContext context) {
    final isTop = speaker.rank <= 2;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: _rankColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: _rankColor, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              '${speaker.rank}',
              style: TextStyle(
                color: _rankColor,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          VoiceLiveAvatarGlow(
            live: isTop,
            glowColor: _rankColor,
            size: 36,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: speaker.avatarColor,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              child: speaker.avatarUrl?.trim().isNotEmpty == true
                  ? CanlifalNetworkImage(
                      url: speaker.avatarUrl!,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      thumbnailWidth: 72,
                      fadeIn: false,
                    )
                  : Text(
                      speaker.name.characters.first,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              speaker.name,
              style: const TextStyle(
                color: VoiceRoomsUiTokens.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isTop) ...[
            VoiceMicLevelBars(
              width: 22,
              height: 12,
              color: VoiceRoomsUiTokens.onlineGreen,
            ),
            const SizedBox(width: 6),
          ],
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (speaker.onlineLabel != null) ...[
                VoiceRoomsSvgIcons.icon(
                  'soundwave',
                  size: 12,
                  color: VoiceRoomsUiTokens.onlineGreen,
                ),
                const SizedBox(width: 4),
                Text(
                  speaker.onlineLabel!,
                  style: const TextStyle(
                    color: VoiceRoomsUiTokens.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ] else ...[
                VoiceRoomsSvgIcons.icon(
                  'diamond',
                  size: 12,
                  color: VoiceRoomsUiTokens.purpleGlow,
                ),
                const SizedBox(width: 4),
                Text(
                  speaker.diamonds,
                  style: const TextStyle(
                    color: VoiceRoomsUiTokens.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
