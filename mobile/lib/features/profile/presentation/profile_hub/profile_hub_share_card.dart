import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../premium_2026/profile_theme.dart';
import '../widgets/premium/profile_glass.dart';

/// Profil paylaşım kartı.
class ProfileHubShareCard extends StatelessWidget {
  const ProfileHubShareCard({
    super.key,
    required this.username,
    required this.displayName,
  });

  final String username;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    final url = 'https://canlifal.com/@$username';

    return ProfileGlass(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: ProfilePremiumTheme.radiusMd,
      child: InkWell(
        onTap: () => SharePlus.instance.share(
          ShareParams(text: url, subject: '$displayName — Canlifal'),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Profilimi Paylaş',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Profil linkini arkadaşlarınla paylaş!',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.ios_share_rounded,
              color: ProfilePremiumTheme.neonPurple,
            ),
          ],
        ),
      ),
    );
  }
}
