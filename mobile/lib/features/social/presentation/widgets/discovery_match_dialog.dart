import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../platform_social/presentation/widgets/platform_social_ui_kit.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/entities/social_discovery_user.dart';

Future<void> showDiscoveryMatchDialog(
  BuildContext context, {
  required SocialDiscoveryUser matchedUser,
  String? myAvatarUrl,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Eşleşme',
    barrierColor: Colors.black.withValues(alpha: 0.75),
    pageBuilder: (ctx, _, _) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Material(
            color: Colors.transparent,
            child: PlatformSocialGlassCard(
              gradient: PlatformSocialPalette.heroGradient,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Eşleştiniz!',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${matchedUser.displayName} ile karşılıklı beğeni',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      UserAvatar(url: myAvatarUrl, radius: 36),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(
                          Icons.favorite_rounded,
                          color: PlatformSocialPalette.accent,
                          size: 32,
                        ),
                      ),
                      UserAvatar(url: matchedUser.avatarUrl, radius: 36),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: PlatformSocialPrimaryButton(
                      label: 'Mesaj Gönder',
                      icon: Icons.chat_bubble_rounded,
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        context.push('/chat/${matchedUser.id}');
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Keşfete devam'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
