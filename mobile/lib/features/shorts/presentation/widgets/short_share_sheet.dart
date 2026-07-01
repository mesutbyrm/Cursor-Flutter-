import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/firebase/firebase_bootstrap.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/ui/premium/premium_bottom_sheet.dart';
import '../../../social/presentation/providers/social_providers.dart';
import '../../domain/entities/short_video_entity.dart';
import '../pages/shorts_feed_page.dart';
import '../utils/shorts_api_message.dart';
import 'short_story_share_card.dart';

Future<void> showShortShareSheet(
  BuildContext context, {
  required String videoId,
  required String? description,
  required VoidCallback onShared,
  ShortVideoEntity? video,
  WidgetRef? ref,
}) {
  final link = shortVideoShareUrl(videoId);
  final text = [
    if (description?.trim().isNotEmpty == true) description!.trim(),
    link,
  ].join('\n');

  return showPremiumBottomSheet<void>(
    context: context,
    child: _ShortShareSheetBody(
      videoId: videoId,
      link: link,
      text: text,
      video: video,
      ref: ref,
      onShared: onShared,
    ),
  );
}

class _ShortShareSheetBody extends StatefulWidget {
  const _ShortShareSheetBody({
    required this.videoId,
    required this.link,
    required this.text,
    required this.onShared,
    this.video,
    this.ref,
  });

  final String videoId;
  final String link;
  final String text;
  final VoidCallback onShared;
  final ShortVideoEntity? video;
  final WidgetRef? ref;

  @override
  State<_ShortShareSheetBody> createState() => _ShortShareSheetBodyState();
}

class _ShortShareSheetBodyState extends State<_ShortShareSheetBody> {
  var _storyLoading = false;

  Future<void> _shareToStory() async {
    final ref = widget.ref;
    final video = widget.video;
    if (ref == null || video == null) {
      if (mounted) {
        showShortsSnackBar(context, 'Hikâye paylaşımı için giriş gerekli.');
      }
      return;
    }
    setState(() => _storyLoading = true);
    try {
      final imagePath = await downloadThumbnailForStory(
        video,
        ref.read(dioProvider),
      );
      if (imagePath == null) {
        throw Exception('Kapak görseli indirilemedi');
      }
      await ref.read(socialRepositoryProvider).createStoryImage(imagePath);
      await FirebaseBootstrap.logEvent(
        'short_share_story',
        parameters: {'video_id': widget.videoId},
      );
      if (mounted) {
        Navigator.pop(context);
        showShortsSnackBar(context, 'Hikâyede paylaşıldı.');
        widget.onShared();
      }
    } catch (e) {
      if (mounted) {
        showShortsSnackBar(context, 'Hikâye paylaşılamadı: $e');
      }
    } finally {
      if (mounted) setState(() => _storyLoading = false);
    }
  }

  void _showQr() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF121218),
        title: const Text('QR kod', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: widget.link,
                version: QrVersions.auto,
                size: 200,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.link,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: widget.link));
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Link kopyala'),
          ),
          FilledButton(
            onPressed: () {
              SharePlus.instance.share(
                ShareParams(text: widget.link),
              );
              Navigator.pop(ctx);
              widget.onShared();
            },
            child: const Text('Paylaş'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Wrap(
        children: [
          _ShareTile(
            icon: Icons.link,
            label: 'Link kopyala',
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: widget.link));
              if (context.mounted) Navigator.pop(context);
              widget.onShared();
            },
          ),
          _ShareTile(
            icon: Icons.qr_code_2,
            label: 'QR kod',
            onTap: _showQr,
          ),
          if (widget.video != null && widget.ref != null)
            _ShareTile(
              icon: Icons.auto_stories_outlined,
              label: _storyLoading ? 'Hikâye…' : 'Hikâyede paylaş',
              onTap: _storyLoading ? null : _shareToStory,
            ),
          _ShareTile(
            icon: Icons.share_outlined,
            label: 'Paylaş',
            onTap: () {
              SharePlus.instance.share(ShareParams(text: widget.text));
              Navigator.pop(context);
              widget.onShared();
            },
          ),
          _ShareTile(
            icon: Icons.chat,
            label: 'WhatsApp',
            onTap: () async {
              final uri = Uri.parse(
                'https://wa.me/?text=${Uri.encodeComponent(widget.text)}',
              );
              await launchUrl(uri, mode: LaunchMode.externalApplication);
              if (context.mounted) Navigator.pop(context);
              widget.onShared();
            },
          ),
          _ShareTile(
            icon: Icons.telegram,
            label: 'Telegram',
            onTap: () async {
              final uri = Uri.parse(
                'https://t.me/share/url?url=${Uri.encodeComponent(widget.link)}',
              );
              await launchUrl(uri, mode: LaunchMode.externalApplication);
              if (context.mounted) Navigator.pop(context);
              widget.onShared();
            },
          ),
          _ShareTile(
            icon: Icons.alternate_email,
            label: 'X (Twitter)',
            onTap: () async {
              final uri = Uri.parse(
                'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(widget.text)}',
              );
              await launchUrl(uri, mode: LaunchMode.externalApplication);
              if (context.mounted) Navigator.pop(context);
              widget.onShared();
            },
          ),
          _ShareTile(
            icon: Icons.facebook,
            label: 'Facebook',
            onTap: () async {
              final uri = Uri.parse(
                'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(widget.link)}',
              );
              await launchUrl(uri, mode: LaunchMode.externalApplication);
              if (context.mounted) Navigator.pop(context);
              widget.onShared();
            },
          ),
          _ShareTile(
            icon: Icons.camera_alt_outlined,
            label: 'Instagram',
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: widget.link));
              final uri = Uri.parse('instagram://story-camera');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              } else {
                await launchUrl(
                  Uri.parse('https://www.instagram.com/'),
                  mode: LaunchMode.externalApplication,
                );
              }
              if (context.mounted) {
                Navigator.pop(context);
                showShortsSnackBar(context, 'Link kopyalandı — hikâyeye yapıştırın.');
              }
              widget.onShared();
            },
          ),
          _ShareTile(
            icon: Icons.close,
            label: 'Kapat',
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _ShareTile extends StatelessWidget {
  const _ShareTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }
}
