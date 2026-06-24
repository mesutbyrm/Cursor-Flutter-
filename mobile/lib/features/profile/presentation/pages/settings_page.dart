import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../../core/widgets/theme_mode_selector.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../fortune/presentation/widgets/fortune_auto_share_setting_tile.dart';
import '../widgets/premium/profile_glass.dart';

/// Merkezi ayarlar — hesap, güvenlik, gizlilik, bildirimler.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: 'Ayarlar',
          subtitle: 'Hesap, güvenlik ve tercihler',
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              const _SectionLabel('Hesap'),
              ProfileGlass(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.person_outline_rounded,
                      label: 'Profili Düzenle',
                      onTap: () => context.push('/profile/edit'),
                    ),
                    const _Divider(),
                    _SettingsTile(
                      icon: Icons.email_outlined,
                      label: 'E-posta Doğrulama',
                      onTap: () {
                        final email = user?.email;
                        if (email == null || !email.contains('@')) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('E-posta bilgisi bulunamadı'),
                            ),
                          );
                          return;
                        }
                        context.push('/auth/otp-verify', extra: email);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const _SectionLabel('Güvenlik'),
              ProfileGlass(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.lock_outline_rounded,
                      label: 'Şifre Değiştir',
                      onTap: () => context.push('/profile/security'),
                    ),
                    const _Divider(),
                    _SettingsTile(
                      icon: Icons.devices_rounded,
                      label: 'Aktif Cihazlar',
                      onTap: () => context.push('/settings/devices'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const _SectionLabel('Gizlilik'),
              ProfileGlass(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _PrivacyToggle(
                      label: 'Profilimi herkese açık göster',
                      initial: true,
                    ),
                    const _Divider(),
                    _PrivacyToggle(
                      label: 'Çevrimiçi durumumu göster',
                      initial: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const _SectionLabel('Bildirimler'),
              ProfileGlass(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.notifications_outlined,
                      label: 'Bildirim Ayarları',
                      onTap: () => context.push('/notifications'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const _SectionLabel('Fal & Paylaşım'),
              const ProfileGlass(
                padding: EdgeInsets.zero,
                child: FortuneAutoShareSettingTile(),
              ),
              const SizedBox(height: 20),
              const _SectionLabel('Görünüm'),
              const ThemeModeSelector(),
              const SizedBox(height: 20),
              const _SectionLabel('Diğer'),
              ProfileGlass(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.help_outline_rounded,
                      label: 'Yardım & Destek',
                      onTap: () => context.push('/profile/help'),
                    ),
                    const _Divider(),
                    _SettingsTile(
                      icon: Icons.info_outline_rounded,
                      label: 'Hakkımızda',
                      onTap: () => context.push('/profile/about'),
                    ),
                    const _Divider(),
                    _SettingsTile(
                      icon: Icons.logout_rounded,
                      label: 'Çıkış Yap',
                      destructive: true,
                      onTap: () async {
                        try {
                          await ref.read(authControllerProvider.notifier).logout();
                          if (context.mounted) context.go('/auth/login');
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(ApiException.userMessage(e))),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 13,
          color: context.colors.onSurfaceMuted,
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, indent: 52, color: context.colors.outlineVariant);
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? trailing;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? const Color(0xFFFF5252)
        : context.colors.onSurface;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
      trailing: trailing != null
          ? Text(trailing!, style: TextStyle(color: context.colors.onSurfaceMuted))
          : Icon(Icons.chevron_right_rounded, color: context.colors.onSurfaceMuted),
      onTap: onTap,
    );
  }
}

class _PrivacyToggle extends StatefulWidget {
  const _PrivacyToggle({required this.label, required this.initial});

  final String label;
  final bool initial;

  @override
  State<_PrivacyToggle> createState() => _PrivacyToggleState();
}

class _PrivacyToggleState extends State<_PrivacyToggle> {
  late var _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(
        widget.label,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      value: _value,
      onChanged: (v) => setState(() => _value = v),
    );
  }
}
