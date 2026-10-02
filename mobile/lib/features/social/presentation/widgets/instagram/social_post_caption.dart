import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';

import '../../../../feed/domain/entities/post_entity.dart';

import 'social_expandable_caption.dart';

/// Gönderi metni — ekrana sığdığı kadar gösterilir, "Daha fazla" ile açılır.
class SocialPostCaption extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final text = (bodyText ?? post.caption)?.trim() ?? '';
    if (text.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
      child: inlineBodyOnly
          ? SocialExpandableCaption(
              text: text,
              maxLines: 4,
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
                SocialExpandableCaption(
                  text: text,
                  maxLines: 4,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: context.colors.onSurface,
                  ),
                ),
              ],
            ),
    );
  }
}

/// Metin gönderileri için önizleme (ekrana sığdığı kadar + "Daha fazla").
class SocialPostTextPreview extends StatelessWidget {
  const SocialPostTextPreview({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SocialExpandableCaption(
      text: text.trim(),
      maxLines: 6,
      style: TextStyle(
        fontSize: 15,
        height: 1.45,
        fontWeight: FontWeight.w500,
        color: context.colors.onSurface,
      ),
    );
  }
}
