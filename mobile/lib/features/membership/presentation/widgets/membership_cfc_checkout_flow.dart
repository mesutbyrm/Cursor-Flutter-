import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/content/currency_usage_info.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../profile/data/jeton_payment_request.dart';
import '../../../profile/domain/entities/payment_method_entity.dart';
import '../../../profile/presentation/providers/payment_requests_notifier.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/membership_model.dart';

/// CFC bakiyesi yeterliyken tek dokunuşla üyelik talebi (kanal seçimi yok).
Future<bool> submitMembershipCfcInstant(
  BuildContext context,
  WidgetRef ref, {
  required MembershipTierModel tier,
  required int priceCfc,
  required VoidCallback onDone,
}) async {
  try {
    await ref.read(walletRepositoryProvider).submitPaymentRequest(
          buildMembershipCfcPaymentRequest(
            tierId: tier.wireId,
            tierTitle: tier.title,
            cfcAmount: priceCfc,
            priceTry: tier.monthlyPriceTry.toDouble(),
            method: 'cfc_balance',
          ),
        );
    ref.refreshWalletCache(force: true);
    ref.invalidate(paymentRequestsNotifierProvider);
    onDone();
    if (!context.mounted) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('CFC ile üyelik talebi gönderildi. Onay sonrası plan aktifleşir.'),
      ),
    );
    return true;
  } catch (e) {
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ApiException.userMessage(e))),
    );
    return false;
  }
}

/// Üyelik satın alma — CFC ödeme talebi (WhatsApp / Papara / Havale).
Future<void> openMembershipCfcCheckoutFlow(
  BuildContext context,
  WidgetRef ref, {
  required MembershipTierModel tier,
  required VoidCallback onDone,
}) async {
  List<PaymentMethodEntity> methods;
  try {
    methods = await ref.read(paymentMethodsProvider.future);
  } catch (_) {
    methods = PaymentMethodEntity.defaults;
  }
  final list = methods
      .where((m) => m.enabled && PaymentMethodEntity.isKnownCheckoutMethod(m.id))
      .toList();
  final channels = list.isNotEmpty ? list : PaymentMethodEntity.defaults;
  final priceCfc = CurrencyUsageInfo.cfcForTl(tier.monthlyPriceTry);
  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF0D0216),
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
              Text(
                '${tier.title} · CFC ile üyelik',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$priceCfc CFC · ₺${tier.monthlyPriceTry}',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
              ),
              const SizedBox(height: 16),
              for (final method in channels)
                _CfcMethodButton(
                  method: method,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _submitMembershipCfc(
                      context,
                      ref,
                      tier: tier,
                      priceCfc: priceCfc,
                      method: PaymentMethodEntity.normalizeCheckoutMethodId(
                        method.id,
                      ),
                      onDone: onDone,
                    );
                  },
                ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/cfc-purchase');
                },
                child: const Text('CFC bakiyesi yükle'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _submitMembershipCfc(
  BuildContext context,
  WidgetRef ref, {
  required MembershipTierModel tier,
  required int priceCfc,
  required String method,
  required VoidCallback onDone,
}) async {
  try {
    await ref.read(walletRepositoryProvider).submitPaymentRequest(
          buildMembershipCfcPaymentRequest(
            tierId: tier.wireId,
            tierTitle: tier.title,
            cfcAmount: priceCfc,
            priceTry: tier.monthlyPriceTry.toDouble(),
            method: method,
          ),
        );
    ref.refreshWalletCache(force: true);
    ref.invalidate(paymentRequestsNotifierProvider);
    onDone();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'CFC üyelik talebi gönderildi. Onay sonrası plan aktifleşir.',
        ),
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ApiException.userMessage(e))),
    );
  }
}

class _CfcMethodButton extends StatelessWidget {
  const _CfcMethodButton({required this.method, required this.onTap});

  final PaymentMethodEntity method;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FilledButton.icon(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: AppThemeColors.diamondBlue.withValues(alpha: 0.85),
          minimumSize: const Size.fromHeight(48),
        ),
        icon: const Icon(Icons.payments_rounded, size: 20),
        label: Text(
          method.recommended ? '${method.label} · Önerilen' : method.label,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
