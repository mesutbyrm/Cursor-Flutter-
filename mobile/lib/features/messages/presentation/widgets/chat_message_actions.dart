import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/message_entities.dart';

Future<void> showChatMessageActions({
  required BuildContext context,
  required MessageEntity message,
  required VoidCallback? onDelete,
  required VoidCallback onReply,
  required VoidCallback onForward,
}) {
  return showModalBottomSheet<void>(
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
            leading: const Icon(Icons.reply_rounded, color: Colors.white70),
            title: const Text('Yanıtla', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(ctx);
              onReply();
            },
          ),
          ListTile(
            leading: const Icon(Icons.forward_rounded, color: Colors.white70),
            title: const Text('İlet', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(ctx);
              onForward();
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
              leading:
                  const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              title: const Text('Sil', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(ctx);
                onDelete();
              },
            ),
        ],
      ),
    ),
  );
}

Future<void> showConversationPeerActions({
  required BuildContext context,
  required String peerName,
  required VoidCallback onDeleteChat,
  required VoidCallback onBlock,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF111827),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              peerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep_outlined, color: Colors.white70),
            title: const Text('Sohbeti sil', style: TextStyle(color: Colors.white)),
            subtitle: const Text(
              'Bu cihazda sohbet gizlenir',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            onTap: () {
              Navigator.pop(ctx);
              onDeleteChat();
            },
          ),
          ListTile(
            leading: const Icon(Icons.block_rounded, color: Colors.redAccent),
            title: const Text('Mesajları engelle',
                style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              Navigator.pop(ctx);
              onBlock();
            },
          ),
        ],
      ),
    ),
  );
}
