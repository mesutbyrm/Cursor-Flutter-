import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/live_beauty_settings.dart';
import '../../providers/live_beauty_provider.dart';

Future<void> showLiveBeautyFilterSheet({
  required BuildContext context,
  required WidgetRef ref,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _BeautySheet(),
  );
}

class _BeautySheet extends ConsumerWidget {
  const _BeautySheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(liveBeautyProvider);
    final notifier = ref.read(liveBeautyProvider.notifier);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            MediaQuery.paddingOf(context).bottom + 16,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF151522).withValues(alpha: 0.94),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Güzelleştirme',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
              SwitchListTile(
                title: const Text('Aktif', style: TextStyle(color: Colors.white)),
                value: settings.enabled,
                onChanged: (v) => notifier.update(settings.copyWith(enabled: v)),
              ),
              _slider(
                'Skin Smooth',
                settings.smoothness,
                (v) => notifier.update(settings.copyWith(smoothness: v)),
              ),
              _slider(
                'Whitening',
                settings.whitening,
                (v) => notifier.update(settings.copyWith(whitening: v)),
              ),
              _slider(
                'Sharpen',
                settings.sharpness,
                (v) => notifier.update(settings.copyWith(sharpness: v)),
              ),
              _slider(
                'Brightness',
                settings.brightness,
                (v) => notifier.update(settings.copyWith(brightness: v)),
              ),
              _slider(
                'Contrast',
                settings.contrast,
                (v) => notifier.update(settings.copyWith(contrast: v)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: List.generate(LiveBeautySettings.filterNames.length, (i) {
                  final selected = settings.filterIndex == i;
                  return ChoiceChip(
                    label: Text(LiveBeautySettings.filterNames[i]),
                    selected: selected,
                    onSelected: (_) =>
                        notifier.update(settings.copyWith(filterIndex: i)),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _slider(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        Slider(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFFB832FF),
        ),
      ],
    );
  }
}
