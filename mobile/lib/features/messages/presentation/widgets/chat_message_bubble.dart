import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/message_entities.dart';
import 'chat_quick_replies_bar.dart';

/// WhatsApp tarzı mesaj balonu — büyük yazı, alıntı, hızlı yanıtlar.
class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    this.onDelete,
    this.onReply,
    this.onForward,
    this.showQuickReplies = false,
    this.onQuickReply,
  });

  final MessageEntity message;
  final VoidCallback? onDelete;
  final VoidCallback? onReply;
  final VoidCallback? onForward;
  final bool showQuickReplies;
  final ValueChanged<String>? onQuickReply;

  static const _mineColor = Color(0xFF005C4B);
  static const _theirsColor = Color(0xFF1F2C34);

  @override
  Widget build(BuildContext context) {
    final m = message;
    return Column(
      crossAxisAlignment:
          m.isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Align(
          alignment: m.isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPress: () => _showActions(context),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 3),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.82,
              ),
              padding: const EdgeInsets.fromLTRB(12, 9, 10, 7),
              decoration: BoxDecoration(
                color: m.isMine ? _mineColor : _theirsColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(m.isMine ? 16 : 4),
                  bottomRight: Radius.circular(m.isMine ? 4 : 16),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (m.forwardedFrom != null) ...[
                    Text(
                      'İletildi · ${m.forwardedFrom}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (m.replyTo != null) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(8),
                        border: const Border(
                          left: BorderSide(color: Color(0xFF25D366), width: 3),
                        ),
                      ),
                      child: Text(
                        m.replyTo!.text,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                  Text(
                    m.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17.5,
                      height: 1.4,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (m.createdAt != null)
                        Text(
                          DateFormat.Hm('tr').format(m.createdAt!.toLocal()),
                          style: TextStyle(
                            fontSize: 12,
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
        ),
        if (showQuickReplies && onQuickReply != null)
          ChatQuickRepliesBar(onSelect: onQuickReply!),
      ],
    );
  }

  void _showActions(BuildContext context) {
    if (onReply == null && onForward == null && onDelete == null) return;
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
            if (onReply != null)
              ListTile(
                leading: const Icon(Icons.reply_rounded, color: Colors.white70),
                title: const Text('Yanıtla', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  onReply!();
                },
              ),
            if (onForward != null)
              ListTile(
                leading: const Icon(Icons.forward_rounded, color: Colors.white70),
                title: const Text('İlet', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  onForward!();
                },
              ),
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
                leading: const Icon(Icons.delete_outline_rounded,
                    color: Colors.redAccent),
                title:
                    const Text('Sil', style: TextStyle(color: Colors.redAccent)),
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
    return Icon(icon, size: 17, color: color);
  }
}
