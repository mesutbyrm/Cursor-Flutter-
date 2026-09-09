import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../moderation/domain/entities/report_target.dart';
import '../../../../moderation/presentation/utils/open_report_flow.dart';
import '../../../domain/entities/chat_room_message.dart';

/// Sesli oda sohbet — uzun bas: yanıtla / kopyala / raporla.
Future<void> showVoiceRoomChatMessageActions({
  required BuildContext context,
  required ChatRoomMessage message,
  VoidCallback? onReply,
  String? reportContextLabel,
}) {
  if (message.kind != ChatMessageKind.text) {
    return Future.value();
  }
  final text = message.content.trim();
  if (text.isEmpty) return Future.value();

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF1A1035),
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
                onReply();
              },
            ),
          ListTile(
            leading: const Icon(Icons.copy_rounded, color: Colors.white70),
            title: const Text('Kopyala', style: TextStyle(color: Colors.white)),
            onTap: () {
              Clipboard.setData(ClipboardData(text: text));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mesaj kopyalandı')),
              );
            },
          ),
          if (message.id.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: Colors.orangeAccent),
              title: const Text('Raporla', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                openReportFlow(
                  context,
                  ReportTarget(
                    type: ReportTargetType.message,
                    targetId: message.id,
                    displayTitle: text.length > 48
                        ? '${text.substring(0, 48)}…'
                        : text,
                    contextLabel: reportContextLabel,
                  ),
                );
              },
            ),
        ],
      ),
    ),
  );
}
