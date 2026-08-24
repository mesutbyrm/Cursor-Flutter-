import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';

import '../../../../feed/domain/entities/post_entity.dart';
import '../social_linked_caption_text.dart';

const socialCaptionPreviewChars = 250;

/// Gönderi metni — ilk 250 karakter, «daha fazla» ile genişler.
class SocialPostCaption extends StatefulWidget {
  const SocialPostCaption({
    super.key,
    required this.post,
    this.inlineBodyOnly = false,
    this.bodyText,
  });

  final PostEntity post;
  final bool inlineBodyOnly;
  final String? bodyText;

  @override
  State<SocialPostCaption> createState() => _SocialPostCaptionState();
}

class _SocialPostCaptionState extends State<SocialPostCaption> {
  var _expanded = false;

  PostEntity get post => widget.post;

  @override
  Widget build(BuildContext context) {
    final text = (widget.bodyText ?? post.caption)?.trim() ?? '';
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
              ? SocialLinkedCaptionText(
                  text: preview,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    color: context.colors.onSurface,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.author.display,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        fontWeight: FontWeight.w800,
                        color: context.colors.onSurface,
                      ),
                    ),
                    SocialLinkedCaptionText(
                      text: preview,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: context.colors.onSurface,
                      ),
                    ),
                  ],
                ),
          if (hasOverflow && !_expanded) ...[
            SizedBox(height: 4),
            GestureDetector(
              onTap: () => setState(() => _expanded = true),
              child: Text(
                'daha fazla',
                style: TextStyle(
                  color: AppThemeColors.accentCyan,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
          if (hasOverflow && _expanded) ...[
            SizedBox(height: 4),
            GestureDetector(
              onTap: () => setState(() => _expanded = false),
              child: Text(
                'daha az',
                style: TextStyle(
                  color: context.colors.onSurfaceMuted,
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
        SocialLinkedCaptionText(
          text: preview,
          style: TextStyle(
            fontSize: 15,
            height: 1.45,
            fontWeight: FontWeight.w500,
            color: context.colors.onSurface,
          ),
        ),
        if (hasOverflow && !_expanded) ...[
          SizedBox(height: 6),
          GestureDetector(
            onTap: () => setState(() => _expanded = true),
            child: Text(
              'daha fazla',
              style: TextStyle(
                color: AppThemeColors.accentCyan,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
        if (hasOverflow && _expanded) ...[
          SizedBox(height: 6),
          GestureDetector(
            onTap: () => setState(() => _expanded = false),
            child: Text(
              'daha az',
              style: TextStyle(
                color: context.colors.onSurfaceMuted,
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
