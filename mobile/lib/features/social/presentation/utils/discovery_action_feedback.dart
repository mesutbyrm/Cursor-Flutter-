import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/social_discovery_feed.dart';

/// Tanış keşif — API aksiyon hata / kota mesajları.
void showDiscoveryActionFailure(
  BuildContext context,
  SocialDiscoveryActionResult result,
) {
  final text = result.isRateOrQuotaLimit
      ? (result.message?.trim().isNotEmpty == true
          ? result.message!
          : 'Beğeni limitine ulaştınız. Yarın tekrar deneyin veya Gold üyelik seçeneklerine bakın.')
      : (result.message ?? 'İşlem tamamlanamadı');

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      duration: result.isRateOrQuotaLimit
          ? const Duration(seconds: 5)
          : const Duration(seconds: 3),
      action: result.isRateOrQuotaLimit
          ? SnackBarAction(
              label: 'Gold',
              onPressed: () => context.push('/vip-gold'),
            )
          : null,
    ),
  );
}
