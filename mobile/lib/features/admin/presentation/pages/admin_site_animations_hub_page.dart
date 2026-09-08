import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
                    icon: Icons.group_add_outlined,
                    title: 'Toplu Atama',
                    subtitle: 'Gold üyeler, oda, etkinlik',
                    onTap: () => context.push('/admin/site-animations/bulk-assign'),
                  ),
                  _NavTile(
                    icon: Icons.play_circle_outline_rounded,
                    title: 'Oda Önizleme',
                    subtitle: 'Gerçek sesli oda mock üzerinde test',
                    onTap: () => context.push('/admin/site-animations/preview'),
                  ),
                ],
              ),
            ),
          ],
        ),
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
