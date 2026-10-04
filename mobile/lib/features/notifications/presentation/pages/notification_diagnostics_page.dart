import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/onesignal/onesignal_bootstrap.dart';
import '../../../../core/push/push_notification_service.dart';
import '../../../../core/push/push_registrar.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/mock_ui_kit.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Bildirim tanılama — push neden gelmiyor? Her adımı gösterir ve onarır:
/// izin → OneSignal SDK → kullanıcı eşlemesi (external_id) → abonelik →
/// sunucu kaydı.
class NotificationDiagnosticsPage extends ConsumerStatefulWidget {
  const NotificationDiagnosticsPage({super.key});

  @override
  ConsumerState<NotificationDiagnosticsPage> createState() =>
      _NotificationDiagnosticsPageState();
}

class _NotificationDiagnosticsPageState
    extends ConsumerState<NotificationDiagnosticsPage> {
  var _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    if (!OneSignalBootstrap.isReady) {
      await PushNotificationService.instance.refreshPermissionStatus();
    }
    if (mounted) setState(() {});
  }

  Future<void> _repair() async {
    setState(() => _busy = true);
    try {
      final user = ref.read(authControllerProvider).valueOrNull;
      if (!OneSignalBootstrap.isReady) await OneSignalBootstrap.init();
      if (user != null) await OneSignalBootstrap.login(user.id);
      if (!OneSignalBootstrap.permissionGranted) {
        await OneSignalBootstrap.requestPermission(fallbackToSettings: true);
      }
      await OneSignalBootstrap.optInIfPermitted();
      await ref
          .read(pushRegistrarProvider)
          .registerIfPossible(allowTokenRetry: true);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bildirim bağlantısı yenilendi')),
        );
      }
    }
  }

  String _short(String? v) {
    if (v == null || v.isEmpty) return 'yok';
    return v.length <= 14 ? v : '${v.substring(0, 6)}…${v.substring(v.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final user = ref.watch(authControllerProvider).valueOrNull;
    final ready = OneSignalBootstrap.isReady;
    final granted = ready
        ? OneSignalBootstrap.permissionGranted
        : PushNotificationService.instance.permissionGranted;
    final externalOk = user != null &&
        OneSignalBootstrap.externalUserId == user.id;
    final subOk = OneSignalBootstrap.optedIn &&
        OneSignalBootstrap.subscriptionId != null;
    final registered = PushRegistrar.lastStatus.startsWith('Sunucuya');

    Widget row(
      IconData icon,
      String title,
      String value,
      bool ok, {
      VoidCallback? onTap,
    }) =>
        MockListRow(
          icon: icon,
          color: ok ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
          title: title,
          value: value,
          valueColor: ok ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
          onTap: onTap,
          chevron: false,
          dense: true,
        );

    return MockScaffold(
      title: 'Bildirim tanılama',
      actions: [
        IconButton(
          tooltip: 'Yenile',
          icon: const Icon(Icons.refresh_rounded),
          color: c.onSurface,
          onPressed: () => unawaited(_refresh()),
        ),
      ],
      body: MockRowList(
        gap: 6,
        children: [
          row(
            Icons.notifications_active_rounded,
            'Bildirim izni',
            granted ? 'Verildi' : 'Verilmedi',
            granted,
            onTap: granted ? null : () => unawaited(openAppSettings()),
          ),
          row(
            Icons.hub_rounded,
            'Push servisi (OneSignal)',
            ready ? 'Hazır' : 'Başlatılmadı',
            ready,
          ),
          row(
            Icons.person_pin_rounded,
            'Hesap eşlemesi (external_id)',
            externalOk ? _short(user.id) : 'Eşlenmedi',
            externalOk,
          ),
          row(
            Icons.cell_tower_rounded,
            'Abonelik',
            subOk ? _short(OneSignalBootstrap.subscriptionId) : 'Kapalı',
            subOk,
          ),
          row(
            Icons.cloud_done_rounded,
            'Sunucu kaydı',
            PushRegistrar.lastStatus,
            registered,
          ),
          const SizedBox(height: 6),
          FilledButton.icon(
            onPressed: _busy ? null : () => unawaited(_repair()),
            icon: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.build_circle_rounded),
            label: const Text('Bildirimleri onar / yeniden bağla'),
          ),
          const SizedBox(height: 4),
          Text(
            'Her satır yeşilse push uygulamaya ulaşır. Hepsi yeşil olduğu '
            'halde bildirim gelmiyorsa sorun sunucudadır (OneSignal anahtarları '
            'veya App ID eşleşmesi) — destek ekibine bu ekranın görüntüsünü gönder.',
            style: TextStyle(color: c.onSurfaceMuted, fontSize: 11.5, height: 1.4),
          ),
        ],
      ),
    );
  }
}
