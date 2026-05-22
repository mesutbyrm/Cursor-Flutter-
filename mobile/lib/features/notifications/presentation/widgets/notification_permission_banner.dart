import 'package:flutter/material.dart';

import '../../../../core/push/push_notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';

/// Sistem bildirim izni kapalıysa etkinleştirme çağrısı.
class NotificationPermissionBanner extends StatefulWidget {
  const NotificationPermissionBanner({super.key});

  @override
  State<NotificationPermissionBanner> createState() =>
      _NotificationPermissionBannerState();
}

class _NotificationPermissionBannerState
    extends State<NotificationPermissionBanner> {
  var _granted = PushNotificationService.instance.permissionGranted;
  var _loading = false;

  Future<void> _enable() async {
    setState(() => _loading = true);
    final ok =
        await PushNotificationService.instance.requestSystemPermission();
    if (mounted) {
      setState(() {
        _granted = ok;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_granted) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: DiscoverGlassCard(
        padding: const EdgeInsets.all(14),
        borderColor: AppColors.accentPink.withValues(alpha: 0.35),
        child: Row(
          children: [
            const Icon(Icons.notifications_active_rounded, color: AppColors.accentPink),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Uygulama bildirimlerini açarak ödeme onayı, mesaj ve canlı yayın uyarılarını alın.',
                style: TextStyle(fontSize: 13, height: 1.35),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _loading ? null : _enable,
              child: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Aç'),
            ),
          ],
        ),
      ),
    );
  }
}
