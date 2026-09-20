import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../providers/admin_preferences_provider.dart';
import '../providers/staff_access_provider.dart';
import '../widgets/admin_local_preview_banner.dart';

/// Admin tercihler — tema, layout, bildirim ayarları.
class AdminPreferencesPage extends ConsumerWidget {
  const AdminPreferencesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(staffAccessProvider);
    if (!access.isSiteAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Tercihler')),
        body: const Center(
          child: Text('Yalnızca site admin erişebilir.'),
        ),
      );
    }

    final prefs = ref.watch(adminPreferencesProvider);
    final notifier = ref.read(adminPreferencesProvider.notifier);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Admin Tercihler'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const AdminLocalPreviewBanner(),
          const SizedBox(height: 20),

          // Tema
          _SectionHeader(title: 'Görünüm'),
          _PreferenceGroup(
            title: 'Tema',
            children: [
              _RadioTile<AdminThemeMode>(
                title: 'Açık',
                subtitle: 'Açık arka plan',
                value: AdminThemeMode.light,
                groupValue: prefs.theme,
                onChanged: (v) => notifier.update(prefs.copyWith(theme: v)),
              ),
              _RadioTile<AdminThemeMode>(
                title: 'Koyu',
                subtitle: 'Koyu arka plan',
                value: AdminThemeMode.dark,
                groupValue: prefs.theme,
                onChanged: (v) => notifier.update(prefs.copyWith(theme: v)),
              ),
              _RadioTile<AdminThemeMode>(
                title: 'Sistem',
                subtitle: 'Cihaz ayarını takip et',
                value: AdminThemeMode.system,
                groupValue: prefs.theme,
                onChanged: (v) => notifier.update(prefs.copyWith(theme: v)),
              ),
            ],
          ),

          // Layout
          _PreferenceGroup(
            title: 'Düzen',
            children: [
              _RadioTile<AdminLayoutMode>(
                title: 'Kompakt',
                subtitle: 'Daha az boşluk',
                value: AdminLayoutMode.compact,
                groupValue: prefs.layout,
                onChanged: (v) => notifier.update(prefs.copyWith(layout: v)),
              ),
              _RadioTile<AdminLayoutMode>(
                title: 'Rahat',
                subtitle: 'Standart boşluk (varsayılan)',
                value: AdminLayoutMode.comfortable,
                groupValue: prefs.layout,
                onChanged: (v) => notifier.update(prefs.copyWith(layout: v)),
              ),
              _RadioTile<AdminLayoutMode>(
                title: 'Geniş',
                subtitle: 'Daha fazla boşluk',
                value: AdminLayoutMode.spacious,
                groupValue: prefs.layout,
                onChanged: (v) => notifier.update(prefs.copyWith(layout: v)),
              ),
            ],
          ),

          // Sidebar
          _PreferenceGroup(
            title: 'Yan Panel',
            children: [
              SwitchListTile(
                title: const Text('Kompakt mod'),
                subtitle: const Text('Iconları gizle, metin göster'),
                value: prefs.compactSidebar,
                onChanged: (v) =>
                    notifier.update(prefs.copyWith(compactSidebar: v)),
              ),
            ],
          ),

          // Bildirimler
          const SizedBox(height: 20),
          _SectionHeader(title: 'Bildirimler'),
          _PreferenceGroup(
            title: 'Aktifleştir',
            children: [
              SwitchListTile(
                title: const Text('Bildirimleri aç'),
                subtitle: const Text('Sistem bildirimleri'),
                value: prefs.notificationsEnabled,
                onChanged: (v) => notifier.update(
                  prefs.copyWith(notificationsEnabled: v),
                ),
              ),
              if (prefs.notificationsEnabled) ...[
                SwitchListTile(
                  title: const Text('Ses'),
                  subtitle: const Text('Bildirim sesi'),
                  value: prefs.soundEnabled,
                  onChanged: (v) =>
                      notifier.update(prefs.copyWith(soundEnabled: v)),
                ),
                SwitchListTile(
                  title: const Text('Sistem tray'),
                  subtitle: const Text('Tray bildirimi'),
                  value: prefs.systemTrayNotifications,
                  onChanged: (v) => notifier.update(
                    prefs.copyWith(systemTrayNotifications: v),
                  ),
                ),
              ],
            ],
          ),

          // Bildirim filtreleri
          if (prefs.notificationsEnabled)
            _PreferenceGroup(
              title: 'Bildirim türleri',
              children: [
                _FilterChip(
                  label: 'Hata',
                  color: AppThemeColors.liveRed,
                  selected: prefs.notificationFilters.contains('error'),
                  onSelected: (selected) {
                    final filters = Set<String>.from(prefs.notificationFilters);
                    if (selected) {
                      filters.add('error');
                    } else {
                      filters.remove('error');
                    }
                    notifier.update(prefs.copyWith(notificationFilters: filters));
                  },
                ),
                _FilterChip(
                  label: 'Uyarı',
                  color: Colors.orange,
                  selected: prefs.notificationFilters.contains('warning'),
                  onSelected: (selected) {
                    final filters = Set<String>.from(prefs.notificationFilters);
                    if (selected) {
                      filters.add('warning');
                    } else {
                      filters.remove('warning');
                    }
                    notifier.update(prefs.copyWith(notificationFilters: filters));
                  },
                ),
                _FilterChip(
                  label: 'Bilgi',
                  color: AppThemeColors.accentCyan,
                  selected: prefs.notificationFilters.contains('info'),
                  onSelected: (selected) {
                    final filters = Set<String>.from(prefs.notificationFilters);
                    if (selected) {
                      filters.add('info');
                    } else {
                      filters.remove('info');
                    }
                    notifier.update(prefs.copyWith(notificationFilters: filters));
                  },
                ),
              ],
            ),

          const SizedBox(height: 40),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.check),
            label: const Text('Kaydet ve kapat'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppThemeColors.accentCyan,
        ),
      ),
    );
  }
}

class _PreferenceGroup extends StatelessWidget {
  const _PreferenceGroup({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _RadioTile<T> extends StatelessWidget {
  const _RadioTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final T value;
  final T groupValue;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<T>(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      groupValue: groupValue,
      onChanged: (v) => v != null ? onChanged(v) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final Color color;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: onSelected,
        backgroundColor: color.withValues(alpha: 0.1),
        selectedColor: color.withValues(alpha: 0.3),
        side: BorderSide(
          color: selected ? color : color.withValues(alpha: 0.2),
        ),
      ),
    );
  }
}
