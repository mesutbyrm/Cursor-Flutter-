import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/push/notification_channels.dart';
import '../../../../core/push/push_notification_service.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/mock_ui_kit.dart';
import '../widgets/notification_permission_banner.dart';

/// Kanal bazlı bildirim tercihleri — Mesajlar, Canlı yayın başlatanlar,
/// Günlük fal önerisi, Diğer.
///
/// Tercihler bu cihazda saklanır ve uygulanır (backend'de bildirim tercihi
/// ucu yoktur). Sistem düzeyinde de kanal bazlı yönetim için Android'in
/// "Bildirim ayarları" ekranına kısayol vardır.
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

  Future<void> _load() async {
    final all = await _prefs.loadAll();
    if (mounted) setState(() => _values = all);
  }

  Future<void> _toggle(AppNotificationChannel c, bool v) async {
    setState(() => _values = {...?_values, c: v});
    await _prefs.setEnabled(c, v);
    if (c == AppNotificationChannel.dailyFortune) {
      // Günlük fal önerisi kapanınca zamanlanmış hatırlatıcı da iptal edilir;
      // açılınca günde bir kez yeniden planlanır.
      await PushNotificationService.instance.setDailyFortuneReminderEnabled(v);
    }
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
