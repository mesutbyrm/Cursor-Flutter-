import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';

import '../utils/social_feed_end_label.dart';

/// Sosyal akışın sonunda — sayfalama bittiğinde gösterilir.
class SocialFeedEndBanner extends StatelessWidget {
  const SocialFeedEndBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Center(
        child: Text(
          socialFeedEndReachedLabel,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.colors.onSurfaceMuted,
          ),
        ),
      ),
    );
  }
}
