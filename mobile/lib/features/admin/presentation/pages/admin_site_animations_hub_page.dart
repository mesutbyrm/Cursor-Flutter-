import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/site_animation/data/site_animation_cache.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../domain/admin_site_animation.dart';
import '../providers/admin_site_animation_providers.dart';
import '../providers/staff_access_provider.dart';
import '../widgets/admin_site_animation_stats_grid.dart';

/// Site Animasyonları — dashboard + alt menü.
class AdminSiteAnimationsHubPage extends ConsumerWidget {
  const AdminSiteAnimationsHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(staffAccessProvider);
    if (!access.canManageSiteAnimations) {
      return _locked(context);
    }

    final statsAsync = ref.watch(adminSiteAnimationStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0E0524),
      body: DiscoverBackground(
        child: Column(
          children: [
            SizedBox(height: MediaQuery.paddingOf(context).top + 4),
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 12),
              child: Row(
                children: [
                  DiscoverIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: () => context.pop(),
                  ),
                  const Expanded(
                    child: DiscoverTabHeader(
                      title: '🎨 Site Animasyonları',
                      subtitle: 'Giriş, çıkış, koltuk, oda efektleri',
                    ),
                  ),
                  DiscoverIconButton(
                    icon: Icons.refresh_rounded,
                    onPressed: () {
                      ref.invalidate(adminSiteAnimationListProvider);
                      ref.invalidate(adminSiteAnimationStatsProvider);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  statsAsync.when(
                    loading: () => const Center(child: DiscoverAccentLoader()),
                    error: (_, _) => const AdminSiteAnimationStatsGrid(
                      stats: AdminSiteAnimationStats(),
                    ),
                    data: (stats) => AdminSiteAnimationStatsGrid(stats: stats),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Kategoriler',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AdminSiteAnimationCategory.hubCategories
                        .map(
                          (cat) => ActionChip(
                            label: Text(cat.label),
                            backgroundColor: const Color(0xFF1A0F33),
                            labelStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                            onPressed: () => context.push(
                              '/admin/site-animations/library?category=${cat.name}',
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  _NavTile(
                    icon: Icons.collections_rounded,
                    title: 'Animasyon Kütüphanesi',
                    subtitle: 'Preview, düzenle, ata, pasifleştir',
                    onTap: () => context.push('/admin/site-animations/library'),
                  ),
                  _NavTile(
                    icon: Icons.add_circle_outline_rounded,
                    title: 'Animasyon Ekle',
                    subtitle: 'Asset, süre, priority, anchor',
                    onTap: () => context.push('/admin/site-animations/new'),
                  ),
                  _NavTile(
                    icon: Icons.workspace_premium_outlined,
                    title: 'Üyelik Eşleştirme',
                    subtitle: 'Giriş + çıkış varsayılan animasyonları',
                    onTap: () => context.push('/admin/site-animations/defaults'),
                  ),
                  _NavTile(
                    icon: Icons.person_search_rounded,
                    title: 'Kullanıcıya Özel',
                    subtitle: 'Entrance, exit, seat, mic, VIP…',
                    onTap: () => context.push('/admin/site-animations/user-assign'),
                  ),
                  _NavTile(
                    icon: Icons.card_giftcard_outlined,
                    title: 'Ödül Animasyonu',
                    subtitle: 'Etkinlik / günlük giriş — süreli atama',
                    onTap: () => context.push('/admin/site-animations/reward'),
                  ),
                  _NavTile(
                    icon: Icons.group_add_outlined,
                    title: 'Toplu Atama',
                    subtitle: 'Gold üyeler, oda, etkinlik',
                    onTap: () => context.push('/admin/site-animations/bulk-assign'),
                  ),
                  _NavTile(
                    icon: Icons.play_circle_outline_rounded,
                    title: 'Ekran Önizleme',
                    subtitle: 'Sosyal, profil, sesli oda, Fal & Tarot mock',
                    onTap: () => context.push('/admin/site-animations/preview'),
                  ),
                  _NavTile(
                    icon: Icons.cloud_upload_outlined,
                    title: 'CDN Yükleme Rehberi',
                    subtitle: 'production / preview / sounds path örnekleri',
                    onTap: () => _showCdnGuideDialog(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCdnGuideDialog(BuildContext context) {
    const sampleId = 'anim_entrance_gold_crown';
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF12082A),
        title: const Text('CDN asset pipeline'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Dosyaları cdn.canlifal.com/animations/ altına yükle. '
                'Editördeki CDN doldur chip\'leri bu path\'leri otomatik yazır.',
                style: TextStyle(fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 12),
              _CdnPathRow(
                label: 'Üretim (.lottie)',
                path: SiteAnimationAssetPaths.production(sampleId),
              ),
              _CdnPathRow(
                label: 'Önizleme (.mp4)',
                path: SiteAnimationAssetPaths.preview(sampleId),
              ),
              _CdnPathRow(
                label: 'Ses (.mp3)',
                path: SiteAnimationAssetPaths.sound(sampleId),
              ),
              const SizedBox(height: 8),
              Text(
                'Detay: docs/SITE_ANIMATION_CDN.md',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _locked(BuildContext context) {
    return Scaffold(
      body: DiscoverBackground(
        child: Center(
          child: DiscoverEmptyState(
            icon: Icons.lock_outline_rounded,
            message: 'Site animasyonları yalnızca yetkili admin içindir.',
            actionLabel: 'Geri',
            action: () => Navigator.of(context).maybePop(),
          ),
        ),
      ),
    );
  }
}

class _CdnPathRow extends StatelessWidget {
  const _CdnPathRow({required this.label, required this.path});

  final String label;
  final String path;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
          SelectableText(
            path,
            style: TextStyle(
              fontSize: 10,
              color: AppThemeColors.accentPurple,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF12082A),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppThemeColors.accentPurple),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
