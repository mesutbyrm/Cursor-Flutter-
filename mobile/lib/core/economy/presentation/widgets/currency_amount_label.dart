import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/economy_providers.dart';

/// Markalı para birimi etiketi — ikon + biçimli sayı + ad.
class CurrencyAmountLabel extends ConsumerWidget {
  const CurrencyAmountLabel({
    super.key,
    required this.amount,
    required this.currencyKey,
    this.compact = false,
    this.showName = true,
    this.textStyle,
    this.iconSize = 16,
  });

  final int amount;
  final String currencyKey;
  final bool compact;
  final bool showName;
  final TextStyle? textStyle;
  final double iconSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = resolveEconomyBrand(ref, key: currencyKey);
    final locale = Localizations.localeOf(context);
    final formatted = NumberFormat.decimalPattern(locale.languageCode == 'tr'
        ? 'tr_TR'
        : locale.toString()).format(amount);
    final label = brand.labelForLocale(locale);
    final color = brand.resolveColor();
    final style = textStyle ??
        Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          currencyKey.toLowerCase() == 'jeton'
              ? Icons.monetization_on_rounded
              : Icons.diamond_rounded,
          size: iconSize,
          color: color,
        ),
        SizedBox(width: compact ? 4 : 6),
        Text(
          showName ? '$formatted $label' : formatted,
          style: style,
        ),
      ],
    );
  }
}
