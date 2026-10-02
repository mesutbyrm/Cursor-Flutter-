import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/bootstrap/app_cache_clear.dart';
import '../../../../core/design_system/cds_colors.dart';
import '../../../../core/design_system/cds_fx.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../../core/widgets/settings_kit.dart';
import '../../../../core/widgets/theme_mode_selector.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../fortune/presentation/widgets/fortune_auto_share_setting_tile.dart';
import '../../../inbox/domain/inbox_tab.dart';
import '../../../inbox/presentation/inbox_routes.dart';
import '../premium_2026/profile_membership_helpers.dart';
import '../widgets/vip_privacy_settings_section.dart';

/// Merkezi ayarlar — hesap, güvenlik, gizlilik, bildirimler (kutucuk düzeni).
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final c = context.colors;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: 'Ayarlar',
          subtitle: 'Hesap, güvenlik ve tercihler',
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
            children: [
              SettingsHeroCard(
                title: user?.display ?? 'Hesabım',
                subtitle: user?.email ?? 'Profilini düzenle',
                onTap: () => context.push('/profile/edit'),
                leading: CircleAvatar(
                  radius: 26,
                  backgroundColor: c.primary.withValues(alpha: 0.25),
                  backgroundImage: (user?.avatarUrl?.isNotEmpty ?? false)
                      ? NetworkImage(user!.avatarUrl!)
                      : null,
                  child: (user?.avatarUrl?.isNotEmpty ?? false)
                      ? null
                      : Icon(Icons.person_rounded, color: c.primary),
                ),
              ),
              const SettingsSectionHeader('Hesap', icon: Icons.person_rounded),
              SettingsTileGrid(
                children: [
                  SettingsTileCard(
                    icon: Icons.person_outline_rounded,
                    label: 'Profili Düzenle',
                    subtitle: 'Ad, fotoğraf, biyografi',
                    onTap: () => context.push('/profile/edit'),
                  ),
                  SettingsTileCard(
                    icon: Icons.palette_outlined,
                    label: buildMembershipSettingsCosmeticsRowLabel(),
                    subtitle: 'Çerçeve ve efektler',
                    accent: CdsColors.accentPink,
                    onTap: () => context.push('/profile/cosmetics'),
                  ),
                  SettingsTileCard(
                    icon: Icons.email_outlined,
                    label: 'E-posta Doğrulama',
                    subtitle: user?.email ?? 'Doğrulama kodu gönder',
                    accent: CdsColors.accentCyan,
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
                  SettingsTileCard(
                    icon: Icons.auto_awesome_rounded,
                    label: 'Giriş efektim',
                    subtitle: 'Odaya girişte görünen efekt',
                    accent: CdsColors.gold,
                    onTap: () => context.push('/settings/entrance-effects'),
                  ),
                ],
              ),
              const SettingsSectionHeader('Güvenlik', icon: Icons.shield_rounded),
              SettingsTileGrid(
                children: [
                  SettingsTileCard(
                    icon: Icons.lock_outline_rounded,
                    label: 'Şifre Değiştir',
                    subtitle: 'Hesap güvenliği',
                    accent: CdsColors.success,
                    onTap: () => context.push('/profile/security'),
                  ),
                  SettingsTileCard(
                    icon: Icons.devices_rounded,
                    label: 'Aktif Cihazlar',
                    subtitle: 'Oturum açık cihazlar',
                    accent: CdsColors.success,
                    onTap: () => context.push('/settings/devices'),
                  ),
                ],
              ),
              const SettingsSectionHeader(
                'Gizlilik & VIP',
                icon: Icons.visibility_off_rounded,
              ),
              const VipPrivacySettingsSection(),
              const SettingsSectionHeader(
                'Bildirimler',
                icon: Icons.notifications_rounded,
              ),
              SettingsTileGrid(
                children: [
                  SettingsTileCard(
                    icon: Icons.tune_rounded,
                    label: 'Bildirim ayarları',
                    subtitle: 'Hangi bildirimleri alacağını seç',
                    accent: CdsColors.accentPink,
                    onTap: () => context.push('/settings/notifications'),
                  ),
                  SettingsTileCard(
                    icon: Icons.inbox_rounded,
                    label: 'Gelen Kutusu',
                    subtitle: 'Mesajlar ve sistem bildirimleri',
                    accent: CdsColors.accentCyan,
                    onTap: () => InboxRoutes.open(context),
                  ),
                  SettingsTileCard(
                    icon: Icons.notifications_outlined,
                    label: 'Sistem bildirimleri',
                    subtitle: 'Duyurular ve uyarılar',
                    accent: CdsColors.gold,
                    onTap: () =>
                        InboxRoutes.open(context, tab: InboxTab.system),
                  ),
                ],
              ),
              const SettingsSectionHeader(
                'Canlı Yayın & Ses',
                icon: Icons.podcasts_rounded,
              ),
              SettingsTileGrid(
                children: [
                  SettingsTileCard(
                    icon: Icons.graphic_eq_rounded,
                    label: 'Ses ayarları',
                    subtitle: 'Mikrofon kalitesi ve efektler',
                    accent: CdsColors.liveHot,
                    onTap: () => context.push('/settings/voice-audio'),
                  ),
                  SettingsTileCard(
                    icon: Icons.group_add_rounded,
                    label: 'Ortak yayın davetleri',
                    subtitle: 'Gelen ve giden davetler',
                    accent: CdsColors.liveHot,
                    onTap: () => context.push('/co-broadcast-invites'),
                  ),
                ],
              ),
              const SettingsSectionHeader(
                'Fal & Paylaşım',
                icon: Icons.auto_awesome_rounded,
              ),
              const SettingsPanel(
                padding: EdgeInsets.zero,
                child: FortuneAutoShareSettingTile(),
              ),
              const SettingsSectionHeader('Görünüm', icon: Icons.brush_rounded),
              const ThemeModeSelector(),
              const SizedBox(height: 10),
              SettingsToggleTile(
                icon: Icons.speed_rounded,
                label: 'Performans modu',
                subtitle:
                    'Dekoratif animasyon ve blur azaltılır; sohbet, hediye ve yayın çalışır.',
                accent: CdsColors.success,
                value: ref.watch(cdsFxProvider).performanceMode,
                onChanged: (v) =>
                    ref.read(cdsFxProvider.notifier).setPerformanceMode(v),
              ),
              const SettingsSectionHeader(
                'Depolama',
                icon: Icons.storage_rounded,
              ),
              SettingsTileGrid(
                children: [
                  SettingsTileCard(
                    icon: Icons.cleaning_services_outlined,
                    label: 'Önbelleği Temizle',
                    subtitle: 'Görsel ve API önbelleği',
                    accent: CdsColors.accentCyan,
                    onTap: () => _clearCache(context),
                  ),
                ],
              ),
              if (kDebugMode) ...[
                const SettingsSectionHeader(
                  'Geliştirici',
                  icon: Icons.bug_report_rounded,
                ),
                SettingsTileGrid(
                  children: [
                    SettingsTileCard(
                      icon: Icons.monitor_heart_outlined,
                      label: 'API Monitor',
                      onTap: () => context.push('/debug/api-monitor'),
                    ),
                  ],
                ),
              ],
              const SettingsSectionHeader('Diğer', icon: Icons.more_horiz_rounded),
              SettingsTileGrid(
                children: [
                  SettingsTileCard(
                    icon: Icons.help_outline_rounded,
                    label: 'Yardım & Destek',
                    subtitle: 'Sık sorulanlar ve iletişim',
                    accent: CdsColors.accentCyan,
                    onTap: () => context.push('/profile/help'),
                  ),
                  SettingsTileCard(
                    icon: Icons.info_outline_rounded,
                    label: 'Hakkımızda',
                    subtitle: 'Sürüm ve yasal metinler',
                    accent: CdsColors.accentCyan,
                    onTap: () => context.push('/profile/about'),
                  ),
                  SettingsTileCard(
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
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _clearCache(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Önbelleği temizle'),
        content: const Text(
          'Görsel ve API önbelleği temizlenir. Oturum bilginiz silinmez.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await AppCacheClear.clearNonAuthCaches();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önbellek temizlendi')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    }
  }
}
