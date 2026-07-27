import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../trtc/presentation/trtc_room_manager.dart';
import '../../../domain/entities/live_beauty_settings.dart';
import '../../providers/live_beauty_provider.dart';

Future<void> showLiveBeautyFilterSheet({
  required BuildContext context,
  required WidgetRef ref,
}) {
  final maxHeight = MediaQuery.sizeOf(context).height * 0.55;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    constraints: BoxConstraints(maxHeight: maxHeight),
    barrierColor: Colors.transparent,
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CameraPreviewCard(notifier: notifier, settings: settings),
                const Text(
                  'Güzelleştirme',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                SwitchListTile(
                  title:
                      const Text('Aktif', style: TextStyle(color: Colors.white)),
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
                  children:
                      List.generate(LiveBeautySettings.filterNames.length, (i) {
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

class _CameraPreviewCard extends StatelessWidget {
  const _CameraPreviewCard({
    required this.notifier,
    required this.settings,
  });

  final LiveBeautyNotifier notifier;
  final LiveBeautySettings settings;

  @override
  Widget build(BuildContext context) {
    final trtc = notifier.boundTrtc;
    final hasPreview = trtc != null && trtc.cameraOn;

    return Container(
      height: 120,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          hasPreview
              ? TrtcLocalVideoView(manager: trtc)
              : const Text(
                  '📷 Önizleme',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
          if (hasPreview && !settings.enabled)
            Container(
              color: Colors.black.withValues(alpha: 0.35),
              alignment: Alignment.center,
              child: const Text(
                'Filtre kapalı',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }
}
