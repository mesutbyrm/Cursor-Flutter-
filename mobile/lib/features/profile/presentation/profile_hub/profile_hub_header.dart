import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../core/ui/premium/premium_skeleton.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/profile_extended_entity.dart';
import '../premium_2026/profile_membership_helpers.dart';
import '../../../admin/presentation/providers/staff_access_provider.dart';
import '../premium_2026/profile_screen_state.dart';
import '../premium_2026/profile_theme.dart';
import '../providers/profile_hub_providers.dart';
import 'profile_avatar_sheet.dart';
import 'profile_meta_helpers.dart';
import '../../../cosmetics/domain/cosmetic_item.dart';
import '../../../cosmetics/presentation/providers/cosmetics_providers.dart';
import '../../../cosmetics/presentation/widgets/cosmetic_avatar_frame.dart';
import '../../../cosmetics/presentation/widgets/cosmetic_name_label.dart';
import '../../../cosmetics/presentation/widgets/cosmetic_particle_overlay.dart';
import '../../../../core/site_animation/presentation/widgets/site_animation_avatar_effect.dart';
import '../../../../core/site_animation/presentation/site_animation_profile_providers.dart';
import '../../../../core/site_animation/presentation/widgets/site_animation_framed_avatar.dart';
import '../../../../core/site_animation/presentation/widgets/site_animation_profile_entrance_stagger.dart';

/// Referans profil başlığı
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
    final vipLabel = buildMembershipHubVipPillLabel(
      info: ref.watch(profileMembershipInfoProvider),
      membershipExpiresAt: state.wallet?.membershipExpiresAt,
      extVipLevel: ext.vipLevel,
      fallbackStateIsVip: state.isVip,
      levelVipTier: state.level.vipTier,
    );

    final topInset = MediaQuery.paddingOf(context).top;
    final siteFrame = ref.watch(resolvedSiteAnimationProfileFrameProvider);
    final siteAvatarFx = ref.watch(resolvedSiteAnimationAvatarEffectProvider);
    final useProfileStagger = siteFrame != null || siteAvatarFx != null;
    final staff = ref.watch(staffAccessProvider);

    final avatarBlock = _AvatarBlock(
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
    );

    final nameRow = Row(
      children: [
        Expanded(
          child: CosmeticNameLabel(
            text: user.display,
            item: ref.watch(resolvedNameEffectProvider),
            maxLines: 1,
            style: TextStyle(
              color: ProfilePremiumTheme.textOf(context),
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ),
        if (vipLabel != null) ...[
          const SizedBox(width: 6),
          _VipPill(label: vipLabel),
        ],
        _MembershipBadgeChip(
          badge: ref.watch(resolvedMembershipBadgeProvider),
        ),
      ],
    );

    final membershipRow = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '@${user.username}',
          style: TextStyle(
            color: ProfilePremiumTheme.textSecondaryOf(context),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        _ProfileMetaChips(
          zodiac: ext.zodiacSign,
          team: ext.favoriteTeam ?? state.wallet?.favoriteTeam,
        ),
        if (staff.isStaffMember) ...[
          const SizedBox(height: 6),
          _StaffRoleChip(label: staff.roleLabel),
        ],
      ],
    );

    // Avatar kapağın altına biner; kimlik bloğu kapağın ALTINDA durur ki
    // metin her temada sayfa zemini üzerinde okunur olsun.
    const avatarDrop = 46.0;
    const avatarInset = 12.0;
    final identity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [nameRow, const SizedBox(height: 2), membershipRow],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            _CoverBanner(coverUrl: ext.coverImage, topInset: topInset),
            if (!useProfileStagger)
              Positioned(
                left: avatarInset,
                bottom: -avatarDrop,
                child: avatarBlock,
              ),
          ],
        ),
        if (useProfileStagger)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: SiteAnimationProfileEntranceStagger(
              layout: SiteAnimationProfileStaggerLayout.horizontal,
              avatarSpacing: 14,
              avatar: avatarBlock,
              nameRow: nameRow,
              membershipRow: membershipRow,
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(
              left: avatarInset + 92 + 12,
              top: 8,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: avatarDrop - 8),
              child: identity,
            ),
          ),
        const SizedBox(height: 14),
        _ProfileActionsRow(
          onEdit: () => context.push('/profile/edit'),
          onQr: () => context.push('/profile/qr'),
          onSettings: () => context.push('/settings'),
        ),
        const SizedBox(height: 10),
        Text(
          'ID: ${user.id}',
          style: TextStyle(
            color: ProfilePremiumTheme.textMutedOf(context),
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
                  color: ProfilePremiumTheme.textSecondaryOf(context),
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
              color: ProfilePremiumTheme.textSecondaryOf(context),
              fontSize: 13,
              height: 1.4,
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
    final siteFrame = ref.watch(resolvedSiteAnimationProfileFrameProvider);
    final siteAvatarFx = ref.watch(resolvedSiteAnimationAvatarEffectProvider);
    final profileFx = ref.watch(resolvedProfileEffectProvider);

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (siteFrame != null)
            SiteAnimationFramedAvatar(
              entry: siteFrame,
              size: 92,
              child: UserAvatar(url: user.avatarUrl, radius: 40),
            )
          else
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
          if (siteAvatarFx != null)
            Positioned.fill(
              child: SiteAnimationAvatarEffectOverlay(
                entry: siteAvatarFx,
                size: 92,
              ),
            ),
          Positioned(
            left: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ProfilePremiumTheme.neonPurple,
                    ProfilePremiumTheme.neonPink,
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 1.5,
                ),
              ),
              child: Text(
                'Lv.$level',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
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
                    color: Theme.of(context).scaffoldBackgroundColor,
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
                  padding: EdgeInsets.all(7),
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

class _MembershipBadgeChip extends StatelessWidget {
  const _MembershipBadgeChip({required this.badge});

  final CosmeticItem? badge;

  @override
  Widget build(BuildContext context) {
    if (badge == null) return const SizedBox.shrink();
    final url = badge!.previewUrl ?? badge!.assetUrl;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: url != null && url.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CanlifalNetworkImage(
                url: url,
                width: 22,
                height: 22,
                fit: BoxFit.cover,
                thumbnailWidth: 48,
              ),
            )
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: ProfilePremiumTheme.insetOf(context, darkAlpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge!.name,
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
              ),
            ),
    );
  }
}

