import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/push/notification_channels.dart';
import '../../../../core/push/push_notification_service.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../../core/widgets/settings_kit.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
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

  Color _channelAccent(AppNotificationChannel c) => switch (c) {
        AppNotificationChannel.messages => context.accentCyan,
        AppNotificationChannel.liveStarters => context.liveRed,
        AppNotificationChannel.dailyFortune => context.accentPurple,
        AppNotificationChannel.other => context.coinGold,
      };

  @override
  Widget build(BuildContext context) {
    final values = _values;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: 'Bildirim ayarları',
          subtitle: 'Hangi bildirimleri almak istediğini seç',
          body: values == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  children: [
                    const NotificationPermissionBanner(),
                    const SizedBox(height: 14),
                    SettingsTileGrid(
                      children: [
                        for (final c in AppNotificationChannel.values)
                          SettingsToggleTile(
                            key: ValueKey('notif-switch-${c.name}'),
                            icon: _channelIcon(c),
                            label: c.label,
                            subtitle: c.description,
                            accent: _channelAccent(c),
                            value: values[c] ?? true,
                            onChanged: (v) => unawaited(_toggle(c, v)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => unawaited(openAppSettings()),
                      icon: const Icon(Icons.settings_outlined),
                      label: const Text('Sistem bildirim ayarlarını aç'),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Tercihlerin bu cihazda saklanır. Uygulama kapalıyken '
                      'sunucudan gelen bildirimleri tamamen kapatmak için sistem '
                      'ayarlarındaki kanalları da kullanabilirsin.',
                      style: TextStyle(
                        color: context.colors.onSurfaceMuted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
