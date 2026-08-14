import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';

import '../../domain/membership_model.dart';

enum MembershipCheckoutChoice { externalPayment, cfcPayment }

/// Jeton yetersizken üyelik ödeme yolu seçimi.
Future<MembershipCheckoutChoice?> showMembershipCheckoutSheet(
  BuildContext context, {
  required MembershipTierModel tier,
  required int priceJeton,
  required int priceCfc,
  required int cfcBalance,
}) {
  final hasCfc = cfcBalance >= priceCfc && priceCfc > 0;
  return showModalBottomSheet<MembershipCheckoutChoice>(
    context: context,
    backgroundColor: const Color(0xFF12081C),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${tier.title} üyeliği · ödeme',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '₺${tier.monthlyPriceTry} · ${tier.monthlyTokens} jeton/ay',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              _OptionTile(
                icon: Icons.credit_card_rounded,
                color: MembershipCatalogData.gold,
                title: 'WhatsApp / Papara / Havale',
                subtitle: 'Jeton yükleme talebi ile üyelik ($priceJeton jeton)',
                onTap: () =>
                    Navigator.pop(ctx, MembershipCheckoutChoice.externalPayment),
              ),
              const SizedBox(height: 10),
              _OptionTile(
                icon: Icons.auto_awesome_rounded,
                color: AppThemeColors.diamondBlue,
                title: 'CFC ile öde',
                subtitle: hasCfc
                    ? 'Bakiyeniz: $cfcBalance CFC · gerekli: $priceCfc CFC'
                    : 'Bakiye yetersiz ($cfcBalance / $priceCfc CFC) — yükleme talebi',
                enabled: priceCfc > 0,
                onTap: priceCfc > 0
                    ? () => Navigator.pop(ctx, MembershipCheckoutChoice.cfcPayment)
                    : null,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: enabled ? 0.08 : 0.04),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: enabled ? color : Colors.white38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: enabled ? Colors.white : Colors.white54,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: enabled ? Colors.white54 : Colors.white24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
