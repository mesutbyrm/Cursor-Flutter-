import 'package:flutter/material.dart';

import '../../../domain/entities/live_broadcast_session.dart';
import '../../../domain/entities/live_fortune_request_entity.dart';
import 'live_broadcast_room_chips.dart';
import 'live_room_chat_fal_panel.dart';
import 'live_room_chat_message.dart';

/// Canlı yayın sohbet alanı + yan rail yuvası.
class LiveBroadcastRoomChatOverlay extends StatelessWidget {
  const LiveBroadcastRoomChatOverlay({
    super.key,
    required this.chatVisible,
    required this.onHideChat,
    required this.onShowChat,
    required this.session,
    required this.lastJoinedName,
    required this.messages,
    required this.balance,
    required this.initialFortuneType,
    required this.onMessageLongPress,
    required this.onSubmitFortuneRequest,
    required this.viewerSideRail,
  });

  final bool chatVisible;
  final VoidCallback onHideChat;
  final VoidCallback onShowChat;
  final LiveBroadcastSession session;
  final String? lastJoinedName;
  final List<LiveRoomChatMessage> messages;
  final int? balance;
  final String? initialFortuneType;
  final void Function(LiveRoomChatMessage message)? onMessageLongPress;
  final Future<bool> Function({
    required String displayName,
    required String question,
    required String fortuneType,
    required LiveFortunePriority priority,
    required int jetonCost,
  }) onSubmitFortuneRequest;
  final Widget viewerSideRail;

  @override
  Widget build(BuildContext context) {
    if (chatVisible) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 12, bottom: 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: Semantics(
                button: true,
                label: 'Sohbeti gizle',
                child: GestureDetector(
                  onTap: onHideChat,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.keyboard_arrow_down_rounded,
                            color: Colors.white, size: 18),
                        Text(
                          'Sohbeti gizle',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (lastJoinedName != null && lastJoinedName!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: LiveBroadcastLastJoinedChip(
                            name: lastJoinedName!,
                          ),
                        ),
                      const SizedBox(height: 6),
                      LiveRoomChatFalPanel(
                        messages: messages.isEmpty
                            ? const [
                                LiveRoomChatMessage(
                                  user: 'Sistem',
                                  text: 'Canlı yayına hoş geldin',
                                  isSystem: true,
                                ),
                              ]
                            : messages,
                        showFortuneTab: false,
                        canModerate: session.isHost,
                        onMessageLongPress: onMessageLongPress,
                        balance: balance,
                        initialFortuneType: initialFortuneType,
                        onSubmitFortuneRequest: onSubmitFortuneRequest,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                viewerSideRail,
              ],
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Spacer(),
          Semantics(
            button: true,
            label: 'Sohbeti göster',
            child: GestureDetector(
              onTap: onShowChat,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_bubble_rounded,
                        color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Sohbet',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          viewerSideRail,
        ],
      ),
    );
  }
}
