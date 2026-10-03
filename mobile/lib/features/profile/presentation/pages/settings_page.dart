import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../../core/widgets/settings_kit.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import 'settings_category_page.dart';

/// Merkezi ayarlar — her kategori ayrı bir kart; kartlar sürekli görünür.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final c = context.colors;
    final avatar = user?.avatarUrl;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: 'Ayarlar',
          subtitle: 'Hesap, güvenlik ve tercihler',
          body: ListView.separated(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 40),
            itemCount: settingsCategories.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: SettingsHeroCard(
                    title: user?.display ?? 'Hesabım',
                    subtitle: user?.email ?? 'Profilini düzenle',
                    onTap: () => context.push('/profile/edit'),
                    leading: CircleAvatar(
                      radius: 26,
                      backgroundColor: c.primary.withValues(alpha: 0.25),
                      backgroundImage: (avatar?.isNotEmpty ?? false)
                          ? NetworkImage(avatar!)
                          : null,
                      child: (avatar?.isNotEmpty ?? false)
                          ? null
                          : Icon(Icons.person_rounded, color: c.primary),
                    ),
                  ),
                );
              }
              final cat = settingsCategories[i - 1];
              return SettingsCategoryCard(
                icon: cat.icon,
                title: cat.title,
                subtitle: cat.subtitle,
                accent: cat.accent,
                onTap: () => context.push(cat.route),
              );
            },
          ),
        ),
      ),
    );
  }
}
