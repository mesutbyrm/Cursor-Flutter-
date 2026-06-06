import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/onesignal/onesignal_bootstrap.dart';
import '../../../../core/push/push_notification_service.dart';
import '../../../../core/push/push_registrar.dart';
import '../../../../core/widgets/discover_tab_layout.dart';

/// Sistem bildirim izni kapalıysa etkinleştirme çağrısı.
class NotificationPermissionBanner extends ConsumerStatefulWidget {
  const NotificationPermissionBanner({super.key});

  @override
  ConsumerState<NotificationPermissionBanner> createState() =>
      _NotificationPermissionBannerState();
}

class _NotificationPermissionBannerState
    extends ConsumerState<NotificationPermissionBanner> {
  var _granted = false;
  var _loading = false;

  @override
  void initState() {
    super.initState();
    _syncGranted();
  }

  void _syncGranted() {
    _granted = OneSignalBootstrap.isReady
        ? OneSignalBootstrap.permissionGranted
        : PushNotificationService.instance.permissionGranted;
  }

  Future<void> _enable() async {
    setState(() => _loading = true);
    var ok = false;
    if (OneSignalBootstrap.isReady) {
      ok = await OneSignalBootstrap.requestPermission();
      if (ok) {
        await ref.read(pushRegistrarProvider).registerIfPossible();
      }
    } else {
      ok = await PushNotificationService.instance.requestSystemPermission();
    }
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
        borderColor: AppThemeColors.accentPink.withValues(alpha: 0.35),
        child: Row(
          children: [
            const Icon(Icons.notifications_active_rounded, color: AppThemeColors.accentPink),
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
