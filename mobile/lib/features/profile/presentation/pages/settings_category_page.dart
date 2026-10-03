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
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../../fortune/presentation/widgets/fortune_auto_share_setting_tile.dart';
import '../premium_2026/profile_membership_helpers.dart';
import '../widgets/vip_privacy_settings_section.dart';

/// Ayarlar kategorisi — ana listedeki her kart için gerçek detay sayfası.
///
/// Yalnızca uygulamada gerçekten çalışan ayarlar gösterilir; sunucuda ya da
/// cihazda karşılığı olmayan seçenekler (ör. hesap silme) listelenmez.
class SettingsCategoryData {
  const SettingsCategoryData({
    required this.slug,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  final String slug;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;

  /// Ayrı bir sayfası olan kategoriler doğrudan oraya gider.
  String get route => switch (slug) {
        'bildirimler' => '/settings/notifications',
        'muzik' => '/settings/voice-audio',
        'yardim' => '/profile/help',
        'hakkinda' => '/profile/about',
        _ => '/settings/c/$slug',
      };
}

const settingsCategories = <SettingsCategoryData>[
  SettingsCategoryData(
    slug: 'hesap',
    title: 'Hesap',
    subtitle: 'Hesap bilgileri, güvenlik, e-posta',
    icon: Icons.person_rounded,
    accent: Color(0xFF7C5CFF),
  ),
  SettingsCategoryData(
    slug: 'bildirimler',
    title: 'Bildirimler',
    subtitle: 'Push ve bildirim tercihleri',
    icon: Icons.notifications_rounded,
    accent: Color(0xFFFF7A45),
  ),
  SettingsCategoryData(
    slug: 'gizlilik',
    title: 'Gizlilik ve Güvenlik',
    subtitle: 'Gizlilik ayarları, şifre, cihazlar',
    icon: Icons.lock_rounded,
    accent: Color(0xFF2ECC71),
  ),
  SettingsCategoryData(
    slug: 'dil',
    title: 'Dil ve Bölge',
    subtitle: 'Uygulama dili ve bölge',
    icon: Icons.language_rounded,
    accent: Color(0xFF8E6BFF),
  ),
  SettingsCategoryData(
    slug: 'gorunum',
    title: 'Görünüm',
    subtitle: 'Tema, karanlık mod, performans',
    icon: Icons.palette_rounded,
    accent: Color(0xFF9B59FF),
  ),
  SettingsCategoryData(
    slug: 'cuzdan',
    title: 'Cüzdan ve Ödemeler',
    subtitle: 'Jeton, CFC, ödeme geçmişi',
    icon: Icons.account_balance_wallet_rounded,
    accent: Color(0xFFFFB020),
  ),
  SettingsCategoryData(
    slug: 'canli',
    title: 'Canlı Yayın',
    subtitle: 'Yayın tercihleri ve davetler',
    icon: Icons.videocam_rounded,
    accent: Color(0xFFFF3D71),
  ),
  SettingsCategoryData(
    slug: 'sesli',
    title: 'Sesli Odalar',
    subtitle: 'Oda ayarları ve giriş efekti',
    icon: Icons.mic_rounded,
    accent: Color(0xFF1ED6C4),
  ),
  SettingsCategoryData(
    slug: 'muzik',
    title: 'Müzik',
    subtitle: 'Ses ve müzik ayarları',
    icon: Icons.music_note_rounded,
    accent: Color(0xFFE056FD),
  ),
  SettingsCategoryData(
    slug: 'video',
    title: 'Video',
    subtitle: 'Video kalitesi, otomatik oynatma',
    icon: Icons.play_circle_rounded,
    accent: Color(0xFF19C37D),
  ),
  SettingsCategoryData(
    slug: 'veri',
    title: 'Veri Kullanımı',
    subtitle: 'Mobil veri ve önbellek',
    icon: Icons.bar_chart_rounded,
    accent: Color(0xFF3B82F6),
  ),
  SettingsCategoryData(
    slug: 'erisilebilirlik',
    title: 'Erişilebilirlik',
    subtitle: 'Animasyon azaltma ve sadeleştirme',
    icon: Icons.accessibility_new_rounded,
    accent: Color(0xFF00B4D8),
  ),
  SettingsCategoryData(
    slug: 'yardim',
    title: 'Yardım ve Destek',
    subtitle: 'SSS, destek talebi',
    icon: Icons.support_agent_rounded,
    accent: Color(0xFF7C5CFF),
  ),
  SettingsCategoryData(
    slug: 'hakkinda',
    title: 'Hakkında',
    subtitle: 'Sürüm, kullanım koşulları',
    icon: Icons.info_rounded,
    accent: Color(0xFF94A3B8),
  ),
];

SettingsCategoryData? settingsCategoryBySlug(String slug) {
  for (final c in settingsCategories) {
    if (c.slug == slug) return c;
  }
  return null;
}

class SettingsCategoryPage extends ConsumerWidget {
  const SettingsCategoryPage({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cat = settingsCategoryBySlug(slug);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: cat?.title ?? 'Ayarlar',
          subtitle: cat?.subtitle,
          body: ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 40),
            children: cat == null
                ? [
                    const SettingsPanel(
                      child: Text('Bu ayar kategorisi bulunamadı.'),
                    ),
                  ]
                : _sections(context, ref, cat),
          ),
        ),
      ),
    );
  }

  List<Widget> _sections(
    BuildContext context,
    WidgetRef ref,
    SettingsCategoryData cat,
  ) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    switch (cat.slug) {
      case 'hesap':
        return [
          SettingsTileGrid(
            children: [
              SettingsTileCard(
                icon: Icons.person_outline_rounded,
                label: 'Profili Düzenle',
                subtitle: 'Ad, fotoğraf, biyografi',
                accent: cat.accent,
                onTap: () => context.push('/profile/edit'),
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
                      const SnackBar(content: Text('E-posta bilgisi bulunamadı')),
                    );
                    return;
                  }
                  context.push('/auth/otp-verify', extra: email);
                },
              ),
              SettingsTileCard(
                icon: Icons.palette_outlined,
                label: buildMembershipSettingsCosmeticsRowLabel(),
                subtitle: 'Çerçeve ve efektler',
                accent: CdsColors.accentPink,
                onTap: () => context.push('/profile/cosmetics'),
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
          const SettingsSectionHeader(
            'Fal & Paylaşım',
            icon: Icons.auto_awesome_rounded,
          ),
          const SettingsPanel(
            padding: EdgeInsets.zero,
            child: FortuneAutoShareSettingTile(),
          ),
        ];
      case 'gizlilik':
        return [
          SettingsTileGrid(
            children: [
              SettingsTileCard(
                icon: Icons.lock_outline_rounded,
                label: 'Şifre Değiştir',
                subtitle: 'Hesap güvenliği',
                accent: cat.accent,
                onTap: () => context.push('/profile/security'),
              ),
              SettingsTileCard(
                icon: Icons.devices_rounded,
                label: 'Aktif Cihazlar',
                subtitle: 'Oturum açık cihazlar',
                accent: cat.accent,
                onTap: () => context.push('/settings/devices'),
              ),
            ],
          ),
          const SettingsSectionHeader(
            'Gizlilik & VIP',
            icon: Icons.visibility_off_rounded,
          ),
          const VipPrivacySettingsSection(),
        ];
      case 'dil':
        return [
          SettingsPanel(
            title: 'Uygulama dili',
            icon: Icons.language_rounded,
            accent: cat.accent,
            child: const Text(
              'Türkçe (Türkiye)',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
          const SizedBox(height: 10),
          SettingsPanel(
            child: Text(
              'Şu anda uygulama yalnızca Türkçe arayüzle yayınlanıyor. '
              'Ek diller eklendiğinde seçim burada yapılacak.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: context.colors.onSurfaceMuted,
              ),
            ),
          ),
        ];
      case 'gorunum':
        return [
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
        ];
      case 'cuzdan':
        return [
          SettingsTileGrid(
            children: [
              SettingsTileCard(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Cüzdan',
                subtitle: 'Jeton ve CFC bakiyesi',
                accent: cat.accent,
                onTap: () => context.push('/wallet'),
              ),
              SettingsTileCard(
                icon: Icons.add_card_rounded,
                label: 'Jeton Satın Al',
                subtitle: 'Jeton paketleri',
                accent: cat.accent,
                onTap: () => context.push('/jeton-store'),
              ),
              SettingsTileCard(
                icon: Icons.currency_exchange_rounded,
                label: 'CFC Satın Al',
                subtitle: 'CFC paketleri',
                accent: CdsColors.fortuneMystic,
                onTap: () => context.push('/cfc-store'),
              ),
              SettingsTileCard(
                icon: Icons.receipt_long_rounded,
                label: 'İşlem Geçmişi',
                subtitle: 'Tüm hareketler',
                accent: CdsColors.accentCyan,
                onTap: () => context.push('/profile/transactions'),
              ),
              SettingsTileCard(
                icon: Icons.card_giftcard_rounded,
                label: 'Hediye Geçmişi',
                subtitle: 'Gönderilen ve alınan',
                accent: CdsColors.accentPink,
                onTap: () => context.push('/profile/gifts'),
              ),
              SettingsTileCard(
                icon: Icons.payments_rounded,
                label: 'Kazançlarım',
                subtitle: 'Yayın kazançları',
                accent: CdsColors.success,
                onTap: () => context.push('/profile/earnings'),
              ),
            ],
          ),
        ];
      case 'canli':
        return [
          SettingsTileGrid(
            children: [
              SettingsTileCard(
                icon: Icons.group_add_rounded,
                label: 'Ortak yayın davetleri',
                subtitle: 'Gelen ve giden davetler',
                accent: cat.accent,
                onTap: () => context.push('/co-broadcast-invites'),
              ),
              SettingsTileCard(
                icon: Icons.history_rounded,
                label: 'Yayın geçmişi',
                subtitle: 'Geçmiş yayınların',
                accent: cat.accent,
                onTap: () => context.push('/profile/broadcast-history'),
              ),
              SettingsTileCard(
                icon: Icons.insights_rounded,
                label: 'Yayıncı istatistikleri',
                subtitle: 'İzleyici ve gelir',
                accent: CdsColors.accentCyan,
                onTap: () => context.push('/profile/broadcaster-stats'),
              ),
            ],
          ),
        ];
      case 'sesli':
        return [
          SettingsTileGrid(
            children: [
              SettingsTileCard(
                icon: Icons.auto_awesome_rounded,
                label: 'Giriş efektim',
                subtitle: 'Odaya girişte görünen efekt',
                accent: CdsColors.gold,
                onTap: () => context.push('/settings/entrance-effects'),
              ),
              SettingsTileCard(
                icon: Icons.graphic_eq_rounded,
                label: 'Ses ayarları',
                subtitle: 'Mikrofon kalitesi ve efektler',
                accent: cat.accent,
                onTap: () => context.push('/settings/voice-audio'),
              ),
            ],
          ),
        ];
      case 'video':
        return [
          SettingsPanel(
            title: 'Video kalitesi',
            icon: Icons.high_quality_rounded,
            accent: cat.accent,
            child: Text(
              'Yayın görüntü kalitesi bağlantı durumuna göre otomatik '
              'uyarlanır. Manuel kalite ve otomatik oynatma seçimi henüz '
              'sunulmuyor.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: context.colors.onSurfaceMuted,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SettingsToggleTile(
            icon: Icons.speed_rounded,
            label: 'Performans modu',
            subtitle: 'Blur ve dekoratif animasyonları azaltarak akıcılığı artırır.',
            accent: CdsColors.success,
            value: ref.watch(cdsFxProvider).performanceMode,
            onChanged: (v) =>
                ref.read(cdsFxProvider.notifier).setPerformanceMode(v),
          ),
        ];
      case 'veri':
        return [
          SettingsTileGrid(
            children: [
              SettingsTileCard(
                icon: Icons.cleaning_services_outlined,
                label: 'Önbelleği Temizle',
                subtitle: 'Görsel ve API önbelleği',
                accent: cat.accent,
                onTap: () => _clearCache(context),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SettingsToggleTile(
            icon: Icons.speed_rounded,
            label: 'Performans modu',
            subtitle: 'Ağır görsel efektleri azaltır, veri ve pil tüketimini düşürür.',
            accent: CdsColors.success,
            value: ref.watch(cdsFxProvider).performanceMode,
            onChanged: (v) =>
                ref.read(cdsFxProvider.notifier).setPerformanceMode(v),
          ),
        ];
      case 'erisilebilirlik':
        return [
          SettingsToggleTile(
            icon: Icons.animation_rounded,
            label: 'Animasyonları azalt',
            subtitle: 'Dekoratif hareket ve blur kapatılır (Performans modu).',
            accent: cat.accent,
            value: ref.watch(cdsFxProvider).performanceMode,
            onChanged: (v) =>
                ref.read(cdsFxProvider.notifier).setPerformanceMode(v),
          ),
          const SizedBox(height: 10),
          SettingsPanel(
            child: Text(
              'Yazı boyutu ve kontrast, cihazınızın sistem erişilebilirlik '
              'ayarlarını izler.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: context.colors.onSurfaceMuted,
              ),
            ),
          ),
        ];
      default:
        return [
          if (kDebugMode)
            SettingsTileGrid(
              children: [
                SettingsTileCard(
                  icon: Icons.monitor_heart_outlined,
                  label: 'API Monitor',
                  onTap: () => context.push('/debug/api-monitor'),
                ),
              ],
            ),
        ];
    }
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
