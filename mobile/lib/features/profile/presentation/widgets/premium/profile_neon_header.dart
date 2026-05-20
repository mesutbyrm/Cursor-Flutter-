import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/user_avatar.dart';
import 'profile_glass.dart';

class ProfileNeonHeader extends StatelessWidget {
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
    this.onSettings,
    this.onEdit,
    this.onNotifications,
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
  final VoidCallback? onSettings;
  final VoidCallback? onEdit;
  final VoidCallback? onNotifications;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
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
            if (diamondBalance != null) _DiamondPill(balance: diamondBalance!),
            const SizedBox(width: 8),
            _TopIconButton(icon: Icons.edit_rounded, onPressed: onEdit),
            if (onNotifications != null) ...[
              const SizedBox(width: 4),
              _TopIconButton(
                icon: Icons.notifications_none_rounded,
                onPressed: onNotifications,
              ),
            ],
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
        Center(child: _NeonAvatar(url: avatarUrl)),
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
              ),
            ),
            _statDivider(),
            Expanded(
              child: _StatColumn(
                value: profileFormatCount(following),
                label: 'Takip',
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

class _DiamondPill extends StatelessWidget {
  const _DiamondPill({required this.balance});

  final int balance;

  @override
  Widget build(BuildContext context) {
    return ProfileGlass(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: 20,
      borderColor: const Color(0xFF5B8CFF).withValues(alpha: 0.45),
      blur: 8,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6EB5FF).withValues(alpha: 0.9),
                  const Color(0xFF3D6BFF).withValues(alpha: 0.9),
                ],
              ),
              boxShadow: AppColors.glowShadow(
                const Color(0xFF5B8CFF),
                blur: 12,
              ),
            ),
            child: const Icon(
              Icons.diamond_rounded,
              size: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            profileFormatCoins(balance),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.add_circle_rounded,
            size: 16,
            color: AppColors.accentCyan.withValues(alpha: 0.9),
          ),
        ],
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
  const _StatColumn({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }
}
