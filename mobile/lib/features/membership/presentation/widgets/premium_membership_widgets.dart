import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/responsive/responsive_layout.dart';
import '../../../profile/presentation/widgets/jeton_store_widgets.dart';
import '../../domain/membership_package_entity.dart';

/// Mor yıldızlı arka plan + içerik katmanı.
class PremiumMembershipScaffold extends StatelessWidget {
  const PremiumMembershipScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const JetonStoreBackdrop(),
        child,
      ],
    );
  }
}

class PremiumMembershipHeader extends StatelessWidget {
  const PremiumMembershipHeader({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Material(
            color: Colors.white.withValues(alpha: 0.08),
            shape: const CircleBorder(),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: onBack,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: AppColors.coinGold,
            boxShadow: AppColors.glowShadow(AppColors.coinGold, blur: 16),
          ),
          child: const Icon(
            Icons.workspace_premium_rounded,
            color: Color(0xFF1A1030),
            size: 40,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Premium Üyelik',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 26,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sınırsız erişim, özel ayrıcalıklar ve VIP deneyim',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textMuted.withValues(alpha: 0.95),
            fontSize: 14,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class PremiumFeatureGrid extends StatelessWidget {
  const PremiumFeatureGrid({super.key});

  static const _items = [
    (Icons.auto_awesome_rounded, 'Bonus Jeton'),
    (Icons.diamond_rounded, 'Özel Rozet'),
    (Icons.headset_mic_rounded, 'Öncelikli Destek'),
    (Icons.flare_rounded, 'İndirimli Fal'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 400 ? 2 : 1;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: cols,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: cols == 1 ? 4.5 : 2.8,
          children: _items
              .map(
                (e) => _FeatureBadge(icon: e.$1, label: e.$2),
              )
              .toList(),
        );
      },
    );
  }
}

class _FeatureBadge extends StatelessWidget {
  const _FeatureBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(
          color: AppColors.coinGold.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: AppColors.coinGold),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class PremiumActiveMembershipCard extends StatelessWidget {
  const PremiumActiveMembershipCard({
    super.key,
    required this.tierLabel,
    required this.daysRemaining,
    required this.onExtend,
  });

  final String tierLabel;
  final int daysRemaining;
  final VoidCallback onExtend;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onExtend,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.coinGold.withValues(alpha: 0.7),
            ),
            color: AppColors.coinGold.withValues(alpha: 0.1),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.coinGold,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Color(0xFF1A1030),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${tierLabel.toUpperCase()} ÜYESİNİZ',
                      style: const TextStyle(
                        color: AppColors.coinGold,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$daysRemaining gün kaldı, uzatın',
                      style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.95),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.coinGold),
            ],
          ),
        ),
      ),
    );
  }
}

class PremiumBalanceLines extends StatelessWidget {
  const PremiumBalanceLines({
    super.key,
    required this.jeton,
    required this.cfc,
  });

  final int jeton;
  final int cfc;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _line(Icons.monetization_on_rounded, 'Jeton Bakiyeniz:', '$jeton', AppColors.coinGold),
        const SizedBox(height: 8),
        _line(Icons.auto_awesome_rounded, 'CFC Bakiyeniz:', '$cfc', const Color(0xFFD8B4FE)),
      ],
    );
  }

  Widget _line(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class PremiumTierCard extends StatelessWidget {
  const PremiumTierCard({
    super.key,
    required this.package,
    required this.onBuy,
    this.showPopular = true,
  });

  final MembershipPackageEntity package;
  final VoidCallback onBuy;
  final bool showPopular;

  static Color accentFor(String id) => switch (id) {
        'premium' => const Color(0xFF5B8CFF),
        'gold' => const Color(0xFFFFD54F),
        'diamond' => const Color(0xFFB832FF),
        _ => const Color(0xFF6E6E82),
      };

  @override
  Widget build(BuildContext context) {
    final accent = accentFor(package.id);
    final active = package.isActive && (package.daysRemaining ?? 0) > 0;
    final btnLabel = active ? 'Uzat' : 'Satın Al';
    final btnFg = package.id == 'gold' ? Colors.black87 : Colors.white;

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 340;

        final details = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              package.title,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: accent,
              ),
            ),
            if (active) ...[
              const SizedBox(height: 4),
              Text(
                '${package.title} üyesiniz, ${package.daysRemaining ?? 0} gün kaldı, uzatın',
                style: TextStyle(
                  fontSize: 11,
                  color: accent.withValues(alpha: 0.95),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _TagPill(
                  icon: Icons.schedule_rounded,
                  label: '${package.durationDays} gün',
                  color: accent,
                ),
                _TagPill(
                  icon: Icons.diamond_rounded,
                  label: 'VIP',
                  color: accent,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${package.priceJeton} Jeton',
              style: const TextStyle(
                color: AppColors.coinGold,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ],
        );

        final button = SizedBox(
          width: stacked ? double.infinity : 108,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onBuy,
              borderRadius: BorderRadius.circular(12),
              child: Ink(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  btnLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: btnFg,
                  ),
                ),
              ),
            ),
          ),
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF1A1030).withValues(alpha: 0.9),
            border: Border.all(
              color: active
                  ? accent.withValues(alpha: 0.85)
                  : accent.withValues(alpha: 0.4),
              width: active ? 1.5 : 1,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (showPopular)
                Positioned(
                  top: -10,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentPink,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Popüler',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (stacked)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TierIcon(accent: accent),
                        const SizedBox(width: 12),
                        Expanded(child: details),
                      ],
                    ),
                    const SizedBox(height: 12),
                    button,
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _TierIcon(accent: accent),
                    const SizedBox(width: 12),
                    Expanded(child: details),
                    const SizedBox(width: 10),
                    button,
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TierIcon extends StatelessWidget {
  const _TierIcon({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: accent.withValues(alpha: 0.25),
        border: Border.all(color: accent.withValues(alpha: 0.65)),
      ),
      child: Icon(
        Icons.workspace_premium_rounded,
        color: accent,
        size: 28,
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Premium sayfa gövdesi — responsive padding + max genişlik.
class PremiumMembershipBody extends StatelessWidget {
  const PremiumMembershipBody({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ResponsiveConstrained(
      child: Padding(
        padding: ResponsiveLayout.pagePadding(context),
        child: child,
      ),
    );
  }
}
