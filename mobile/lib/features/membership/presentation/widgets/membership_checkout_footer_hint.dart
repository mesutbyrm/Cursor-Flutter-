import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profile/presentation/premium_2026/profile_membership_helpers.dart';
import '../../../profile/presentation/providers/profile_hub_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/membership_model.dart';
import '../controllers/membership_controller.dart';

/// Üyelik sayfası checkout alt ipucu — seçili plan özeti.
class MembershipCheckoutFooterHint extends ConsumerWidget {
  const MembershipCheckoutFooterHint({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(profileMembershipInfoProvider);
    final ui = ref.watch(membershipControllerProvider);
    final tier = ui.selectedTierModel;
    final expiresAt =
        ref.watch(walletBalancesProvider).valueOrNull?.membershipExpiresAt;
    final hint = buildMembershipCheckoutFooterHint(
      info: info,
      selectedTier: tier,
      expiresAt: expiresAt,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        hint,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.55),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
      ),
    );
  }
}
