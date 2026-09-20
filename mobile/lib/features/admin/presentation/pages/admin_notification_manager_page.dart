import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../providers/admin_preferences_provider.dart';
import '../providers/staff_access_provider.dart';

/// Admin bildirim yönetimi — severity filter, mute, öncelik.
class AdminNotificationManagerPage extends ConsumerWidget {
  const AdminNotificationManagerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(staffAccessProvider);
    if (!access.canViewActivityLog) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bildirim Yönetimi')),
        body: const Center(
          child: Text('Yalnızca admin erişebilir.'),
        ),
      );
    }

    final prefs = ref.watch(adminPreferencesProvider);
    final notifier = ref.read(adminPreferencesProvider.notifier);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Bildirim Yönetimi'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Durum
          _StatusCard(
            enabled: prefs.notificationsEnabled,
            filters: prefs.notificationFilters,
          ),

          const SizedBox(height: 24),
          const Text(
            'Bildirim Kuralları',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 12),
          _RuleCard(
            title: 'Hata Bildirimleri',
            icon: Icons.error_outline_rounded,
            color: AppThemeColors.liveRed,
            description: 'Kritik hata ve sistem arızaları',
            enabled: prefs.notificationFilters.contains('error'),
            onToggle: (enabled) {
              final filters = Set<String>.from(prefs.notificationFilters);
              if (enabled) {
                filters.add('error');
              } else {
                filters.remove('error');
              }
              notifier.update(prefs.copyWith(notificationFilters: filters));
            },
          ),

          const SizedBox(height: 12),
          _RuleCard(
            title: 'Uyarı Bildirimleri',
            icon: Icons.warning_outlined,
            color: Colors.orange,
            description: 'Moderasyon uyarıları, riskli işlemler',
            enabled: prefs.notificationFilters.contains('warning'),
            onToggle: (enabled) {
              final filters = Set<String>.from(prefs.notificationFilters);
              if (enabled) {
                filters.add('warning');
              } else {
                filters.remove('warning');
              }
              notifier.update(prefs.copyWith(notificationFilters: filters));
            },
          ),

          const SizedBox(height: 12),
          _RuleCard(
            title: 'Bilgi Bildirimleri',
            icon: Icons.info_outline_rounded,
            color: AppThemeColors.accentCyan,
            description: 'Aktivite günlüğü, sistem güncellemeleri',
            enabled: prefs.notificationFilters.contains('info'),
            onToggle: (enabled) {
              final filters = Set<String>.from(prefs.notificationFilters);
              if (enabled) {
                filters.add('info');
              } else {
                filters.remove('info');
              }
              notifier.update(prefs.copyWith(notificationFilters: filters));
            },
          ),

          const SizedBox(height: 24),
          const Text(
            'Kanal Ayarları',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Bildirim Sesi'),
                    subtitle: const Text('Bildirimlerde ses çal'),
                    value: prefs.soundEnabled,
                    onChanged: (v) =>
                        notifier.update(prefs.copyWith(soundEnabled: v)),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Sistem Tray'),
                    subtitle: const Text('Desktop tray bildirimini göster'),
                    value: prefs.systemTrayNotifications,
                    onChanged: (v) => notifier.update(
                      prefs.copyWith(systemTrayNotifications: v),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          const Text(
            'Hızlı İşlemler',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      notifier.update(
                        prefs.copyWith(
                          notificationFilters: {'error', 'warning', 'info'},
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tüm bildirimler açıldı'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.done_all),
                    label: const Text('Tümünü aç'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      notifier.update(
                        prefs.copyWith(notificationFilters: {}),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tüm bildirimler kapatıldı'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.block),
                    label: const Text('Tümünü kapat'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      notifier.update(
                        const AdminPreferences(),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Varsayılan ayarlara döndürüldü'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.restore),
                    label: const Text('Varsayılana döndür'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.enabled,
    required this.filters,
  });

  final bool enabled;
  final Set<String> filters;

  @override
  Widget build(BuildContext context) {
    final filterCount = filters.length;
    return Card(
      color: enabled
          ? AppThemeColors.accentCyan.withValues(alpha: 0.1)
          : Colors.grey.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  enabled ? Icons.notifications_active : Icons.notifications_off,
                  color: enabled ? AppThemeColors.accentCyan : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        enabled ? 'Bildirimler Açık' : 'Bildirimler Kapalı',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: enabled ? null : Colors.grey,
                        ),
                      ),
                      if (enabled)
                        Text(
                          '$filterCount türü aktif',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.description,
    required this.enabled,
    required this.onToggle,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String description;
  final bool enabled;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: enabled,
              onChanged: onToggle,
            ),
          ],
        ),
      ),
    );
  }
}
