import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/economy/presentation/providers/economy_providers.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../domain/entities/message_entities.dart';
import '../../domain/utils/dm_message_codec.dart';
import 'dm_voice_note_bubble.dart';
/// WhatsApp tarzı mesaj balonu: benim mesajlarım sağda yeşil, karşı tarafınki
/// solda nötr gri (açık/koyu temaya göre); saat ve iletim durumu sağ altta.
class ChatMessageBubble extends ConsumerWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    this.onDelete,
    this.onReply,
    this.onForward,
  });

  final MessageEntity message;
  final VoidCallback? onDelete;
  final VoidCallback? onReply;
  final VoidCallback? onForward;

  static const _mineGradient = [Color(0xFF0B8F6A), Color(0xFF16A36F)];
  static const _theirsDark = Color(0xFF262B35);
  static const _theirsLight = Color(0xFFEEF1F5);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = message;
    final voiceNote = DmMessageCodec.parseVoiceNote(m.text);
    final action = voiceNote == null
        ? _actionMeta(
            m.text,
            jetonLabel: economyCurrencyLabel(ref, key: 'jeton'),
          )
        : null;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = m.isMine || dark ? Colors.white : const Color(0xFF111B21);
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
                color: m.isMine ? null : (dark ? _theirsDark : _theirsLight),
                gradient: m.isMine ? const LinearGradient(colors: _mineGradient) : null,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(m.isMine ? 18 : 4),
                  bottomRight: Radius.circular(m.isMine ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: dark ? 0.22 : 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (m.forwardedFrom != null) ...[
                    Text(
                      'İletildi · ${m.forwardedFrom}',
                      style: TextStyle(
                        color: fg.withValues(alpha: 0.72),
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
                        color: Colors.black.withValues(alpha: m.isMine || dark ? 0.22 : 0.06),
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
                          color: fg.withValues(alpha: 0.9),
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                  if (voiceNote != null)
                    DmVoiceNoteBubble(meta: voiceNote)
                  else if (action != null)
                    _CanlifalActionCard(meta: action, fg: fg)
                  else
                    Text(
                      m.text,
                      style: TextStyle(
                        color: fg,
                        fontSize: 16.5,
                        height: 1.35,
                        letterSpacing: 0.05,
                      ),
                    ),
                  const SizedBox(height: 3),
                  Row(
                    key: const Key('chat-bubble-meta'),
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (m.createdAt != null)
                        Text(
                          DateFormat.Hm('tr').format(m.createdAt!.toLocal()),
                          style: TextStyle(
                            fontSize: 11,
                            color: fg.withValues(alpha: 0.72),
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
      ],
    );
  }

  /// Uygulamanın gönderdiği niyet/davet mesajlarını kart olarak gösterir.
  ///
  /// Yalnızca birebir üretilen metinler eşleşir. Eskiden işaret emojisiyle
  /// başlayan her mesaj karta dönüşüyor ve metni kayboluyordu: "✨ Günaydın"
  /// "Sticker mesajı" olarak görünüyordu (✨ emoji seçicide ilk sırada).
  _ActionMeta? _actionMeta(String text, {required String jetonLabel}) {
    final t = text.trim();
    final table = <({String starts, String body, IconData icon, String title, String subtitle, Color color})>[
      (starts: '🎁', body: 'Hediye göndermek istiyor.', icon: Icons.card_giftcard_rounded, title: 'Hediye', subtitle: 'Hediye göndermek istiyor', color: AppThemeColors.coinGold),
      (starts: '🪙', body: '$jetonLabel göndermek istiyor.', icon: Icons.toll_rounded, title: jetonLabel, subtitle: '$jetonLabel göndermek istiyor', color: AppThemeColors.coinGold),
      (starts: '🔮', body: 'Fal isteği gönderdi.', icon: Icons.auto_awesome_rounded, title: 'Fal İsteği', subtitle: 'Fal isteği gönderdi', color: AppThemeColors.accentPurple),
      (starts: '🎙️', body: 'Sesli fal isteği gönderdi.', icon: Icons.mic_rounded, title: 'Sesli Fal', subtitle: 'Sesli fal isteği gönderdi', color: AppThemeColors.accentPink),
      (starts: '📹', body: 'Görüntülü fal isteği gönderdi.', icon: Icons.video_call_rounded, title: 'Görüntülü Fal', subtitle: 'Görüntülü fal isteği gönderdi', color: Colors.cyanAccent),
      (starts: '📡', body: 'Canlı yayına davet etti.', icon: Icons.podcasts_rounded, title: 'Canlı Yayın', subtitle: 'Canlı yayına davet etti', color: AppThemeColors.liveRed),
      (starts: '🎧', body: 'Sesli odaya davet etti.', icon: Icons.groups_rounded, title: 'Sesli Oda', subtitle: 'Sesli odaya davet etti', color: AppThemeColors.accentCyan),
    ];
    for (final row in table) {
      if (t.startsWith(row.starts) &&
          t.substring(row.starts.length).trim() == row.body) {
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
  const _CanlifalActionCard({required this.meta, this.fg = Colors.white});

  final _ActionMeta meta;
  final Color fg;

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
                  style: TextStyle(
                    color: fg,
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
                    color: fg.withValues(alpha: 0.72),
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
