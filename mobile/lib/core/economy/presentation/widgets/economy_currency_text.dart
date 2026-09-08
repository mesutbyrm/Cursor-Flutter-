import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../presentation/providers/economy_providers.dart';

/// Kullanıcıya gösterilen para birimi metni — branding + fallback.
class EconomyCurrencyText extends ConsumerWidget {
  const EconomyCurrencyText({
    super.key,
    required this.amount,
    required this.currencyKey,
    this.prefix,
    this.suffix,
    this.style,
    this.compact = false,
  });

  final int amount;
  final String currencyKey;
  final String? prefix;
  final String? suffix;
  final TextStyle? style;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context);
    final label = economyCurrencyLabel(
      ref,
      key: currencyKey,
      locale: locale,
    );
    final signedPrefix = prefix ?? '';
    final signedSuffix = suffix ?? '';
    final text = compact
        ? '$signedPrefix$amount$signedSuffix'
        : '$signedPrefix$amount $label$signedSuffix';
    return Text(text, style: style);
  }
}
