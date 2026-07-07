import 'package:flutter/material.dart';

import 'voice_rooms_mock_data.dart';
import 'voice_rooms_svg_icons.dart';
import 'voice_rooms_ui_tokens.dart';

/// Yakındaki oda listesi satır kartı — yeniden kullanılabilir.
class NearbyRoomTileCard extends StatelessWidget {
  const NearbyRoomTileCard({
    super.key,
    required this.room,
    this.onJoin,
  });

  final NearbyRoomItem room;
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onJoin,
        borderRadius: BorderRadius.circular(VoiceRoomsUiTokens.radiusMd),
        splashColor: VoiceRoomsUiTokens.purpleGlow.withValues(alpha: 0.15),
        child: Container(
          margin: const EdgeInsets.only(bottom: VoiceRoomsUiTokens.gapMd),
          padding: const EdgeInsets.all(12),
          decoration: VoiceRoomsUiTokens.glass(radius: VoiceRoomsUiTokens.radiusMd),
          child: Row(
            children: [
              Hero(
                tag: 'nearby_avatar_${room.id}',
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: room.avatarColor,
                    border: Border.all(color: room.ringColor, width: 2.5),
                    boxShadow: VoiceRoomsUiTokens.glowShadow(room.ringColor, blur: 14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    room.title.characters.first,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: VoiceRoomsUiTokens.gapMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.title,
                      style: const TextStyle(
                        color: VoiceRoomsUiTokens.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      room.subtitle,
                      style: const TextStyle(
                        color: VoiceRoomsUiTokens.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      children: room.tags
                          .map(
                            (t) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(
                                  VoiceRoomsUiTokens.radiusPill,
                                ),
                              ),
                              child: Text(
                                t,
                                style: const TextStyle(
                                  color: VoiceRoomsUiTokens.textSecondary,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VoiceRoomsSvgIcons.icon(
                        'location',
                        size: 11,
                        color: VoiceRoomsUiTokens.textMuted,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        room.distance,
                        style: const TextStyle(
                          color: VoiceRoomsUiTokens.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VoiceRoomsSvgIcons.icon(
                        'eye',
                        size: 11,
                        color: VoiceRoomsUiTokens.textMuted,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        room.viewers,
                        style: const TextStyle(
                          color: VoiceRoomsUiTokens.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _JoinButton(onTap: onJoin),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JoinButton extends StatefulWidget {
  const _JoinButton({this.onTap});

  final VoidCallback? onTap;

  @override
  State<_JoinButton> createState() => _JoinButtonState();
}

class _JoinButtonState extends State<_JoinButton> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: VoiceRoomsUiTokens.purpleGradient,
            borderRadius: BorderRadius.circular(VoiceRoomsUiTokens.radiusPill),
            boxShadow: VoiceRoomsUiTokens.purpleGlowShadow(blur: 12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              VoiceRoomsSvgIcons.icon('hand', size: 12, color: Colors.white),
              const SizedBox(width: 4),
              const Text(
                'Katıl',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
