import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../widgets/premium/profile_glass.dart';
import '../profile_screen_state.dart';
import '../profile_theme.dart';

/// Tek satır premium istatistik kartı.
class ProfileStats extends StatelessWidget {
  const ProfileStats({
    super.key,
    required this.state,
    this.onFollowersTap,
    this.onFollowingTap,
  });

  final ProfileScreenState state;
  final VoidCallback? onFollowersTap;
  final VoidCallback? onFollowingTap;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ProfileGlass(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        borderRadius: ProfilePremiumTheme.radiusMd,
        borderColor: ProfilePremiumTheme.glassBorder,
        child: Row(
          children: [
            Expanded(
              child: _StatCell(
                label: 'Takipçi',
                value: profileFormatCount(state.followers),
                onTap: onFollowersTap,
              ),
            ),
            _divider(),
            Expanded(
              child: _StatCell(
                label: 'Takip',
                value: profileFormatCount(state.following),
                onTap: onFollowingTap,
              ),
            ),
            _divider(),
            Expanded(
              child: _StatCell(
                label: 'Beğeni',
                value: profileFormatCount(state.likes),
              ),
            ),
            _divider(),
            Expanded(
              child: _StatCell(
                label: 'Yayın',
                value: profileFormatCount(state.liveStreams),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.06, end: 0),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 36,
        color: Colors.white.withValues(alpha: 0.1),
      );
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
