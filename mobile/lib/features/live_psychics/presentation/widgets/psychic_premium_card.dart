import 'package:flutter/material.dart';

import '../../../../core/images/canlifal_network_image.dart';
import '../../../../core/ui/premium/premium_skeleton.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../home/presentation/theme/home_approved_design.dart';
import '../../../home/presentation/theme/home_premium_design.dart';

/// Canlı falcı kart iskeleti — avatar + metin alanları.
class PsychicPremiumCardSkeleton extends StatelessWidget {
  const PsychicPremiumCardSkeleton({
    super.key,
    this.width = PsychicPremiumCard.cardWidth,
    this.height = PsychicPremiumCard.cardHeight,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return PremiumSkeleton(
      width: width,
      height: height,
      borderRadius: BorderRadius.all(
        Radius.circular(PsychicPremiumCard.radius),
      ),
    );
  }
}

/// Ana sayfa yatay kart — premium V2.
class PsychicPremiumCard extends StatelessWidget {
  const PsychicPremiumCard({
    super.key,
    required this.name,
    required this.avatarUrl,
    required this.isOnline,
    required this.rating,
    required this.reviewCount,
    required this.categoryLabel,
    required this.pricePerMinute,
    required this.onTap,
    this.showLiveBadge = false,
  });

  static const cardWidth = 148.0;
  static const cardHeight = 204.0;
  static const radius = 20.0;

  final String name;
  final String? avatarUrl;
  final bool isOnline;
  final double rating;
  final int reviewCount;
  final String categoryLabel;
  final int pricePerMinute;
  final VoidCallback onTap;
  final bool showLiveBadge;

  @override
  Widget build(BuildContext context) {
    final trimmed = avatarUrl?.trim();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          width: cardWidth,
          height: cardHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: isOnline
                  ? HomePremiumDesign.accent.withValues(alpha: 0.42)
                  : HomeApprovedDesign.border,
            ),
            boxShadow: [
              BoxShadow(
                color: (isOnline ? HomePremiumDesign.accent : Colors.black)
                    .withValues(alpha: isOnline ? 0.22 : 0.35),
                blurRadius: isOnline ? 14 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                SizedBox.expand(
                  child: trimmed != null && trimmed.isNotEmpty
                      ? CanlifalNetworkImage(
                          url: trimmed,
                          fit: BoxFit.cover,
                          errorWidget: UserAvatar(url: null, radius: 44),
                          placeholder: UserAvatar(url: null, radius: 44),
                        )
                      : UserAvatar(url: null, radius: 44),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.08),
                        Colors.black.withValues(alpha: 0.55),
                        Colors.black.withValues(alpha: 0.88),
                      ],
                      stops: const [0.35, 0.62, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  right: 8,
                  child: Row(
                    children: [
                      if (showLiveBadge)
                        _StatusPill(
                          label: 'CANLI',
                          color: HomeApprovedDesign.liveRed,
                        )
                      else if (isOnline)
                        _StatusPill(
                          label: 'MÜSAİT',
                          color: HomeApprovedDesign.green,
                        )
                      else
                        _StatusPill(
                          label: 'ÇEVRİMDIŞI',
                          color: Colors.black54,
                        ),
                      const Spacer(),
                    ],
                  ),
                ),
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      PsychicRatingRow(
                        rating: rating,
                        reviewCount: reviewCount,
                        compact: true,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        categoryLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.78),
                        ),
                      ),
                      if (pricePerMinute > 0) ...[
                        const SizedBox(height: 5),
                        Text(
                          '$pricePerMinute jeton/dk',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: HomeApprovedDesign.gold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PsychicPremiumListTile extends StatelessWidget {
  const PsychicPremiumListTile({
    super.key,
    required this.name,
    required this.avatarUrl,
    required this.isOnline,
    required this.rating,
    required this.reviewCount,
    required this.categoryLabel,
    required this.pricePerMinute,
    required this.onTap,
    this.showLiveBadge = false,
  });

  final String name;
  final String? avatarUrl;
  final bool isOnline;
  final double rating;
  final int reviewCount;
  final String categoryLabel;
  final int pricePerMinute;
  final VoidCallback onTap;
  final bool showLiveBadge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HomePremiumDesign.surface.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(PsychicPremiumCard.radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PsychicPremiumCard.radius),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(PsychicPremiumCard.radius),
            border: Border.all(
              color: isOnline
                  ? HomePremiumDesign.accent.withValues(alpha: 0.35)
                  : HomeApprovedDesign.border,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: PsychicPremiumAvatar(url: avatarUrl, radius: 32),
                    ),
                    if (isOnline)
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: HomeApprovedDesign.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: HomeApprovedDesign.textPrimary,
                            ),
                          ),
                        ),
                        if (showLiveBadge)
                          const _StatusPill(
                            label: 'CANLI',
                            color: HomeApprovedDesign.liveRed,
                          )
                        else
                          Text(
                            isOnline ? 'Müsait' : 'Çevrimdışı',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isOnline
                                  ? HomeApprovedDesign.green
                                  : HomeApprovedDesign.textMuted,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      categoryLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: HomeApprovedDesign.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    PsychicRatingRow(
                      rating: rating,
                      reviewCount: reviewCount,
                    ),
                  ],
                ),
              ),
              if (pricePerMinute > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '$pricePerMinute\njeton/dk',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: HomeApprovedDesign.gold,
                    height: 1.15,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class PsychicPremiumAvatar extends StatelessWidget {
  const PsychicPremiumAvatar({
    super.key,
    required this.url,
    this.radius = 44,
  });

  final String? url;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final trimmed = url?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return CanlifalNetworkImage(
        url: trimmed,
        fit: BoxFit.cover,
        width: radius * 2,
        height: radius * 2,
        errorWidget: UserAvatar(url: null, radius: radius),
        placeholder: UserAvatar(url: null, radius: radius),
      );
    }
    return UserAvatar(url: null, radius: radius);
  }
}

class PsychicRatingRow extends StatelessWidget {
  const PsychicRatingRow({
    super.key,
    required this.rating,
    required this.reviewCount,
    this.compact = false,
  });

  final double rating;
  final int reviewCount;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (rating <= 0 && reviewCount <= 0) {
      return const SizedBox.shrink();
    }
    final stars = _formatStars(rating);
    final label = rating > 0 ? rating.toStringAsFixed(1) : null;
    return Row(
      children: [
        if (stars.isNotEmpty)
          Text(
            stars,
            style: TextStyle(
              fontSize: compact ? 10 : 11,
              color: HomeApprovedDesign.gold,
              letterSpacing: 0.4,
            ),
          ),
        if (label != null) ...[
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
        if (reviewCount > 0 && !compact) ...[
          Text(
            ' · $reviewCount',
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
        ],
      ],
    );
  }

  static String _formatStars(double rating) {
    final r = rating.clamp(0, 5);
    final full = r.floor();
    final half = r - full >= 0.5;
    final buf = StringBuffer();
    for (var i = 0; i < full; i++) {
      buf.write('★');
    }
    if (half && full < 5) buf.write('☆');
    while (buf.length < 5) {
      buf.write('☆');
    }
    return buf.toString();
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}
