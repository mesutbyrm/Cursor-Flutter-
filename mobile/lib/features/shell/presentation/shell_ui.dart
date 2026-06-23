import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme_extensions.dart';
import '../../home/presentation/theme/home_approved_design.dart';

/// Shell alt navigasyon ve oluşturma sayfası — tema uyumlu yardımcılar.
abstract final class ShellUi {
  /// Onaylı mockup koyu paleti; açık temada Material scaffold rengi.
  static Color shellBackground(BuildContext context) {
    return context.isDarkTheme
        ? HomeApprovedDesign.background
        : context.colors.scaffoldBackground;
  }

  static Color bottomNavBackground(BuildContext context) {
    return context.isDarkTheme
        ? HomeApprovedDesign.background
        : context.colors.surface;
  }

  static Color bottomSheetBackground(BuildContext context) =>
      context.colors.bottomSheetBackground;

  static void showCreateSheet(BuildContext context, GoRouter router) {
    final colors = context.colors;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.bottomSheetBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.onSurfaceMuted.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'İçerik oluştur',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.videocam_rounded, color: Colors.redAccent),
                title: Text('Canlı yayın aç', style: TextStyle(color: colors.onSurface)),
                subtitle: Text(
                  'Kamera veya ekran yayını başlat',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  router.push('/live/type');
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library_rounded, color: Colors.purpleAccent),
                title: Text('Video yükle', style: TextStyle(color: colors.onSurface)),
                subtitle: Text(
                  'Kısa video veya gönderi paylaş',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  router.push('/shorts/upload');
                },
              ),
              ListTile(
                leading: Icon(Icons.auto_awesome_rounded, color: colors.primary),
                title: Text('Fal & Tarot', style: TextStyle(color: colors.onSurface)),
                subtitle: Text(
                  'Fal merkezine git',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  router.go('/fortune');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
