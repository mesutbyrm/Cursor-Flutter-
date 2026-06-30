import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/message_entities.dart';

/// WhatsApp tarzı mesaj balonu — daha büyük yazı, okundu/görüldü tikleri.
class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    this.onDelete,
  });

  final MessageEntity message;
  final VoidCallback? onDelete;

  static const _mineColor = Color(0xFF005C4B);
  static const _theirsColor = Color(0xFF1F2C34);

  @override
  Widget build(BuildContext context) {
    final m = message;
    return Align(
      alignment: m.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showActions(context),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.82,
          ),
          padding: const EdgeInsets.fromLTRB(12, 8, 10, 6),
          decoration: BoxDecoration(
            color: m.isMine ? _mineColor : _theirsColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(m.isMine ? 14 : 4),
              bottomRight: Radius.circular(m.isMine ? 4 : 14),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                m.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.38,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (m.createdAt != null)
                    Text(
                      DateFormat.Hm('tr').format(m.createdAt!.toLocal()),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.72),
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
      ),
    );
  }

  void _showActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy_rounded, color: Colors.white70),
              title: const Text('Kopyala', style: TextStyle(color: Colors.white)),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.text));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mesaj kopyalandı')),
                );
              },
            ),
            if (onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                title: const Text('Sil', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(ctx);
                  onDelete!();
                },
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
    final (icon, color) = switch (status) {
      MessageDeliveryStatus.read => (
          Icons.done_all_rounded,
          const Color(0xFF53BDEB),
        ),
      MessageDeliveryStatus.delivered => (
          Icons.done_all_rounded,
          Colors.white.withValues(alpha: 0.72),
        ),
      MessageDeliveryStatus.sending => (
          Icons.access_time_rounded,
          Colors.white.withValues(alpha: 0.55),
        ),
      MessageDeliveryStatus.sent => (
          Icons.done_rounded,
          Colors.white.withValues(alpha: 0.65),
        ),
    };
    return Icon(icon, size: 16, color: color);
  }
}
