import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/messages_notifications_actions.dart';
import '../../../../../core/widgets/dual_balance_chips.dart';
import '../../../../../core/widgets/user_avatar.dart';
import 'profile_glass.dart';

class ProfileNeonHeader extends ConsumerWidget {
  const ProfileNeonHeader({
    super.key,
    required this.displayName,
    required this.username,
    required this.avatarUrl,
    required this.followers,
    required this.following,
    this.bio,
    this.liveStreams = 0,
    this.likes = 0,
    this.diamondBalance,
    this.cfcBalance = 0,
    this.onSettings,
    this.onEdit,
    this.onAvatarTap,
    this.onFollowersTap,
    this.onFollowingTap,
    this.onLogout,
  });

  final String displayName;
  final String username;
  final String? avatarUrl;
  final int followers;
  final int following;
  final String? bio;
  final int liveStreams;
  final int likes;
  final int? diamondBalance;
  final int cfcBalance;
  final VoidCallback? onSettings;
  final VoidCallback? onEdit;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onFollowersTap;
  final VoidCallback? onFollowingTap;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _TopIconButton(
              icon: Icons.settings_rounded,
              onPressed: onSettings,
            ),
            const Spacer(),
            if (diamondBalance != null)
              DualBalanceChips(
                jeton: diamondBalance!,
                cfc: cfcBalance,
                compact: true,
              ),
            const SizedBox(width: 8),
            _TopIconButton(icon: Icons.edit_rounded, onPressed: onEdit),
            const SizedBox(width: 4),
            const MessagesNotificationsActions(spacing: 4, iconSize: 36),
            if (onLogout != null) ...[
              const SizedBox(width: 4),
              _TopIconButton(
                icon: Icons.logout_rounded,
                onPressed: onLogout,
              ),
            ],
          ],
        ),
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: onAvatarTap ?? onEdit,
            child: _NeonAvatar(url: avatarUrl),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              displayName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 6),
            ShaderMask(
              shaderCallback: (b) => AppColors.brandGradient.createShader(b),
              child: const Icon(
                Icons.verified_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '@$username',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _StatColumn(
                value: profileFormatCount(liveStreams),
                label: 'Canlı Yayın',
              ),
            ),
            _statDivider(),
            Expanded(
              child: _StatColumn(
                value: profileFormatCount(followers),
                label: 'Takipçi',
                onTap: onFollowersTap,
              ),
            ),
            _statDivider(),
            Expanded(
              child: _StatColumn(
                value: profileFormatCount(following),
                label: 'Takip',
                onTap: onFollowingTap,
              ),
            ),
            _statDivider(),
            Expanded(
              child: _StatColumn(
                value: profileFormatCount(likes),
                label: 'Beğeni',
              ),
            ),
          ],
        ),
        if (bio != null && bio!.trim().isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            bio!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ],
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Colors.white.withValues(alpha: 0.08),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({required this.icon, this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _NeonAvatar extends StatelessWidget {
  const _NeonAvatar({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.brandGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.accentPink.withValues(alpha: 0.55),
            blurRadius: 32,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: AppColors.accentPurple.withValues(alpha: 0.4),
            blurRadius: 48,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.background,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            UserAvatar(url: url, radius: 48),
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.brandGradient,
                  border: Border.all(color: AppColors.background, width: 2),
                ),
                child: const Icon(
                  Icons.star_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.value,
    required this.label,
    this.onTap,
  });

  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
