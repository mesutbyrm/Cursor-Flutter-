import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../feed/domain/entities/post_entity.dart';

const socialCaptionPreviewChars = 250;

/// Gönderi metni — ilk 250 karakter, «daha fazla» ile genişler.
class SocialPostCaption extends StatefulWidget {
  const SocialPostCaption({
    super.key,
    required this.post,
    this.inlineBodyOnly = false,
  });

  final PostEntity post;
  final bool inlineBodyOnly;

  @override
  State<SocialPostCaption> createState() => _SocialPostCaptionState();
}

class _SocialPostCaptionState extends State<SocialPostCaption> {
  var _expanded = false;

  PostEntity get post => widget.post;

  @override
  Widget build(BuildContext context) {
    final text = post.caption?.trim() ?? '';
    if (text.isEmpty) return const SizedBox.shrink();

    final hasOverflow = text.length > socialCaptionPreviewChars;
    final preview = hasOverflow && !_expanded
        ? text.substring(0, socialCaptionPreviewChars)
        : text;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.inlineBodyOnly
              ? Text(
                  preview,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    color: AppColors.textPrimary,
                  ),
                )
              : RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: AppColors.textPrimary,
                    ),
                    children: [
                      TextSpan(
                        text: '${post.author.display} ',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      TextSpan(text: preview),
                    ],
                  ),
                ),
          if (hasOverflow && !_expanded) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => setState(() => _expanded = true),
              child: const Text(
                'daha fazla',
                style: TextStyle(
                  color: AppColors.accentCyan,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
          if (hasOverflow && _expanded) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => setState(() => _expanded = false),
              child: const Text(
                'daha az',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Metin gönderileri için 250 karakter önizleme.
class SocialPostTextPreview extends StatefulWidget {
  const SocialPostTextPreview({super.key, required this.text});

  final String text;

  @override
  State<SocialPostTextPreview> createState() => _SocialPostTextPreviewState();
}

class _SocialPostTextPreviewState extends State<SocialPostTextPreview> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final text = widget.text.trim();
    final hasOverflow = text.length > socialCaptionPreviewChars;
    final preview = hasOverflow && !_expanded
        ? text.substring(0, socialCaptionPreviewChars)
        : text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          preview,
          style: const TextStyle(
            fontSize: 15,
            height: 1.45,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        if (hasOverflow && !_expanded) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => setState(() => _expanded = true),
            child: const Text(
              'daha fazla',
              style: TextStyle(
                color: AppColors.accentCyan,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
        if (hasOverflow && _expanded) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => setState(() => _expanded = false),
            child: const Text(
              'daha az',
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
