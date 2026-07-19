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
import '../../../cosmetics/domain/cosmetic_item.dart';
import '../../../cosmetics/presentation/providers/cosmetics_providers.dart';
import '../../../cosmetics/presentation/widgets/cosmetic_avatar_frame.dart';
import '../../../cosmetics/presentation/widgets/cosmetic_name_label.dart';
import '../../../cosmetics/presentation/widgets/cosmetic_particle_overlay.dart';

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

    final topInset = MediaQuery.paddingOf(context).top;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            _CoverBanner(coverUrl: ext.coverImage, topInset: topInset),
            Positioned(
              left: 0,
              right: 0,
              bottom: -ProfilePremiumTheme.avatarOverlap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
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
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: CosmeticNameLabel(
                                    text: user.display,
                                    item: ref.watch(resolvedNameEffectProvider),
                                    maxLines: 1,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black54,
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (vipLabel != null) ...[
                                  const SizedBox(width: 6),
                                  _VipPill(label: vipLabel),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '@${user.username}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                shadows: const [
                                  Shadow(color: Colors.black54, blurRadius: 6),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ActionBtn(
                          icon: Icons.edit_rounded,
                          label: 'Düzenle',
                          onTap: () => context.push('/profile/edit'),
                        ),
                        const SizedBox(height: 6),
                        _ActionBtn(
                          icon: Icons.qr_code_2_rounded,
                          label: 'QR Kodum',
                          onTap: () => context.push('/profile/qr'),
                        ),
                        const SizedBox(height: 6),
                        _ActionBtn(
                          icon: Icons.settings_rounded,
                          label: 'Ayarlar',
                          onTap: () => context.push('/settings'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: ProfilePremiumTheme.avatarOverlap + 8),
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
  const _CoverBanner({this.coverUrl, this.topInset = 0});

  final String? coverUrl;
  final double topInset;

  @override
  Widget build(BuildContext context) {
    final height = ProfilePremiumTheme.coverHeight + topInset;
    return Hero(
      tag: 'profile-cover',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ProfilePremiumTheme.radiusLg),
        child: SizedBox(
          height: height,
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
              // Altta okunabilirlik için hafif karartma
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x00000000),
                      Color(0x99000000),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: -20,
                top: topInset - 10,
                child: Icon(
                  Icons.nightlight_round,
                  size: 88,
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

class _AvatarBlock extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final frame = ref.watch(resolvedProfileFrameProvider);
    final profileFx = ref.watch(resolvedProfileEffectProvider);

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CosmeticAvatarFrame(
            item: frame,
            size: 92,
            showParticles: false,
            child: UserAvatar(
              url: user.avatarUrl,
              radius: 40,
            ),
          ),
          if (profileFx != null)
            Positioned.fill(
              child: IgnorePointer(
                child: _ProfileFxHost(effect: profileFx),
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

class _ProfileFxHost extends StatefulWidget {
  const _ProfileFxHost({required this.effect});

  final CosmeticItem effect;

  @override
  State<_ProfileFxHost> createState() => _ProfileFxHostState();
}

class _ProfileFxHostState extends State<_ProfileFxHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CosmeticParticleOverlay(
      kind: widget.effect.effectKind,
      size: 92,
      controller: _ctrl,
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
