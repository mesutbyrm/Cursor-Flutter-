import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/payment_defaults.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../profile/presentation/widgets/payment_methods_summary_line.dart';
import '../../domain/membership_model.dart';

class MembershipSupportFooter extends ConsumerWidget {
  const MembershipSupportFooter({super.key});

  Future<void> _openSupport(String whatsapp) async {
    final digits = whatsapp.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$digits');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(paymentConfigProvider).valueOrNull;
    final cfg =
        config != null ? PaymentDefaults.merge(config) : PaymentDefaults.config;

    return Column(
      children: [
        Text(
          'Yardıma mı ihtiyacınız var?',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        const PaymentMethodsSummaryLine(
          prefix: 'Ödeme',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openSupport(cfg.whatsappNumber),
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: MembershipCatalogData.purple.withValues(alpha: 0.45),
                ),
                gradient: LinearGradient(
                  colors: [
                    MembershipCatalogData.purple.withValues(alpha: 0.22),
                    MembershipCatalogData.purpleDeep.withValues(alpha: 0.12),
                  ],
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Destek Ekibi ile İletişime Geçin',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: MembershipCatalogData.gold,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 280.ms, duration: 400.ms);
  }
}
