import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/theme_mode_provider.dart';
import '../providers/amoled_dark_provider.dart';
import '../storage/theme_preferences.dart';
import '../theme/app_spacing.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/features/profile/presentation/widgets/premium/profile_glass.dart';

/// Ayarlar — Açık / Koyu / Sistem tema seçimi (anında uygulanır).
class ThemeModeSelector extends ConsumerWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final amoled = ref.watch(amoledDarkProvider);
    final c = context.colors;

    return ProfileGlass(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined, color: c.secondary, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Tema',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: c.onSurface,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                value: ThemeMode.light,
                label: Text(ThemePreferences.label(ThemeMode.light)),
                icon: const Icon(Icons.light_mode_rounded, size: 18),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text(ThemePreferences.label(ThemeMode.dark)),
                icon: const Icon(Icons.dark_mode_rounded, size: 18),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                label: Text(
                  ThemePreferences.label(ThemeMode.system),
                  style: const TextStyle(fontSize: 11),
                ),
                icon: const Icon(Icons.brightness_auto_rounded, size: 18),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (selected) {
              ref.read(themeModeProvider.notifier).setMode(selected.first);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _hint(mode),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: c.onSurfaceMuted,
                  height: 1.35,
                ),
          ),
          if (mode != ThemeMode.light) ...[
            const SizedBox(height: AppSpacing.md),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'AMOLED Koyu',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: c.onSurface,
                    ),
              ),
              subtitle: Text(
                'Saf siyah arka plan — OLED ekranlarda daha az pil tüketimi',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: c.onSurfaceMuted,
                      height: 1.35,
                    ),
              ),
              value: amoled,
              onChanged: (v) =>
                  ref.read(amoledDarkProvider.notifier).setEnabled(v),
            ),
          ],
        ],
      ),
    );
  }

  String _hint(ThemeMode mode) => switch (mode) {
        ThemeMode.light =>
          'Açık tema: modern, ferah arayüz. Gündüz kullanımı için idealdir.',
        ThemeMode.dark =>
          'Koyu tema: cam efektli premium görünüm. Gece ve yayın için optimize.',
        ThemeMode.system =>
          'Telefonunuzun açık veya koyu ayarını otomatik takip eder.',
      };
}
