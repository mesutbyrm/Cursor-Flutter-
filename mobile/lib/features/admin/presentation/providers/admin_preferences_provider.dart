import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AdminLayoutMode { compact, comfortable, spacious }

enum AdminThemeMode { light, dark, system }

/// Admin tercihler — tema, layout, bildirim ayarları.
class AdminPreferences {
  final AdminThemeMode theme;
  final AdminLayoutMode layout;
  final bool compactSidebar;
  final bool notificationsEnabled;
  final Set<String> notificationFilters; // 'error', 'warning', 'info'
  final bool soundEnabled;
  final bool systemTrayNotifications;

  const AdminPreferences({
    this.theme = AdminThemeMode.system,
    this.layout = AdminLayoutMode.comfortable,
    this.compactSidebar = false,
    this.notificationsEnabled = true,
    this.notificationFilters = const {'error', 'warning', 'info'},
    this.soundEnabled = true,
    this.systemTrayNotifications = false,
  });

  AdminPreferences copyWith({
    AdminThemeMode? theme,
    AdminLayoutMode? layout,
    bool? compactSidebar,
    bool? notificationsEnabled,
    Set<String>? notificationFilters,
    bool? soundEnabled,
    bool? systemTrayNotifications,
  }) {
    return AdminPreferences(
      theme: theme ?? this.theme,
      layout: layout ?? this.layout,
      compactSidebar: compactSidebar ?? this.compactSidebar,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationFilters: notificationFilters ?? this.notificationFilters,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      systemTrayNotifications:
          systemTrayNotifications ?? this.systemTrayNotifications,
    );
  }

  Map<String, dynamic> toJson() => {
        'theme': theme.name,
        'layout': layout.name,
        'compactSidebar': compactSidebar,
        'notificationsEnabled': notificationsEnabled,
        'notificationFilters': notificationFilters.toList(),
        'soundEnabled': soundEnabled,
        'systemTrayNotifications': systemTrayNotifications,
      };

  factory AdminPreferences.fromJson(Map<String, dynamic> json) {
    return AdminPreferences(
      theme: AdminThemeMode.values.byName(json['theme'] ?? 'system'),
      layout: AdminLayoutMode.values.byName(json['layout'] ?? 'comfortable'),
      compactSidebar: json['compactSidebar'] ?? false,
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      notificationFilters: Set<String>.from(json['notificationFilters'] ?? ['error', 'warning', 'info']),
      soundEnabled: json['soundEnabled'] ?? true,
      systemTrayNotifications: json['systemTrayNotifications'] ?? false,
    );
  }
}

class AdminPreferencesNotifier extends StateNotifier<AdminPreferences> {
  AdminPreferencesNotifier(AdminPreferences initial) : super(initial);

  Future<void> update(AdminPreferences prefs) async {
    state = prefs;
    final sp = await SharedPreferences.getInstance();
    await sp.setString('admin_preferences', _jsonEncode(prefs.toJson()));
  }

  String _jsonEncode(Map<String, dynamic> data) {
    return data.toString(); // Basit JSON encode
  }
}

final adminPreferencesProvider =
    StateNotifierProvider<AdminPreferencesNotifier, AdminPreferences>((ref) {
  return AdminPreferencesNotifier(const AdminPreferences());
});
