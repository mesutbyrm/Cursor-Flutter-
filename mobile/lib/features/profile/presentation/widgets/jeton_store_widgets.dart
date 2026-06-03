import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:intl/intl.dart';

import '../../../../core/ui/pro_glass/pro_glass.dart';
import '../../data/jeton_packages_catalog.dart';
import '../../domain/entities/jeton_package_entity.dart';

/// Mor yıldızlı arka plan.
class JetonStoreBackdrop extends StatelessWidget {
  const JetonStoreBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1A0B2E),
                Color(0xFF0B0618),
                Color(0xFF120A22),
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.5),
              radius: 1.2,
              colors: [
                const Color(0xFF5B21B6).withValues(alpha: 0.35),
                Colors.transparent,
              ],
            ),
          ),
        ),
        const CustomPaint(painter: _StarFieldPainter()),
      ],
    );
  }
}

class _StarFieldPainter extends CustomPainter {
  const _StarFieldPainter();

  static const _stars = <(double x, double y, double r)>[
    (0.12, 0.08, 1.2),
    (0.88, 0.12, 1.0),
    (0.45, 0.18, 1.4),
    (0.72, 0.28, 0.9),
    (0.22, 0.35, 1.1),
    (0.58, 0.42, 1.3),
    (0.08, 0.55, 1.0),
    (0.92, 0.48, 1.2),
    (0.35, 0.62, 0.8),
    (0.68, 0.72, 1.1),
    (0.18, 0.78, 1.0),
    (0.82, 0.85, 1.3),
    (0.5, 0.88, 0.9),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.45);
    for (final s in _stars) {
      canvas.drawCircle(
        Offset(s.$1 * size.width, s.$2 * size.height),
        s.$3,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Mockup: Jeton / CFC bakiye çipleri.
class JetonStoreBalanceRow extends StatelessWidget {
  const JetonStoreBalanceRow({
    super.key,
    required this.jeton,
    required this.cfc,
  });

  final int jeton;
  final int cfc;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _BalanceChip(
            icon: Icons.monetization_on_rounded,
            label: 'Jeton:',
            value: '$jeton',
            valueColor: AppThemeColors.coinGold,
            borderColor: AppThemeColors.coinGold.withValues(alpha: 0.45),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _BalanceChip(
            icon: Icons.auto_awesome_rounded,
            label: 'CFC:',
            value: '$cfc',
            valueColor: const Color(0xFFD8B4FE),
            borderColor: const Color(0xFF7C3AED).withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

class _BalanceChip extends StatelessWidget {
  const _BalanceChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
    required this.borderColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: valueColor),
          SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: context.colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class JetonGoldMemberBanner extends StatelessWidget {
  const JetonGoldMemberBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppThemeColors.coinGold.withValues(alpha: 0.65),
            ),
            color: AppThemeColors.coinGold.withValues(alpha: 0.08),
          ),
          child: Row(
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                color: AppThemeColors.coinGold,
                size: 22,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Gold üyesiniz, uzatın',
                  style: TextStyle(
                    color: AppThemeColors.coinGold,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              Icon(
                Icons.star_rounded,
                color: AppThemeColors.coinGold.withValues(alpha: 0.9),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class JetonPackageTile extends StatelessWidget {
  const JetonPackageTile({
    super.key,
    required this.package,
    required this.priceText,
    required this.onTap,
    this.fullWidth = false,
  });

  final JetonPackageEntity package;
  final String priceText;
  final VoidCallback onTap;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final popular = package.badge?.toLowerCase().contains('popüler') == true ||
        package.badge?.toLowerCase().contains('popular') == true;

    return ProGlassCard(
      onTap: onTap,
      blur: 14,
      animateIn: false,
      padding: EdgeInsets.symmetric(
        horizontal: fullWidth ? 16 : 12,
        vertical: fullWidth ? 14 : 12,
      ),
      borderRadius: BorderRadius.circular(fullWidth ? 16 : 0),
      child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (popular)
                Positioned(
                  top: -6,
                  right: -4,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppThemeColors.accentPink,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, size: 12, color: Colors.white),
                        SizedBox(width: 2),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${package.coins} jeton',
                    style: TextStyle(
                      color: AppThemeColors.coinGold,
                      fontWeight: FontWeight.w900,
                      fontSize: fullWidth ? 22 : 18,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    priceText,
                    style: TextStyle(
                      color: context.colors.onSurface,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
    );
  }
}

/// Özel miktar — jeton veya TL girişi.
class JetonCustomAmountSection extends StatefulWidget {
  const JetonCustomAmountSection({
    super.key,
    required this.tlRate,
    required this.onPurchase,
  });

  final double tlRate;
  final void Function(JetonPackageEntity package, String priceText) onPurchase;

  @override
  State<JetonCustomAmountSection> createState() =>
      _JetonCustomAmountSectionState();
}

class _JetonCustomAmountSectionState extends State<JetonCustomAmountSection> {
  var _byJeton = true;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final raw = _controller.text.trim().replaceAll(',', '.');
    final n = double.tryParse(raw);
    if (n == null || n <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçerli bir miktar girin')),
      );
      return;
    }

    final rate = widget.tlRate > 0 ? widget.tlRate : kDefaultJetonTlRate;
    late final int coins;
    late final double priceTry;

    if (_byJeton) {
      coins = n.round();
      if (coins < 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('En az 1 jeton girin')),
        );
        return;
      }
      priceTry = coins * rate;
    } else {
      priceTry = n;
      coins = (priceTry / rate).round();
      if (coins < 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tutar en az 1 jeton karşılığı olmalı')),
        );
        return;
      }
    }

    final priceText = _formatTry(priceTry);
    widget.onPurchase(
      JetonPackageEntity(
        id: 'custom_$coins',
        title: '$coins Jeton (Özel)',
        coins: coins,
        priceTry: priceTry,
      ),
      priceText,
    );
  }

  static String _formatTry(double v) {
    if (v == v.roundToDouble()) {
      return '₺${v.toInt()}';
    }
    return NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 2,
    ).format(v);
  }

  @override
  Widget build(BuildContext context) {
    final rate = widget.tlRate > 0 ? widget.tlRate : kDefaultJetonTlRate;
    final rateLabel = rate == rate.roundToDouble()
        ? rate.toInt().toString()
        : rate.toStringAsFixed(2).replaceAll('.', ',');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(
          color: AppThemeColors.accentPurple.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.link_rounded, color: AppThemeColors.accentPurple, size: 20),
              SizedBox(width: 8),
              Text(
                'Özel Miktar Belirle',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFF120A22),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ModeTab(
                    label: 'Jeton Miktarı Gir',
                    selected: _byJeton,
                    onTap: () => setState(() => _byJeton = true),
                  ),
                ),
                Expanded(
                  child: _ModeTab(
                    label: 'Fiyat Gir (₺)',
                    selected: !_byJeton,
                    onTap: () => setState(() => _byJeton = false),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: context.colors.onSurface),
            decoration: InputDecoration(
              hintText: _byJeton
                  ? 'Kaç jeton almak istiyorsun?'
                  : 'Ödeyeceğiniz tutarı girin (₺)',
              hintStyle: TextStyle(
                color: context.colors.onSurfaceMuted.withValues(alpha: 0.85),
              ),
              filled: true,
              fillColor: const Color(0xFF1A1030),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppThemeColors.accentPurple.withValues(alpha: 0.35),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppThemeColors.accentPurple.withValues(alpha: 0.35),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF9D6BFF)),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
          SizedBox(height: 14),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _submit,
              borderRadius: BorderRadius.circular(14),
              child: Ink(
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFE2C55),
                      Color(0xFFB832FF),
                      Color(0xFF7C3AED),
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    'Satın Al',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 10),
          Text(
            '1 Jeton = ₺$rateLabel',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.colors.onSurfaceMuted.withValues(alpha: 0.95),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: selected
                ? const LinearGradient(
                    colors: [Color(0xFFFE2C55), Color(0xFFB832FF)],
                  )
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : context.colors.onSurfaceMuted,
            ),
          ),
        ),
      ),
    );
  }
}

String formatJetonPrice(JetonPackageEntity p) {
  if (p.priceLabel != null && p.priceLabel!.trim().isNotEmpty) {
    return p.priceLabel!.trim();
  }
  if (p.priceTry != null) {
    final v = p.priceTry!;
    if (v == v.roundToDouble()) return '₺${v.toInt()}';
    return NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 2,
    ).format(v);
  }
  return '—';
}

/// Grid (2x2) + tam genişlik büyük paket.
List<JetonPackageEntity> jetonGridPackages(List<JetonPackageEntity> all) {
  final sorted = List<JetonPackageEntity>.from(all)
    ..sort((a, b) => a.coins.compareTo(b.coins));
  return sorted.where((p) => p.coins < 1000).toList();
}

JetonPackageEntity? jetonHeroPackage(List<JetonPackageEntity> all) {
  final sorted = List<JetonPackageEntity>.from(all)
    ..sort((a, b) => b.coins.compareTo(a.coins));
  for (final p in sorted) {
    if (p.coins >= 1000) return p;
  }
  return sorted.isNotEmpty ? sorted.first : null;
}
