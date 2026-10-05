import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/bootstrap/app_cache_clear.dart';
import '../../../../core/design_system/cds_colors.dart';
import '../../../../core/design_system/cds_fx.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/mock_ui_kit.dart';
import '../../../../core/widgets/settings_kit.dart';
import '../../../../core/widgets/theme_mode_selector.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/account_privacy_providers.dart';
import '../providers/profile_providers.dart';
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
    subtitle: 'Hesap bilgileri, güvenlik, telefon',
    icon: Icons.person_rounded,
    accent: Color(0xFF6B7080),
  ),
  SettingsCategoryData(
    slug: 'bildirimler',
    title: 'Bildirimler',
    subtitle: 'Push ve bildirim tercihleri',
    icon: Icons.notifications_rounded,
    accent: Color(0xFFFF7A2F),
  ),
  SettingsCategoryData(
    slug: 'gizlilik',
    title: 'Gizlilik ve Güvenlik',
    subtitle: 'Gizlilik ayarları, engellenenler',
    icon: Icons.lock_rounded,
    accent: Color(0xFF22C55E),
  ),
  SettingsCategoryData(
    slug: 'dil',
    title: 'Dil ve Bölge',
    subtitle: 'Türkçe',
    icon: Icons.language_rounded,
    accent: Color(0xFF7C5CFF),
  ),
  SettingsCategoryData(
    slug: 'gorunum',
    title: 'Görünüm',
    subtitle: 'Tema, karanlık mod, performans',
    icon: Icons.palette_rounded,
    accent: Color(0xFF8B5CF6),
  ),
  SettingsCategoryData(
    slug: 'cuzdan',
    title: 'Cüzdan ve Ödemeler',
    subtitle: 'Jeton, CFC, ödeme geçmişi',
    icon: Icons.account_balance_wallet_rounded,
    accent: Color(0xFFF59E0B),
  ),
  SettingsCategoryData(
    slug: 'canli',
    title: 'Canlı Yayın',
    subtitle: 'Yayın tercihleri',
    icon: Icons.videocam_rounded,
    accent: Color(0xFF5B5BF6),
  ),
  SettingsCategoryData(
    slug: 'sesli',
    title: 'Sesli Odalar',
    subtitle: 'Oda ayarları',
    icon: Icons.mic_rounded,
    accent: Color(0xFF14B8A6),
  ),
  SettingsCategoryData(
    slug: 'muzik',
    title: 'Müzik',
    subtitle: 'Ses ve müzik ayarları',
    icon: Icons.music_note_rounded,
    accent: Color(0xFFE11D9A),
  ),
  SettingsCategoryData(
    slug: 'video',
    title: 'Video',
    subtitle: 'Video kalitesi, otomatik oynatma',
    icon: Icons.play_circle_rounded,
    accent: Color(0xFF10B981),
  ),
  SettingsCategoryData(
    slug: 'veri',
    title: 'Veri Kullanımı',
    subtitle: 'Mobil veri ve indirme ayarları',
    icon: Icons.bar_chart_rounded,
    accent: Color(0xFF3B82F6),
  ),
  SettingsCategoryData(
    slug: 'erisilebilirlik',
    title: 'Erişilebilirlik',
    subtitle: 'Yazı boyutu, kontrast',
    icon: Icons.accessibility_new_rounded,
    accent: Color(0xFF2D8CFF),
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
    accent: Color(0xFF8A8FA3),
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
    final title = switch (slug) {
      'cuzdan' => 'Cüzdanım',
      _ => cat?.title ?? 'Ayarlar',
    };
    return MockScaffold(
      title: title,
      body: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 6, 14, 40),
        children: cat == null
            ? [
                const SettingsPanel(
                  child: Text('Bu ayar kategorisi bulunamadı.'),
                ),
              ]
            : _sections(context, ref, cat),
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
        final sessions = ref.watch(activeSessionsProvider).valueOrNull;
        final blocked = ref.watch(blockedUsersProvider).valueOrNull;
        return [
          MockListRow(
            icon: Icons.block_rounded,
            color: const Color(0xFFEF4444),
            title: 'Engellenenler',
            value: blocked == null ? null : '${blocked.length} kişi',
            onTap: () => context.push('/settings/blocked'),
          ),
          const SizedBox(height: 8),
          MockListRow(
            icon: Icons.lock_rounded,
            color: const Color(0xFF8B5CF6),
            title: 'Şifre Değiştir',
            onTap: () => context.push('/profile/security'),
          ),
          const SizedBox(height: 8),
          MockListRow(
            icon: Icons.devices_rounded,
            color: const Color(0xFF3B82F6),
            title: 'Giriş Cihazları',
            value: sessions == null ? null : '${sessions.length} cihaz',
            onTap: () => context.push('/settings/devices'),
          ),
          const SettingsSectionHeader(
            'Gizlilik & VIP',
            icon: Icons.visibility_off_rounded,
          ),
          const VipPrivacySettingsSection(),
          const SizedBox(height: 14),
          MockListRow(
            icon: Icons.delete_forever_rounded,
            color: const Color(0xFFEF4444),
            title: 'Hesabı Sil',
            subtitle: 'Hesabın kalıcı olarak silinir',
            danger: true,
            onTap: () => _confirmDeleteAccount(context, ref),
          ),
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
        final wallet = ref.watch(walletBalancesProvider).valueOrNull;
        final nf = NumberFormat.decimalPattern('tr');
        return [
          _BalanceCard(
            color: const Color(0xFFF59E0B),
            icon: Icons.monetization_on_rounded,
            amount: nf.format(wallet?.jeton ?? user?.coinBalance ?? 0),
            unit: 'Jeton',
            onBuy: () => context.push('/jeton-store'),
          ),
          const SizedBox(height: 10),
          _BalanceCard(
            color: const Color(0xFF8B5CF6),
            icon: Icons.diamond_rounded,
            amount: nf.format(wallet?.cfc ?? 0),
            unit: 'CFC',
            onBuy: () => context.push('/cfc-store'),
          ),
          const SizedBox(height: 14),
          MockListRow(
            icon: Icons.receipt_long_rounded,
            color: const Color(0xFF3B82F6),
            title: 'İşlem Geçmişi',
            onTap: () => context.push('/profile/transactions'),
          ),
          const SizedBox(height: 8),
          MockListRow(
            icon: Icons.account_balance_wallet_rounded,
            color: const Color(0xFFF59E0B),
            title: 'Cüzdan',
            subtitle: 'Jeton ve CFC bakiyesi',
            onTap: () => context.push('/wallet'),
          ),
          const SizedBox(height: 8),
          MockListRow(
            icon: Icons.card_giftcard_rounded,
            color: const Color(0xFFEC4899),
            title: 'Hediye Geçmişi',
            onTap: () => context.push('/profile/gifts'),
          ),
          const SizedBox(height: 8),
          MockListRow(
            icon: Icons.payments_rounded,
            color: const Color(0xFF22C55E),
            title: 'Kazançlarım',
            subtitle: 'Yayın kazançları',
            onTap: () => context.push('/profile/earnings'),
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

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final pw = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hesabı sil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hesabın kalıcı olarak silinir. Jeton, CFC ve üyelik '
              'bakiyelerin iade edilmez.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pw,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Şifre (şifreli hesaplar için)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hesabı sil'),
          ),
        ],
      ),
    );
    final password = pw.text;
    // Dialog kapanış animasyonu bitmeden dispose etme.
    Future<void>.delayed(const Duration(milliseconds: 600), pw.dispose);
    if (ok != true || !context.mounted) return;
    try {
      await deleteMyAccount(ref, password: password);
      await ref.read(authControllerProvider.notifier).logout();
      if (context.mounted) context.go('/auth/login');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
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

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.color,
    required this.icon,
    required this.amount,
    required this.unit,
    required this.onBuy,
  });

  final Color color;
  final IconData icon;
  final String amount;
  final String unit;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [color.withValues(alpha: 0.28), mockCardColor(context)],
        ),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  amount,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: c.onSurface,
                    height: 1.1,
                  ),
                ),
                Text(
                  unit,
                  style: TextStyle(fontSize: 12, color: c.onSurfaceMuted),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: onBuy,
            style: FilledButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
            ),
            child: const Text('Satın Al'),
          ),
        ],
      ),
    );
  }
}
