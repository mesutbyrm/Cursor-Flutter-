import 'package:flutter/material.dart';

import '../../../../core/navigation/native_site_routes.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/ui/responsive/responsive_layout.dart';
import '../../domain/content_link.dart';

/// Blog, rüya ve fal içerikleri — yalnızca native ekranlara yönlendirir (WebView yok).
class ContentHubPage extends StatelessWidget {
  const ContentHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

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
              (link) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(link.icon, color: palette.colors.primary),
                  title: Text(
                    link.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    link.subtitle,
                    style: TextStyle(color: palette.textMuted),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: palette.textMuted,
                  ),
                  onTap: () => openNativeSitePath(context, link.path),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
