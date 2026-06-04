import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/user_avatar.dart';

/// canlifal.com ana sayfa — yuvarlak avatar halkası (sesli oda / falcı).
class HomeCircularOrb extends StatelessWidget {
  const HomeCircularOrb({
    super.key,
    required this.title,
    required this.ringColor,
    required this.onTap,
    this.subtitle,
    this.imageUrl,
    this.badge,
    this.size = 72,
  });

  final String title;
  final String? subtitle;
  final String? imageUrl;
  final Color ringColor;
  final VoidCallback onTap;
  final Widget? badge;
  final double size;

  @override
  Widget build(BuildContext context) {
    final avatarR = (size - 6) / 2;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size + 4,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [ringColor, ringColor.withValues(alpha: 0.4)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: ringColor.withValues(alpha: 0.35),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: imageUrl != null && imageUrl!.isNotEmpty
                      ? CircleAvatar(
                          radius: avatarR,
                          backgroundImage: CachedNetworkImageProvider(
                            imageUrl!,
                          ),
                        )
                      : UserAvatar(radius: avatarR),
                ),
                if (badge != null)
                  Positioned(left: 0, top: 0, child: badge!),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: context.colors.onSurface,
              ),
            ),
            if (subtitle != null && subtitle!.isNotEmpty)
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: context.colors.onSurfaceMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
