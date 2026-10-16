import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/push/notification_channels.dart';
import '../../../../core/push/push_notification_service.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/mock_ui_kit.dart';
import '../widgets/notification_permission_banner.dart';

/// Kanal bazlı bildirim tercihleri — Mesajlar, Canlı yayın başlatanlar,
/// Günlük fal önerisi, Diğer.
///
/// Tercihler hesaba kaydedilir (`/api/user/notification-settings`): sunucu
/// kapatılan kanalın push bildirimini hiç göndermez, tercih tüm cihazlarda
/// geçerli olur. Cihazda da saklanır (çevrimdışı / eski sunucu yedeği).
class NotificationChannelSettingsPage extends ConsumerStatefulWidget {
  const NotificationChannelSettingsPage({super.key});

  @override
  ConsumerState<NotificationChannelSettingsPage> createState() =>
      _NotificationChannelSettingsPageState();
}

class _NotificationChannelSettingsPageState
    extends ConsumerState<NotificationChannelSettingsPage> {
  static const _prefs = NotificationChannelPrefs();
  Map<AppNotificationChannel, bool>? _values;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  static const _endpoint = '/api/user/notification-settings';

  Future<void> _load() async {
    final all = await _prefs.loadAll();
    if (mounted) setState(() => _values = all);
    // Hesaptaki tercih (başka cihazda değiştirilmiş olabilir) yereli günceller.
    try {
      final res = await ref.read(dioProvider).safeGet<dynamic>(
            _endpoint,
            forceRefresh: true,
          );
      final body = res.data;
      final data = body is Map && body['data'] is Map ? body['data'] as Map : null;
      if (data == null) return;
      final merged = {...all};
      for (final c in AppNotificationChannel.values) {
        final v = data[c.name];
        if (v is bool && v != merged[c]) {
          merged[c] = v;
          await _prefs.setEnabled(c, v);
        }
      }
      if (mounted) setState(() => _values = merged);
    } catch (_) {}
  }

  Future<void> _toggle(AppNotificationChannel c, bool v) async {
    setState(() => _values = {...?_values, c: v});
    await _prefs.setEnabled(c, v);
    unawaited(
      ref
          .read(dioProvider)
          .safePut<dynamic>(_endpoint, data: {c.name: v})
          .then((_) {}, onError: (_) {}),
    );
    if (c == AppNotificationChannel.dailyFortune) {
      // Günlük fal önerisi kapanınca zamanlanmış hatırlatıcı da iptal edilir;
      // açılınca günde bir kez yeniden planlanır.
      await PushNotificationService.instance.setDailyFortuneReminderEnabled(v);
    }
  }

  var _sendingMail = false;

  /// `POST /api/auth/email/send-verification` (Bearer) — doğrulanmamışsa
  /// e-posta gönderir; doğrulanmışsa `alreadyVerified: true` döner.
  Future<void> _sendVerificationMail() async {
    setState(() => _sendingMail = true);
    String msg;
    try {
      final res = await ref.read(dioProvider).safePost<dynamic>(
            ApiEndpoints.authEmailSendVerification,
            data: const <String, dynamic>{},
          );
      final body = res.data;
      if (body is Map && body['alreadyVerified'] == true) {
        msg = 'E-posta adresin zaten doğrulanmış.';
      } else if (body is Map && body['message'] is String) {
        msg = body['message'] as String;
      } else {
        msg = 'Doğrulama e-postası gönderildi. Gelen kutunu ve spam klasörünü kontrol et.';
      }
    } catch (e) {
      msg = ApiException.userMessage(e);
    }
    if (!mounted) return;
    setState(() => _sendingMail = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  IconData _channelIcon(AppNotificationChannel c) => switch (c) {
        AppNotificationChannel.messages => Icons.chat_bubble_rounded,
        AppNotificationChannel.liveStarters => Icons.sensors_rounded,
        AppNotificationChannel.dailyFortune => Icons.auto_awesome_rounded,
        AppNotificationChannel.other => Icons.notifications_rounded,
      };

  Color _channelColor(AppNotificationChannel c) => switch (c) {
        AppNotificationChannel.messages => const Color(0xFFEF4444),
        AppNotificationChannel.liveStarters => const Color(0xFF22C55E),
        AppNotificationChannel.dailyFortune => const Color(0xFF8B5CF6),
        AppNotificationChannel.other => const Color(0xFFF59E0B),
      };

  @override
  Widget build(BuildContext context) {
    final values = _values;
    return MockScaffold(
      title: 'Bildirimler',
      body: values == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsetsDirectional.fromSTEB(14, 6, 14, 32),
              children: [
                const NotificationPermissionBanner(),
                const SizedBox(height: 10),
                for (final c in AppNotificationChannel.values) ...[
                  MockSwitchRow(
                    key: ValueKey('notif-switch-${c.name}'),
                    icon: _channelIcon(c),
                    color: _channelColor(c),
                    title: c.label,
                    subtitle: c.description,
                    value: values[c] ?? true,
                    onChanged: (v) => unawaited(_toggle(c, v)),
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 6),
                MockListRow(
                  icon: Icons.mark_email_read_rounded,
                  color: const Color(0xFF3B82F6),
                  title: 'E-posta bildirimleri',
                  subtitle: 'Şifre sıfırlama, ödeme ve doğrulama e-postaları',
                  value: _sendingMail ? 'Gönderiliyor…' : 'Doğrulama gönder',
                  onTap: _sendingMail
                      ? null
                      : () => unawaited(_sendVerificationMail()),
                ),
                const SizedBox(height: 8),
                MockListRow(
                  icon: Icons.health_and_safety_rounded,
                  color: const Color(0xFF22C55E),
                  title: 'Bildirim tanılama',
                  subtitle: 'Bildirim gelmiyorsa nedenini gör ve onar',
                  onTap: () => context.push('/settings/notifications/diagnostics'),
                ),
                const SizedBox(height: 8),
                MockListRow(
                  icon: Icons.settings_rounded,
                  color: const Color(0xFF6B7080),
                  title: 'Sistem bildirim ayarları',
                  subtitle: 'Android kanal ayarlarını aç',
                  onTap: () => unawaited(openAppSettings()),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tercihlerin bu cihazda saklanır. Uygulama kapalıyken '
                  'sunucudan gelen bildirimleri tamamen kapatmak için sistem '
                  'ayarlarındaki kanalları da kullanabilirsin.',
                  style: TextStyle(
                    color: context.colors.onSurfaceMuted,
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
    );
  }
}
