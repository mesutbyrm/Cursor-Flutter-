import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/env.dart';
import '../../domain/entities/fortune_type_entity.dart';

typedef FortuneShareAction = Future<void> Function();

class FortuneShareOptions {
  const FortuneShareOptions({
    this.onShareStory,
    this.onShareToSocialFeed,
    this.onShareToProfile,
    this.onSharePublic,
  });

  final FortuneShareAction? onShareStory;
  final FortuneShareAction? onShareToSocialFeed;
  final FortuneShareAction? onShareToProfile;
  final FortuneShareAction? onSharePublic;
}

Future<void> showFortuneShareSheet(
  BuildContext context,
  FortuneReadingResult result, {
  FortuneShareOptions options = const FortuneShareOptions(),
}) {
  final text = _shareText(result);
  final link = _shareLink(result);

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF12121F),
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '📤 Paylaş',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 16),
            _ShareRow(
              children: [
                if (options.onShareToSocialFeed != null)
                  _ShareTile(
                    icon: Icons.public_rounded,
                    label: 'Sosyal Bölümde',
                    color: const Color(0xFFB832FF),
                    onTap: () => _run(ctx, options.onShareToSocialFeed!),
                  ),
                if (options.onShareToProfile != null)
                  _ShareTile(
                    icon: Icons.person_rounded,
                    label: 'Profilimde',
                    color: const Color(0xFF38BDF8),
                    onTap: () => _run(ctx, options.onShareToProfile!),
                  ),
                if (options.onSharePublic != null)
                  _ShareTile(
                    icon: Icons.groups_rounded,
                    label: 'Herkese Açık',
                    color: const Color(0xFF4ADE80),
                    onTap: () => _run(ctx, options.onSharePublic!),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _ShareRow(
              children: [
                _ShareTile(
                  icon: Icons.link_rounded,
                  label: 'Link Oluştur',
                  color: Colors.white70,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await Clipboard.setData(ClipboardData(text: '$text\n\n$link'));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link kopyalandı')),
                      );
                    }
                  },
                ),
                if (options.onShareStory != null)
                  _ShareTile(
                    icon: Icons.auto_awesome,
                    label: 'IG Hikaye',
                    color: const Color(0xFFE1306C),
                    onTap: () => _run(ctx, options.onShareStory!),
                  ),
                _ShareTile(
                  icon: Icons.chat_rounded,
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: () {
                    Navigator.pop(ctx);
                    _launchExternal(
                      'https://wa.me/?text=${Uri.encodeComponent('$text\n$link')}',
                    );
                  },
                ),
                _ShareTile(
                  icon: Icons.send_rounded,
                  label: 'Telegram',
                  color: const Color(0xFF229ED9),
                  onTap: () {
                    Navigator.pop(ctx);
                    _shareTextNative('$text\n$link');
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ShareRow(
              children: [
                _ShareTile(
                  icon: Icons.tag_rounded,
                  label: 'X',
                  color: Colors.white,
                  onTap: () {
                    Navigator.pop(ctx);
                    _launchExternal(
                      'https://twitter.com/intent/tweet?text=${Uri.encodeComponent('$text $link')}',
                    );
                  },
                ),
                _ShareTile(
                  icon: Icons.facebook_rounded,
                  label: 'Facebook',
                  color: const Color(0xFF1877F2),
                  onTap: () {
                    Navigator.pop(ctx);
                    _launchExternal(
                      'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(link)}',
                    );
                  },
                ),
                _ShareTile(
                  icon: Icons.ios_share_rounded,
                  label: 'Diğer',
                  color: Colors.white54,
                  onTap: () {
                    Navigator.pop(ctx);
                    _shareTextNative('$text\n$link');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

String _shareText(FortuneReadingResult result) =>
    '${result.type.title} — ${result.summary}';

String _shareLink(FortuneReadingResult result) {
  final base = Env.apiBaseUrl.replaceAll(RegExp(r'/api/?$'), '');
  return '$base/fal/${result.type.slug}';
}

Future<void> _run(BuildContext ctx, FortuneShareAction action) async {
  Navigator.pop(ctx);
  await action();
}

Future<void> _shareTextNative(String text) async {
  await SharePlus.instance.share(ShareParams(text: text, subject: 'Canlifal Fal'));
}

Future<void> _launchExternal(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _ShareRow extends StatelessWidget {
  const _ShareRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
}

class _ShareTile extends StatelessWidget {
  const _ShareTile({
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
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
