import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/fortune_type_entity.dart';

void showFortuneShareSheet(
  BuildContext context,
  FortuneReadingResult result, {
  VoidCallback? onShareStory,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF16162A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final text =
          '${result.type.title} — ${result.summary}\n\n${result.fullText}';
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Paylaş',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Story kalitesinde görsel veya metin paylaş',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (onShareStory != null)
                    _ShareChip(
                      icon: Icons.auto_awesome,
                      label: 'Story',
                      color: AppThemeColors.accentPurple,
                      onTap: () {
                        Navigator.pop(ctx);
                        onShareStory();
                      },
                    ),
                  _ShareChip(
                    icon: Icons.camera_alt_outlined,
                    label: 'Instagram',
                    color: const Color(0xFFE1306C),
                    onTap: () {
                      Navigator.pop(ctx);
                      if (onShareStory != null) {
                        onShareStory();
                      } else {
                        _share(text);
                      }
                    },
                  ),
                  _ShareChip(
                    icon: Icons.chat_rounded,
                    label: 'WhatsApp',
                    color: const Color(0xFF25D366),
                    onTap: () {
                      Navigator.pop(ctx);
                      _share(text);
                    },
                  ),
                  _ShareChip(
                    icon: Icons.send_rounded,
                    label: 'Telegram',
                    color: const Color(0xFF229ED9),
                    onTap: () {
                      Navigator.pop(ctx);
                      _share(text);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _share(String text) async {
  await SharePlus.instance.share(ShareParams(text: text, subject: 'Canlifal Fal'));
}

class _ShareChip extends StatelessWidget {
  const _ShareChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.5)),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
