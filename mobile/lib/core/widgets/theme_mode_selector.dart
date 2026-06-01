import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/theme_mode_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';

/// Profil / ayarlar — Açık, Koyu, Sistem tema seçici.
class ThemeModeSelector extends ConsumerWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.palette_outlined, color: palette.textSecondary, size: 22),
            const SizedBox(width: 10),
            Text(
              'Görünüm',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: palette.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(
              value: ThemeMode.light,
              label: Text('Açık'),
              icon: Icon(Icons.light_mode_rounded, size: 18),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              label: Text('Koyu'),
              icon: Icon(Icons.dark_mode_rounded, size: 18),
            ),
            ButtonSegment(
              value: ThemeMode.system,
              label: Text('Sistem'),
              icon: Icon(Icons.brightness_auto_rounded, size: 18),
            ),
          ],
          selected: {mode},
          onSelectionChanged: (selected) {
            ref.read(themeModeProvider.notifier).setMode(selected.first);
          },
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.white;
              }
              return palette.textSecondary;
            }),
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.accentPink;
              }
              return palette.surfaceElevated;
            }),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _hint(mode),
          style: TextStyle(
            fontSize: 12,
            color: palette.textMuted,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  String _hint(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'Açık tema — gündüz kullanımı için yüksek kontrast.',
        ThemeMode.dark => 'Koyu tema — canlı yayın ve gece kullanımı için optimize.',
        ThemeMode.system => 'Cihazınızın açık/koyu ayarını otomatik takip eder.',
      };
}
