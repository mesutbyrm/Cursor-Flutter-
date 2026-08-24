import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../live/presentation/providers/live_providers.dart';
import '../../../../vip_gold/presentation/utils/open_voice_room_vip.dart';
import '../../utils/open_voice_chat_room_flow.dart';
import 'voice_rooms_svg_icons.dart';
import 'voice_rooms_ui_tokens.dart';
import 'voice_glass_container.dart';

class MyRoomCard extends ConsumerWidget {
  const MyRoomCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owned = ref.watch(myOwnedVoiceRoomsProvider);
    final hasRooms = owned.isNotEmpty;

    return VoiceGlassContainer(
      radius: VoiceRoomsUiTokens.radiusLg,
      glowColor: VoiceRoomsUiTokens.purpleGlow,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: VoiceRoomsUiTokens.fabGradient,
                  boxShadow: VoiceRoomsUiTokens.purpleGlowShadow(blur: 20),
                ),
                child: Center(
                  child: VoiceRoomsSvgIcons.icon(
                    'mic',
                    size: 22,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Odalarım',
                      style: TextStyle(
                        color: VoiceRoomsUiTokens.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      hasRooms
                          ? '${owned.length} açık oda'
                          : 'Kendi odanı oluştur',
                      style: const TextStyle(
                        color: VoiceRoomsUiTokens.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasRooms) ...[
            const SizedBox(height: 12),
            ...owned.take(3).map((room) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => openVoiceRoomWithVipGate(
                      context,
                      ref,
                      room,
                      skipVipGateForOwner: true,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              room.displayTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: VoiceRoomsUiTokens.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            '${room.displayOnline}',
                            style: TextStyle(
                              color: room.displayOnline > 0
                                  ? VoiceRoomsUiTokens.onlineGreen
                                  : VoiceRoomsUiTokens.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
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
              );
            }),
          ],
          const SizedBox(height: 10),
          _CreateRoomButton(
            label: hasRooms ? 'Yeni Oda Aç' : 'Oda Oluştur',
            onTap: () => showOpenVoiceChatRoomFlow(context, ref),
          ),
        ],
      ),
    );
  }
}

class _CreateRoomButton extends StatelessWidget {
  const _CreateRoomButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VoiceRoomsUiTokens.radiusPill),
        splashColor: Colors.white24,
        child: Ink(
          decoration: BoxDecoration(
            gradient: VoiceRoomsUiTokens.purpleGradient,
            borderRadius: BorderRadius.circular(VoiceRoomsUiTokens.radiusPill),
            boxShadow: VoiceRoomsUiTokens.purpleGlowShadow(blur: 16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                VoiceRoomsSvgIcons.icon('sparkle', size: 14, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 6),
                VoiceRoomsSvgIcons.icon('sparkle', size: 14, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
