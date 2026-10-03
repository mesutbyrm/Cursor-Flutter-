import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/site_animation/presentation/site_animation_profile_providers.dart';
import '../../../../core/site_animation/presentation/widgets/site_animation_framed_avatar.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/mock_ui_kit.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../cosmetics/presentation/providers/cosmetics_providers.dart';
import '../../../cosmetics/presentation/widgets/cosmetic_avatar_frame.dart';
import '../../../cosmetics/presentation/widgets/cosmetic_name_label.dart';
import '../../domain/entities/profile_extended_entity.dart';
import '../premium_2026/profile_membership_helpers.dart';
import '../premium_2026/profile_screen_state.dart';
import '../providers/profile_hub_providers.dart';
import 'profile_avatar_sheet.dart';

String _short(int v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
  return '$v';
}

/// Profil üst bölümü (mockup): logo + paylaş/ayar · ortalanmış avatar ·
/// kullanıcı adı · 4 istatistik · biyografi/konum · iki buton · cüzdan satırı.
class MockProfileHeader extends ConsumerWidget {
  const MockProfileHeader({
    super.key,
    required this.state,
    this.postCount,
    this.onRefresh,
  });

  final ProfileScreenState state;

  /// Yüklenen gönderi sayısı (bilinmiyorsa null → "—").
  final int? postCount;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final user = state.user;
    final ext =
        ref.watch(profileExtendedProvider).valueOrNull ??
        const ProfileExtendedEntity();
    final vipLabel = buildMembershipHubVipPillLabel(
      info: ref.watch(profileMembershipInfoProvider),
      membershipExpiresAt: state.wallet?.membershipExpiresAt,
      extVipLevel: ext.vipLevel,
      fallbackStateIsVip: state.isVip,
      levelVipTier: state.level.vipTier,
    );
    final frame = ref.watch(resolvedProfileFrameProvider);
    final siteFrame = ref.watch(resolvedSiteAnimationProfileFrameProvider);
    final nf = NumberFormat.decimalPattern('tr');
    final bio = (user.bio ?? '').trim();
    final city = (ext.city ?? '').trim();
    final url = 'https://canlifal.com/@${user.username}';

    void share() => unawaited(
      SharePlus.instance.share(
        ShareParams(text: url, subject: '${user.display} — Canlifal'),
      ),
    );

    final avatar = GestureDetector(
      onTap: () => showProfileAvatarSheet(
        context,
        ref,
        avatarUrl: user.avatarUrl,
        onUpdated: onRefresh ?? () {},
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF59E0B), Color(0xFFEC4899), Color(0xFF8B5CF6)],
              ),
            ),
            child: siteFrame != null
                ? SiteAnimationFramedAvatar(
                    entry: siteFrame,
                    size: 88,
                    child: UserAvatar(url: user.avatarUrl, radius: 40),
                  )
                : CosmeticAvatarFrame(
                    item: frame,
                    size: 88,
                    showParticles: false,
                    child: UserAvatar(url: user.avatarUrl, radius: 40),
                  ),
          ),
          if (ext.isOnline)
            PositionedDirectional(
              bottom: -6,
              start: 0,
              child: _Chip(
                label: 'Çevrimiçi',
                color: const Color(0xFF16A34A),
                dot: true,
              ),
            ),
          if (vipLabel != null)
            PositionedDirectional(
              bottom: -4,
              end: -6,
              child: _Chip(
                label: 'VIP',
                color: const Color(0xFF7C3AED),
                star: true,
              ),
            ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 44,
          child: Row(
            children: [
              Image.asset(
                'assets/brand/canlifal_logo_horizontal.png',
                height: 26,
                errorBuilder: (_, _, _) => Text(
                  'CanlıFal',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: c.onSurface,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Paylaş',
                icon: const Icon(Icons.ios_share_rounded, size: 22),
                onPressed: share,
              ),
              IconButton(
                tooltip: 'Ayarlar',
                icon: const Icon(Icons.settings_outlined, size: 23),
                onPressed: () => context.push('/settings'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Center(child: avatar),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                '@${user.username}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: c.onSurface,
                ),
              ),
            ),
            if (user.isVerified) ...[
              const SizedBox(width: 5),
              const Icon(
                Icons.verified_rounded,
                size: 17,
                color: Color(0xFF3B9DFF),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Center(
          child: CosmeticNameLabel(
            text: user.display,
            item: ref.watch(resolvedNameEffectProvider),
            maxLines: 1,
            style: TextStyle(
              color: c.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _Stat(
              value: postCount == null ? '—' : nf.format(postCount),
              label: 'Gönderi',
            ),
            _Stat(
              value: _short(state.followers),
              label: 'Takipçi',
              onTap: () =>
                  context.push('/profile/followers?userId=${user.id}'),
            ),
            _Stat(
              value: nf.format(state.following),
              label: 'Takip',
              onTap: () =>
                  context.push('/profile/following?userId=${user.id}'),
            ),
            _Stat(value: _short(state.likes), label: 'Beğeni'),
          ],
        ),
        if (bio.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            bio,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: c.onSurface,
            ),
          ),
        ],
        if (city.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on_outlined, size: 14, color: c.onSurfaceMuted),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  city,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: c.onSurfaceMuted),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _OutlineButton(
                label: 'Profili Düzenle',
                onTap: () => context.push('/profile/edit'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _OutlineButton(
                label: 'Paylaş',
                icon: Icons.ios_share_rounded,
                onTap: share,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _WalletChip(
                icon: Icons.monetization_on_rounded,
                color: const Color(0xFFF59E0B),
                text: '${nf.format(state.jeton)} Jeton',
                onTap: () => context.push('/wallet'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _WalletChip(
                icon: Icons.diamond_rounded,
                color: const Color(0xFF8B5CF6),
                text: '${nf.format(state.cfc)} CFC',
                onTap: () => context.push('/wallet'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.color,
    this.dot = false,
    this.star = false,
  });

  final String label;
  final Color color;
  final bool dot;
  final bool star;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Theme.of(context).scaffoldBackgroundColor,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsetsDirectional.only(end: 4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          if (star)
            const Padding(
              padding: EdgeInsetsDirectional.only(end: 3),
              child: Icon(Icons.star_rounded, size: 11, color: Colors.white),
            ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.onTap});

  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: c.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(fontSize: 11, color: c.onSurfaceMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({required this.label, required this.onTap, this.icon});

  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          height: 42,
          decoration: BoxDecoration(
            color: mockCardColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: mockCardBorder(context)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: c.onSurface),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: c.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletChip extends StatelessWidget {
  const _WalletChip({
    required this.icon,
    required this.color,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  text,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: c.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
