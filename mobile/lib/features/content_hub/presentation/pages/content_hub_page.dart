import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/native_site_routes.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/ui/responsive/responsive_layout.dart';
import '../../../shell/presentation/widgets/branch_role_actions.dart';
import '../../domain/content_link.dart';

/// Fal ve topluluk içerikleri — yalnızca native ekranlara yönlendirir (WebView yok).
class ContentHubPage extends ConsumerWidget {
  const ContentHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final teller = BranchRoleActions.tellerAction(ref);
    final agency = BranchRoleActions.agencyAction(ref);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Keşfet & İçerik')),
      body: ListView(
        padding: ResponsiveLayout.pagePadding(context).copyWith(bottom: 32),
        children: [
          Text(
            'Tüm içerikler uygulama içi native ekranlarda ve API üzerinden sunulur.',
            style: TextStyle(
              color: palette.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          for (final section in ContentHubCatalog.sections) ...[
            Text(
              section.$1,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: palette.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            ...section.$2.map(
              (link) {
                final resolved = _resolveLink(link, teller, agency);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(resolved.icon, color: palette.colors.primary),
                    title: Text(
                      resolved.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      resolved.subtitle,
                      style: TextStyle(color: palette.textSecondary),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _openLink(context, resolved),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  ContentLink _resolveLink(
    ContentLink link,
    TellerBranchAction teller,
    AgencyBranchAction agency,
  ) {
    if (link.path == '/falci-ol') {
      return ContentLink(
        title: teller.label.replaceAll('\n', ' '),
        subtitle: teller.route != null ? 'Kontrol paneli' : 'Başvuru',
        path: teller.route ?? teller.nativePath ?? '/canli-falcilar/apply',
        icon: teller.icon,
      );
    }
    if (link.path == '/ajans-ol') {
      return ContentLink(
        title: agency.label.replaceAll('\n', ' '),
        subtitle: agency.route != null ? 'Kontrol paneli' : 'Partner başvurusu',
        path: agency.route ?? agency.nativePath ?? '/ajans-ol',
        icon: agency.icon,
      );
    }
    return link;
  }

  void _openLink(BuildContext context, ContentLink link) {
    final path = link.path;
    if (path == '/canli-falcilar/dashboard' ||
        path == '/falci-panel' ||
        path == '/canli-falcilar/apply' ||
        path == '/falci-ol' ||
        path == '/ajans/dashboard') {
      context.push(path);
      return;
    }
    openNativeSitePath(context, path);
  }
}
