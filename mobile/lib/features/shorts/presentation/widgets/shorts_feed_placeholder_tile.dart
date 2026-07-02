import 'package:flutter/material.dart';

import '../../../../core/widgets/hero_tags.dart';
import '../../domain/entities/shorts_feed_entry.dart';
import 'shorts_premium_theme.dart';

/// Uzak sayfalar — yalnızca thumbnail; video controller yok.
class ShortsFeedPlaceholderTile extends StatelessWidget {
  const ShortsFeedPlaceholderTile({
    super.key,
    required this.entry,
  });

  final ShortsFeedEntry entry;

  @override
  Widget build(BuildContext context) {
    final video = entry.video;
    final thumb = video?.thumbnailUrl;
    Widget body = ColoredBox(
      color: Colors.black,
      child: thumb != null && thumb.isNotEmpty
          ? Image.network(
              thumb,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) => const _BlackFill(),
            )
          : const _BlackFill(),
    );
    if (video != null) {
      body = HeroShortThumb(videoId: video.id, child: body);
    }
    return RepaintBoundary(child: body);
  }
}

class _BlackFill extends StatelessWidget {
  const _BlackFill();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ShortsPremiumTheme.feedBackground(context),
    );
  }
}
