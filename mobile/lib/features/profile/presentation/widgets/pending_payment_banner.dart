import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/ui/pro_glass/pro_glass.dart';
import '../../../admin/presentation/providers/staff_access_provider.dart';
import '../../../notifications/presentation/providers/notifications_providers.dart';
import '../../../wallet/domain/cfc_payment_request_entity.dart';
import '../providers/payment_requests_notifier.dart';

enum PendingPaymentKind { jeton, cfc }

/// Bekleyen jeton/CFC ödeme talebi — kullanıcı iptal edebilir.
class PendingPaymentBanner extends ConsumerWidget {
  const PendingPaymentBanner({
    super.key,
    required this.request,
    required this.kind,
    this.totalPending = 1,
  });

  final CfcPaymentRequestEntity request;
  final PendingPaymentKind kind;
  final int totalPending;

  String get _currencyLabel => kind == PendingPaymentKind.jeton ? 'jeton' : 'CFC';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(staffAccessProvider);

    return ProGlassCard(
      blur: 12,
      animateIn: false,
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.hourglass_top_rounded,
            color: kind == PendingPaymentKind.jeton
                ? AppThemeColors.coinGold
                : AppThemeColors.diamondBlue,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  totalPending > 1
                      ? '$totalPending bekleyen ödeme talebiniz var'
                      : 'Bekleyen ödeme talebiniz var',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  totalPending > 1
                      ? '${request.displayLine}\nYeni alım için bekleyen taleplerin tümünü temizleyin.'
                      : '${request.displayLine}\nOnay sonrası $_currencyLabel hesabınıza yansır.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: context.colors.onSurfaceMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    TextButton.icon(
                      onPressed: () => _cancel(context, ref),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: Text(
                        totalPending > 1
                            ? 'Talepleri iptal et ($totalPending)'
                            : 'Talebi iptal et',
                      ),
                    ),
                    if (staff.canManagePayments)
                      TextButton.icon(
                        onPressed: () => context.push('/admin'),
                        icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
                        label: const Text('Admin paneli'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final cancelAll = totalPending > 1;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(cancelAll ? 'Talepleri iptal et' : 'Talebi iptal et'),
        content: Text(
          cancelAll
              ? 'Bekleyen $totalPending $_currencyLabel ödeme talebinizin '
                  'tümü silinecek. Yeni bir ödeme bildirimi gönderebilirsiniz.'
              : 'Bekleyen $_currencyLabel ödeme talebiniz silinecek. '
                  'Yeni bir ödeme bildirimi gönderebilirsiniz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('İptal et'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      final notifier = ref.read(paymentRequestsNotifierProvider.notifier);
      if (cancelAll) {
        await notifier.cancelAllPending();
      } else {
        await notifier.cancelPending(request.id);
      }
      ref.invalidate(notificationsListProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Bekleyen talep ve ödeme bildirimleri temizlendi.',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    }
  }
}
