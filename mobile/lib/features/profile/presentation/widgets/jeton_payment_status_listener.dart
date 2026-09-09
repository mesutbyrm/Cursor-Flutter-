import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../notifications/domain/entities/app_notification_entity.dart';
import '../../../notifications/presentation/providers/notifications_providers.dart';
import '../../../notifications/presentation/providers/notification_event_gate_provider.dart';
import '../../../../core/economy/presentation/providers/economy_providers.dart';
import '../../../../core/theme/app_theme_colors.dart';

/// Jeton ödeme onay / red bildirimlerini popup olarak gösterir.
/// Geçmiş bildirimler uygulama açılışında tekrar gösterilmez.
class JetonPaymentStatusListener extends ConsumerStatefulWidget {
  const JetonPaymentStatusListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<JetonPaymentStatusListener> createState() =>
      _JetonPaymentStatusListenerState();
}

class _JetonPaymentStatusListenerState
    extends ConsumerState<JetonPaymentStatusListener> {
  var _historySeeded = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(notificationsListProvider, (prev, next) {
      final list = next.valueOrNull;
      if (list == null) return;
      final gate = ref.read(notificationEventGateProvider);
      if (!_historySeeded) {
        gate.seedFromHistory(list.map((n) => n.id));
        _historySeeded = true;
      }
      for (final n in list) {
        unawaited(_maybeShow(n));
      }
    });
    return widget.child;
  }

  Future<void> _maybeShow(AppNotificationEntity n) async {
    final type = n.type?.toLowerCase() ?? '';
    if (type != 'jeton_payment_approved' && type != 'jeton_payment_rejected') {
      return;
    }
    final userId = ref.read(authControllerProvider).valueOrNull?.id ?? '';
    final gate = ref.read(notificationEventGateProvider);
    if (userId.isNotEmpty &&
        await gate.wasDialogShownPersisted(userId: userId, eventId: n.id)) {
      return;
    }
    if (!gate.shouldShowHistoricalPopup(
      eventId: n.id,
      isRead: n.read,
      createdAt: n.createdAt,
    )) {
      return;
    }
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showDialog(n, type == 'jeton_payment_approved');
      if (userId.isNotEmpty) {
        unawaited(
          gate.markDialogShownPersisted(userId: userId, eventId: n.id),
        );
      }
    });
  }

  void _showDialog(AppNotificationEntity n, bool approved) {
    final jetonLabel = economyCurrencyLabel(ref, key: 'jeton');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          approved ? Icons.check_circle_rounded : Icons.info_outline_rounded,
          color: approved ? AppThemeColors.accentCyan : AppThemeColors.coinGold,
          size: 36,
        ),
        title: Text(approved ? '$jetonLabel yüklendi' : 'Ödeme reddedildi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              approved
                  ? '$jetonLabel bakiyeniz hesabınıza yüklendi.'
                  : 'Ödeme talebiniz reddedildi.',
              style: const TextStyle(fontWeight: FontWeight.w800, height: 1.35),
            ),
            if (n.body != null && n.body!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(n.body!, style: const TextStyle(height: 1.35)),
            ],
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
