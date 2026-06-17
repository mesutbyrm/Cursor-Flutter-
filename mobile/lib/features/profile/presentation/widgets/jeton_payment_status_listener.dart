import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../notifications/domain/entities/app_notification_entity.dart';
import '../../../notifications/presentation/providers/notifications_providers.dart';
import '../../../../core/theme/app_theme_colors.dart';

/// Jeton ödeme onay / red bildirimlerini popup olarak gösterir.
class JetonPaymentStatusListener extends ConsumerStatefulWidget {
  const JetonPaymentStatusListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<JetonPaymentStatusListener> createState() =>
      _JetonPaymentStatusListenerState();
}

class _JetonPaymentStatusListenerState
    extends ConsumerState<JetonPaymentStatusListener> {
  final _shown = <String>{};

  @override
  Widget build(BuildContext context) {
    ref.listen(notificationsListProvider, (prev, next) {
      final list = next.valueOrNull;
      if (list == null) return;
      for (final n in list) {
        _maybeShow(n);
      }
    });
    return widget.child;
  }

  void _maybeShow(AppNotificationEntity n) {
    if (_shown.contains(n.id)) return;
    final type = n.type?.toLowerCase() ?? '';
    if (type != 'jeton_payment_approved' && type != 'jeton_payment_rejected') {
      return;
    }
    _shown.add(n.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showDialog(n, type == 'jeton_payment_approved');
    });
  }

  void _showDialog(AppNotificationEntity n, bool approved) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          approved ? Icons.check_circle_rounded : Icons.info_outline_rounded,
          color: approved ? AppThemeColors.accentCyan : AppThemeColors.coinGold,
          size: 36,
        ),
        title: Text(approved ? 'Jeton yüklendi' : 'Ödeme düzeltildi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              n.title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            if (n.body != null && n.body!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(n.body!, style: const TextStyle(height: 1.35)),
            ),
            const SizedBox(height: 12),
            Text(
              approved
                  ? 'Jetonlar hesabınıza yansıtıldı. İyi kullanımlar!'
                  : 'Admin ödemenizi kontrol etti. Aşağıdaki bilgi doğru tutar ve jeton miktarıdır.',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}
