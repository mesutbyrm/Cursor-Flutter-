import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../domain/admin_site_animation.dart';
import '../providers/admin_site_animation_providers.dart';
import '../providers/staff_access_provider.dart';
import '../widgets/admin_site_animation_card.dart';

class AdminSiteAnimationsLibraryPage extends ConsumerWidget {
  const AdminSiteAnimationsLibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(staffAccessProvider);
    if (!access.canManageSiteAnimations) return _locked(context);

    final listAsync = ref.watch(adminSiteAnimationListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0E0524),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12082A),
        title: const Text('Animasyon Kütüphanesi'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppThemeColors.accentPurple,
        onPressed: () => context.push('/admin/site-animations/new'),
        icon: const Icon(Icons.add),
        label: const Text('Ekle'),
      ),
      body: listAsync.when(
        loading: () => const Center(child: DiscoverAccentLoader()),
        error: (e, _) => Center(child: Text(ApiException.userMessage(e))),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Henüz animasyon yok.'));
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(adminSiteAnimationListProvider.notifier).refresh(),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.72,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final anim = items[i];
                return AdminSiteAnimationCard(
                  animation: anim,
                  onPreview: () => context.push(
                    '/admin/site-animations/preview',
                    extra: anim,
                  ),
                  onEdit: () => context.push(
                    '/admin/site-animations/${anim.id}/edit',
                    extra: anim,
                  ),
                  onAssign: () => context.push(
                    '/admin/site-animations/user-assign',
                    extra: anim,
                  ),
                  onToggleActive: () async {
                    await ref
                        .read(adminSiteAnimationListProvider.notifier)
                        .toggleActive(anim.id, !anim.isActive);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            anim.isActive
                                ? 'Pasifleştirildi — Flutter\'a gönderilmez'
                                : 'Aktifleştirildi',
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _locked(BuildContext context) {
    return Scaffold(
      body: DiscoverBackground(
        child: Center(
          child: DiscoverEmptyState(
            icon: Icons.lock_outline_rounded,
            message: 'Yetkisiz erişim',
            actionLabel: 'Geri',
            action: () => Navigator.of(context).maybePop(),
          ),
        ),
      ),
    );
  }
}