class _ProfileMetaChips extends StatelessWidget {
  const _ProfileMetaChips({this.zodiac, this.team});

  final String? zodiac;
  final String? team;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    final z = zodiac?.trim();
    if (z != null && z.isNotEmpty) {
      final emoji = profileZodiacEmoji(z);
      chips.add(_MetaChip(
        label: emoji != null
            ? '$emoji ${profileZodiacLabelTr(z)}'
            : profileZodiacLabelTr(z),
      ));
    }
    final t = team?.trim();
    if (t != null && t.isNotEmpty) {
      chips.add(_MetaChip(label: t, icon: Icons.sports_soccer_rounded));
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: chips,
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: ProfilePremiumTheme.insetOf(context, darkAlpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ProfilePremiumTheme.borderOf(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 11,
              color: ProfilePremiumTheme.textSecondaryOf(context),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: ProfilePremiumTheme.textSecondaryOf(context),
              fontSize: 10,
              fontWeight: FontWeight.w700,
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

/// Instagram tarzı eylem satırı — tüm genişlikte, temaya duyarlı.
class _ProfileActionsRow extends StatelessWidget {
  const _ProfileActionsRow({
    required this.onEdit,
    required this.onQr,
    required this.onSettings,
  });

  final VoidCallback onEdit;
  final VoidCallback onQr;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    const compact = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(0, 40)),
      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12)),
      visualDensity: VisualDensity.compact,
    );
    return Row(
      children: [
        Expanded(
          child: FilledButton.tonalIcon(
            style: compact,
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: const Text('Düzenle', maxLines: 1),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            style: compact,
            onPressed: onQr,
            icon: const Icon(Icons.qr_code_2_rounded, size: 18),
            label: const Text('QR Kodum', maxLines: 1),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.outlined(
          tooltip: 'Ayarlar',
          onPressed: onSettings,
          constraints: const BoxConstraints.tightFor(width: 40, height: 40),
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(
            side: BorderSide(color: Theme.of(context).colorScheme.outline),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: const Icon(Icons.settings_rounded, size: 20),
        ),
      ],
    );
  }
}

class _StaffRoleChip extends StatelessWidget {
  const _StaffRoleChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cyan = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF25F4EE)
        : Theme.of(context).colorScheme.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cyan.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cyan.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user_rounded, size: 12, color: cyan),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: cyan,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
