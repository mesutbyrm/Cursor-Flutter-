import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme_colors.dart';
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

  static const _theirsColor = Color(0xFF1A1A22);

  @override
  Widget build(BuildContext context) {
    final m = message;
    final action = _actionMeta(m.text);
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
                color: m.isMine ? null : _theirsColor,
                gradient: m.isMine
                    ? const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFFB832FF)],
                      )
                    : null,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(m.isMine ? 20 : 6),
                  bottomRight: Radius.circular(m.isMine ? 6 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (m.isMine ? const Color(0xFFB832FF) : Colors.black)
                        .withValues(alpha: m.isMine ? 0.24 : 0.22),
                    blurRadius: m.isMine ? 16 : 8,
                    offset: const Offset(0, 4),
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
                  if (action != null)
                    _CanlifalActionCard(meta: action)
                  else
                    Text(
                      m.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.5,
                        height: 1.35,
                        letterSpacing: 0.05,
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

  _ActionMeta? _actionMeta(String text) {
    final t = text.trim();
    final table = <({String starts, IconData icon, String title, String subtitle, Color color})>[
      (starts: '🎁', icon: Icons.card_giftcard_rounded, title: 'Hediye', subtitle: 'Canlifal hediyesi', color: AppThemeColors.coinGold),
      (starts: '🪙', icon: Icons.toll_rounded, title: 'Jeton', subtitle: 'Jeton transfer isteği', color: AppThemeColors.coinGold),
      (starts: '🔮', icon: Icons.auto_awesome_rounded, title: 'Fal İsteği', subtitle: 'Canlifal fal isteği', color: AppThemeColors.accentPurple),
      (starts: '🎙️', icon: Icons.mic_rounded, title: 'Sesli Fal', subtitle: 'Sesli fal isteği', color: AppThemeColors.accentPink),
      (starts: '📹', icon: Icons.video_call_rounded, title: 'Görüntülü Fal', subtitle: 'Görüntülü fal isteği', color: Colors.cyanAccent),
      (starts: '📡', icon: Icons.podcasts_rounded, title: 'Canlı Yayın', subtitle: 'Canlı yayına davet', color: AppThemeColors.liveRed),
      (starts: '🎧', icon: Icons.groups_rounded, title: 'Sesli Oda', subtitle: 'Sesli odaya davet', color: AppThemeColors.accentCyan),
      (starts: '📷', icon: Icons.photo_rounded, title: 'Fotoğraf', subtitle: 'Fotoğraf mesajı', color: AppThemeColors.accentCyan),
      (starts: '🎬', icon: Icons.videocam_rounded, title: 'Video', subtitle: 'Video mesajı', color: AppThemeColors.liveRed),
      (starts: '📎', icon: Icons.attach_file_rounded, title: 'Dosya', subtitle: 'Dosya mesajı', color: Colors.white70),
      (starts: '📍', icon: Icons.location_on_rounded, title: 'Konum', subtitle: 'Konum paylaşımı', color: Colors.greenAccent),
      (starts: '🖼️', icon: Icons.gif_box_rounded, title: 'GIF', subtitle: 'GIF mesajı', color: Colors.purpleAccent),
      (starts: '✨', icon: Icons.emoji_emotions_rounded, title: 'Sticker', subtitle: 'Sticker mesajı', color: Colors.orangeAccent),
    ];
    for (final row in table) {
      if (t.startsWith(row.starts)) {
        return _ActionMeta(
          icon: row.icon,
          title: row.title,
          subtitle: row.subtitle,
          color: row.color,
          body: t,
        );
      }
    }
    return null;
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

class _ActionMeta {
  const _ActionMeta({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String body;
}

class _CanlifalActionCard extends StatelessWidget {
  const _CanlifalActionCard({required this.meta});

  final _ActionMeta meta;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 210),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: meta.color.withValues(alpha: 0.42)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  meta.color.withValues(alpha: 0.92),
                  AppThemeColors.accentPurple.withValues(alpha: 0.72),
                ],
              ),
            ),
            child: Icon(meta.icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meta.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  meta.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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
