import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/widgets/dual_balance_chips.dart';
import '../../../../../core/widgets/messages_notifications_actions.dart';
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
  final VoidCallback? onEdit;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onFollowersTap;
  final VoidCallback? onFollowingTap;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeroBanner(),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text('Profilim', style: ProfileTypography.pageTitle(context)),
            ),
            if (diamondBalance != null)
              DualBalanceChips(
                jeton: diamondBalance!,
                cfc: cfcBalance,
                compact: true,
              ),
            const SizedBox(width: 8),
            _TopIconButton(icon: Icons.edit_rounded, onPressed: onEdit),
            const SizedBox(width: 4),
            const MessagesNotificationsActions(spacing: 4, iconSize: 40),
            if (onLogout != null) ...[
              const SizedBox(width: 4),
              _TopIconButton(icon: Icons.logout_rounded, onPressed: onLogout),
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
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                displayName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: ProfileTypography.displayName(context),
              ),
            ),
            const SizedBox(width: 6),
            ShaderMask(
              shaderCallback: (b) => c.brandGradient.createShader(b),
              child: const Icon(
                Icons.verified_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '@$username',
          textAlign: TextAlign.center,
          style: ProfileTypography.username(context),
        ),
        const SizedBox(height: 20),
        ProfileGlass(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          borderColor: c.glassBorder,
          child: Row(
            children: [
              Expanded(
                child: _StatColumn(
                  value: profileFormatCount(liveStreams),
                  label: 'Canlı Yayın',
                ),
              ),
              _statDivider(c),
              Expanded(
                child: _StatColumn(
                  value: profileFormatCount(followers),
                  label: 'Takipçi',
                  onTap: onFollowersTap,
                ),
              ),
              _statDivider(c),
              Expanded(
                child: _StatColumn(
                  value: profileFormatCount(following),
                  label: 'Takip',
                  onTap: onFollowingTap,
                ),
              ),
              _statDivider(c),
              Expanded(
                child: _StatColumn(
                  value: profileFormatCount(likes),
                  label: 'Beğeni',
                ),
              ),
            ],
          ),
        ),
        if (bio != null && bio!.trim().isNotEmpty) ...[
          const SizedBox(height: 14),
          ProfileGlass(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.format_quote_rounded,
                  size: 20,
                  color: AppThemeColors.accentPurple.withValues(alpha: 0.85),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(bio!.trim(), style: ProfileTypography.body(context)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _statDivider(AppThemeColors c) {
    return Container(
      width: 1,
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      color: c.divider.withValues(alpha: 0.65),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 108,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF2A1248),
                    AppThemeColors.accentPurple.withValues(alpha: 0.75),
                    AppThemeColors.accentPink.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
            Positioned(
              right: -24,
              top: -18,
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 96,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            Positioned(
              left: 16,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CanlıFal',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Profil vitrinin',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({required this.icon, this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.glassFillElevated,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Icon(icon, size: 21, color: c.onSurface),
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
        gradient: context.colors.brandGradient,
        boxShadow: [
          BoxShadow(
            color: AppThemeColors.accentPink.withValues(alpha: 0.45),
            blurRadius: 28,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: AppThemeColors.accentPurple.withValues(alpha: 0.35),
            blurRadius: 40,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.scaffoldBg,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            UserAvatar(url: url, radius: 52),
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: context.colors.brandGradient,
                  border: Border.all(color: context.scaffoldBg, width: 2.5),
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
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Column(
            children: [
              Text(value, style: ProfileTypography.statValue(context)),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: ProfileTypography.statLabel(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
