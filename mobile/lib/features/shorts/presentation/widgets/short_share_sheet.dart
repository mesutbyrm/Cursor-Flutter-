import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../pages/shorts_feed_page.dart';

Future<void> showShortShareSheet(
  BuildContext context, {
  required String videoId,
  required String? description,
  required VoidCallback onShared,
}) {
  final link = shortVideoShareUrl(videoId);
  final text = [
    if (description?.trim().isNotEmpty == true) description!.trim(),
    link,
  ].join('\n');

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF121218),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) => SafeArea(
      child: Wrap(
        children: [
          _ShareTile(
            icon: Icons.link,
            label: 'Link kopyala',
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: link));
              if (ctx.mounted) Navigator.pop(ctx);
              onShared();
            },
          ),
          _ShareTile(
            icon: Icons.share_outlined,
            label: 'Paylaş',
            onTap: () {
              SharePlus.instance.share(ShareParams(text: text));
              Navigator.pop(ctx);
              onShared();
            },
          ),
          _ShareTile(
            icon: Icons.chat,
            label: 'WhatsApp',
            onTap: () async {
              final uri = Uri.parse(
                'https://wa.me/?text=${Uri.encodeComponent(text)}',
              );
              await launchUrl(uri, mode: LaunchMode.externalApplication);
              if (ctx.mounted) Navigator.pop(ctx);
              onShared();
            },
          ),
          _ShareTile(
            icon: Icons.send_outlined,
            label: 'Telegram',
            onTap: () async {
              final uri = Uri.parse(
                'https://t.me/share/url?url=${Uri.encodeComponent(link)}',
              );
              await launchUrl(uri, mode: LaunchMode.externalApplication);
              if (ctx.mounted) Navigator.pop(ctx);
              onShared();
            },
          ),
          _ShareTile(
            icon: Icons.close,
            label: 'Kapat',
            onTap: () => Navigator.pop(ctx),
          ),
        ],
      ),
    ),
  );
}

class _ShareTile extends StatelessWidget {
  const _ShareTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }
}
