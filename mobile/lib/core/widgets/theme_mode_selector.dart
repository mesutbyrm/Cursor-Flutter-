import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/theme_mode_provider.dart';
import '../providers/amoled_dark_provider.dart';
import '../theme/app_spacing.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/features/profile/presentation/widgets/premium/profile_glass.dart';

enum _DarkThemeChoice { standard, amoled }

/// Ayarlar — yalnızca Koyu ve AMOLED Koyu tema seçimi.
class ThemeModeSelector extends ConsumerWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amoled = ref.watch(amoledDarkProvider);
    final selected = amoled ? _DarkThemeChoice.amoled : _DarkThemeChoice.standard;
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
          SegmentedButton<_DarkThemeChoice>(
            segments: const [
              ButtonSegment(
                value: _DarkThemeChoice.standard,
                label: Text('Koyu'),
                icon: Icon(Icons.dark_mode_rounded, size: 18),
              ),
              ButtonSegment(
                value: _DarkThemeChoice.amoled,
                label: Text('AMOLED Koyu'),
                icon: Icon(Icons.contrast_rounded, size: 18),
              ),
            ],
            selected: {selected},
            onSelectionChanged: (choice) {
              final pick = choice.first;
              ref.read(themeModeProvider.notifier).setMode(ThemeMode.dark);
              ref
                  .read(amoledDarkProvider.notifier)
                  .setEnabled(pick == _DarkThemeChoice.amoled);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            selected == _DarkThemeChoice.amoled
                ? 'Saf siyah arka plan — OLED ekranlarda daha az pil tüketimi.'
                : 'Cam efektli koyu tema — gece ve yayın için optimize.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: c.onSurfaceMuted,
                  height: 1.35,
                ),
          ),
        ],
      ),
    );
  }
}
