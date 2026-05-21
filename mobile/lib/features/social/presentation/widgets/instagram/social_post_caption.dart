import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../feed/domain/entities/post_entity.dart';

const _previewWordLimit = 300;

/// Gönderi metni: 300 kelime önizleme, «daha fazla», «devamını oku», birlikte bakanlar.
class SocialPostCaption extends StatefulWidget {
  const SocialPostCaption({
    super.key,
    required this.post,
    this.inlineBodyOnly = false,
  });

  final PostEntity post;
  /// Akışta yalnızca gövde metni (kullanıcı adı başlıkta).
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
    if (text.isEmpty && post.fortuneCount <= 0) return const SizedBox.shrink();

    final words = _splitWords(text);
    final hasOverflow = words.length > _previewWordLimit;
    final preview = hasOverflow && !_expanded
        ? words.take(_previewWordLimit).join(' ')
        : text;
    final showCoViewers = post.fortuneCount > 0;
    final showReadMore = showCoViewers || (hasOverflow && !_expanded);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (text.isNotEmpty)
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
          if (showReadMore) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: hasOverflow && !_expanded
                  ? () => setState(() => _expanded = true)
                  : null,
              child: Text(
                'devamını oku',
                style: TextStyle(
                  color: AppColors.textMuted.withValues(alpha: 0.95),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (showCoViewers) ...[
            const SizedBox(height: 4),
            Text(
              _coViewersLine(post),
              style: TextStyle(
                color: AppColors.accentPurple.withValues(alpha: 0.95),
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
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

  static List<String> _splitWords(String text) {
    return text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  }

  static String _coViewersLine(PostEntity post) {
    final n = post.fortuneCount;
    final label = _shareSubjectLabel(post);
    return 'Bu kullanıcı ile birlikte $n kişi $label baktı';
  }

  static String _shareSubjectLabel(PostEntity post) {
    if (post.fortuneType != null && post.fortuneType!.isNotEmpty) {
      return 'bu ${_fortuneLabel(post.fortuneType!)} falına';
    }
    if (post.postType == 'fortune') return 'bu fala';
    if (post.postType == 'text') return 'bu paylaşıma';
    return 'buna';
  }

  static String _fortuneLabel(String type) {
    return switch (type) {
      'kahve-fali' || 'coffee' => 'kahve',
      'tarot' || 'gunluk-tarot' => 'tarot',
      'ruya-yorumu' => 'rüya yorumu',
      'palm' => 'el',
      'love' => 'aşk',
      'angel' => 'melek',
      'katina' => 'katina',
      'yesno' || 'evet-hayir' => 'evet/hayır',
      'istikhara' => 'istihare',
      'astroloji' => 'astroloji',
      _ => type.replaceAll('-', ' '),
    };
  }
}
