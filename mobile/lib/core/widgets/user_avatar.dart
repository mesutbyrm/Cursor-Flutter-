import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

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
    final r = BorderRadius.circular(radius);
    final side = (radius * 2).clamp(24.0, 128.0);
    final cachePx = side.round();
    if (url != null && url!.isNotEmpty) {
      return ClipRRect(
        borderRadius: r,
        child: CachedNetworkImage(
          imageUrl: url!,
          width: side,
          height: side,
          fit: BoxFit.cover,
          memCacheWidth: cachePx,
          memCacheHeight: cachePx,
          maxWidthDiskCache: 128,
          maxHeightDiskCache: 128,
          placeholder: (_, _) => _fallback(),
          errorWidget: (_, _, _) => _fallback(),
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
