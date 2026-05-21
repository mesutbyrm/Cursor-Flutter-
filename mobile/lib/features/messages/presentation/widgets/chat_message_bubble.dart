import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/message_entities.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({super.key, required this.message});

  final MessageEntity message;

  @override
  Widget build(BuildContext context) {
    final m = message;
    return Align(
      alignment: m.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: m.isMine ? AppColors.brandGradient : null,
          color: m.isMine
              ? null
              : const Color(0xFF16162A).withValues(alpha: 0.92),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(m.isMine ? 16 : 4),
            bottomRight: Radius.circular(m.isMine ? 4 : 16),
          ),
          border: m.isMine
              ? null
              : Border.all(
                  color: AppColors.accentPurple.withValues(alpha: 0.25),
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              m.text,
              style: TextStyle(
                color: m.isMine ? Colors.white : AppColors.textPrimary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (m.createdAt != null)
                  Text(
                    DateFormat.Hm('tr').format(m.createdAt!),
                    style: TextStyle(
                      fontSize: 10,
                      color: (m.isMine ? Colors.white : AppColors.textMuted)
                          .withValues(alpha: 0.65),
                    ),
                  ),
                if (m.isMine) ...[
                  const SizedBox(width: 4),
                  MessageReadTicks(status: m.deliveryStatus),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MessageReadTicks extends StatelessWidget {
  const MessageReadTicks({super.key, required this.status});

  final MessageDeliveryStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      MessageDeliveryStatus.read => AppColors.accentCyan,
      MessageDeliveryStatus.delivered => Colors.white.withValues(alpha: 0.75),
      MessageDeliveryStatus.sending => Colors.white.withValues(alpha: 0.45),
      MessageDeliveryStatus.sent => Colors.white.withValues(alpha: 0.55),
    };
    final icon = status == MessageDeliveryStatus.read
        ? Icons.done_all_rounded
        : Icons.done_rounded;
    return Icon(icon, size: 14, color: color);
  }
}
