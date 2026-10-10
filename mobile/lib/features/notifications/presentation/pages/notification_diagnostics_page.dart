import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/firebase/firebase_bootstrap.dart';
import '../../../../core/onesignal/onesignal_bootstrap.dart';
import '../../../../core/push/push_delivery.dart';
import '../../../../core/push/push_notification_service.dart';
import '../../../../core/push/push_registrar.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/mock_ui_kit.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Bildirim tanılama — push neden gelmiyor? Her adımı gösterir ve onarır:
/// izin → FCM (veya legacy OneSignal) → sunucu token kaydı.
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

  String? _fcmTokenPreview;

  Future<void> _refresh() async {
    if (!PushDelivery.oneSignalActive) {
      await PushNotificationService.instance.refreshPermissionStatus();
      if (FirebaseBootstrap.isReady) {
        final t = await PushNotificationService.instance.currentFcmToken();
        _fcmTokenPreview = t;
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _repair() async {
    setState(() => _busy = true);
    try {
      final user = ref.read(authControllerProvider).valueOrNull;
      if (PushDelivery.usesOneSignal) {
        if (!OneSignalBootstrap.isReady) await OneSignalBootstrap.init();
        if (user != null) await OneSignalBootstrap.login(user.id);
        if (!OneSignalBootstrap.permissionGranted) {
          await OneSignalBootstrap.requestPermission(fallbackToSettings: true);
        }
        await OneSignalBootstrap.optInIfPermitted();
      } else {
        await PushNotificationService.instance.requestSystemPermission();
      }
      await ref
          .read(pushRegistrarProvider)
          .registerIfPossible(allowTokenRetry: true);
      await _refresh();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bildirim bağlantısı yenilendi')),
        );
      }
    }
  }

  String? _serverTestResult;

  /// Sunucudan kendi hesabına test push gönderir; sunucunun ham yanıtını
  /// (anahtar eksik mi, abone cihaz var mı) ekrana yazar.
  Future<void> _serverTest() async {
    setState(() {
      _busy = true;
      _serverTestResult = null;
    });
    try {
      final res = await ref.read(dioProvider).post<dynamic>(
            '/api/notifications/test-push',
            options: Options(validateStatus: (_) => true),
          );
      final d = res.data;
      final m = d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{};
      final ok = m['ok'] == true;
      final reason = m['reason']?.toString();
      final resp = m['response'];
      final text = ok
          ? 'Sunucu bildirimi gönderdi. Birkaç saniye içinde telefonuna düşmeli.'
          : 'Gönderilemedi (HTTP ${res.statusCode}): '
              '${reason ?? m['error'] ?? 'bilinmeyen hata'}'
              '${resp != null ? '\n$resp' : ''}';
      if (mounted) setState(() => _serverTestResult = text);
    } catch (e) {
      if (mounted) setState(() => _serverTestResult = 'İstek başarısız: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
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
    final fcmOnly = !PushDelivery.usesOneSignal;
    final registered = PushRegistrar.lastStatus.startsWith('Sunucuya');
    final ready = fcmOnly
        ? FirebaseBootstrap.isReady
        : OneSignalBootstrap.isReady;
    final granted = PushDelivery.oneSignalActive
        ? OneSignalBootstrap.permissionGranted
        : PushNotificationService.instance.permissionGranted;
    final externalOk = fcmOnly
        ? (user != null && registered)
        : user != null && OneSignalBootstrap.externalUserId == user.id;
    final subOk = fcmOnly
        ? (_fcmTokenPreview != null && _fcmTokenPreview!.length > 20)
        : OneSignalBootstrap.optedIn &&
            OneSignalBootstrap.subscriptionId != null;

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
            fcmOnly ? 'Firebase / FCM' : 'Push servisi (OneSignal)',
            ready ? 'Hazır' : 'Başlatılmadı',
            ready,
          ),
          row(
            Icons.person_pin_rounded,
            fcmOnly ? 'Hesap + token kaydı' : 'Hesap eşlemesi (external_id)',
            user != null && externalOk ? _short(user.id) : 'Eşlenmedi',
            externalOk,
          ),
          row(
            Icons.cell_tower_rounded,
            fcmOnly ? 'FCM cihaz tokenı' : 'Abonelik',
            subOk
                ? _short(
                    fcmOnly ? _fcmTokenPreview : OneSignalBootstrap.subscriptionId,
                  )
                : 'Kapalı',
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
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => unawaited(_serverTest()),
            icon: const Icon(Icons.send_rounded),
            label: const Text('Sunucudan test bildirimi gönder'),
          ),
          if (_serverTestResult != null) ...[
            const SizedBox(height: 8),
            SelectableText(
              _serverTestResult!,
              style: TextStyle(color: c.onSurface, fontSize: 12, height: 1.4),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'Her satır yeşilse push uygulamaya ulaşır. Hepsi yeşil olduğu '
            'halde bildirim gelmiyorsa sorun sunucudadır (FCM Admin / '
            'PUSH_PROVIDER veya legacy OneSignal anahtarları) — destek '
            'ekibine bu ekranın görüntüsünü gönder.',
            style: TextStyle(color: c.onSurfaceMuted, fontSize: 11.5, height: 1.4),
          ),
        ],
      ),
    );
  }
}
