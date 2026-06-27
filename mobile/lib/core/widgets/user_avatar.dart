import 'package:flutter/material.dart';

import '../images/canlifal_image_urls.dart';
import '../images/canlifal_network_image.dart';
import '../theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.url,
    this.radius = 22,
  });

  final String? url;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final side = (radius * 2).clamp(24.0, 128.0);
    if (url != null && url!.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CanlifalNetworkImage(
          url: url,
          width: side,
          height: side,
          fit: BoxFit.cover,
          thumbnailWidth: CanlifalImageUrls.avatarThumbnailWidth,
          errorWidget: _fallback(),
          placeholder: _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.surfaceElevated,
      child: Icon(Icons.person, color: AppTheme.muted, size: radius),
    );
  }
}
