import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../core/ui/premium/premium_skeleton.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/profile_extended_entity.dart';
import '../premium_2026/profile_screen_state.dart';
import '../premium_2026/profile_theme.dart';
import '../providers/profile_hub_providers.dart';
import 'profile_avatar_sheet.dart';

/// Referans profil başlığı — avatar, VIP, doğrulama, düzenle/QR/ayarlar.
class ProfileHubHeader extends ConsumerWidget {
  const ProfileHubHeader({
    super.key,
    required this.state,
    this.onRefresh,
  });

  final ProfileScreenState state;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = state.user;
    final extAsync = ref.watch(profileExtendedProvider);
    final ext = extAsync.valueOrNull ?? const ProfileExtendedEntity();
    final level = state.level;
    final vipLabel = _vipLabel(state, ext);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CoverBanner(coverUrl: ext.coverImage),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AvatarBlock(
              user: user,
              level: level.level,
              isVip: state.isVip,
              isOnline: ext.isOnline,
              isVerified: user.isVerified,
              onTap: () => showProfileAvatarSheet(
                context,
                ref,
                avatarUrl: user.avatarUrl,
                onUpdated: onRefresh ?? () {},
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.display,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (vipLabel != null) ...[
                        const SizedBox(width: 6),
                        _VipPill(label: vipLabel),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${user.username}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ID: ${user.id}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (user.isVerified) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          color: Color(0xFF29B6F6),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Doğrulanmış Üye',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (user.bio != null && user.bio!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      user.bio!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              children: [
                _ActionBtn(
                  icon: Icons.edit_rounded,
                  label: 'Düzenle',
                  onTap: () => context.push('/profile/edit'),
                ),
                const SizedBox(height: 8),
                _ActionBtn(
                  icon: Icons.qr_code_2_rounded,
                  label: 'QR Kodum',
                  onTap: () => context.push('/profile/qr'),
                ),
                const SizedBox(height: 8),
                _ActionBtn(
                  icon: Icons.settings_rounded,
                  label: 'Ayarlar',
                  onTap: () => context.push('/settings'),
                ),
              ],
            ),
          ],
        ),
        if (extAsync.isLoading && extAsync.valueOrNull == null)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: PremiumSkeleton(height: 12, width: 120),
          ),
      ],
    );
  }

  String? _vipLabel(ProfileScreenState state, ProfileExtendedEntity ext) {
    final m = state.membership?.trim();
    if (m != null && m.isNotEmpty) return '💎 $m';
    final v = ext.vipLevel?.trim();
    if (v != null && v.isNotEmpty) return '💎 $v';
    if (state.isVip) return '💎 VIP';
    return state.level.vipTier?.trim().isNotEmpty == true
        ? '💎 ${state.level.vipTier}'
        : null;
  }
}

class _CoverBanner extends StatelessWidget {
  const _CoverBanner({this.coverUrl});

  final String? coverUrl;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'profile-cover',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ProfilePremiumTheme.radiusLg),
        child: SizedBox(
          height: ProfilePremiumTheme.coverHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (coverUrl != null && coverUrl!.isNotEmpty)
                CanlifalNetworkImage(
                  url: coverUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  thumbnailWidth: 1080,
                )
              else
                _gradient(),
              Positioned(
                right: -20,
                top: -10,
                child: Icon(
                  Icons.nightlight_round,
                  size: 100,
                  color: ProfilePremiumTheme.neonPurple.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gradient() => DecoratedBox(
        decoration: BoxDecoration(
          gradient: ProfilePremiumTheme.coverGradient,
          border: Border.all(color: ProfilePremiumTheme.glassBorder),
        ),
      );
}

class _AvatarBlock extends StatelessWidget {
  const _AvatarBlock({
    required this.user,
    required this.level,
    required this.isVip,
    required this.isOnline,
    required this.isVerified,
    this.onTap,
  });

  final UserEntity user;
  final int level;
  final bool isVip;
  final bool isOnline;
  final bool isVerified;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  ProfilePremiumTheme.neonPink,
                  ProfilePremiumTheme.neonPurple,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: ProfilePremiumTheme.neonPurple.withValues(alpha: 0.45),
                  blurRadius: 24,
                ),
              ],
            ),
            child: UserAvatar(
              url: user.avatarUrl,
              radius: 42,
            ),
          ),
          if (isOnline)
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ProfilePremiumTheme.deepBg,
                    width: 2,
                  ),
                ),
              ),
            ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Material(
              color: ProfilePremiumTheme.neonPurple,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VipPill extends StatelessWidget {
  const _VipPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: ProfilePremiumTheme.premiumGradient,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
