import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/live_stream_fps_mode.dart';
import '../../../domain/entities/live_stream_quality_preset.dart';
import '../../providers/live_stream_quality_provider.dart';

/// Yayın video kalitesi + FPS seçici — prep ve yayın ayarlarında ortak.
class LiveStreamQualityPicker extends ConsumerWidget {
  const LiveStreamQualityPicker({
    super.key,
    this.compact = false,
    this.showTitle = true,
  });

  final bool compact;
  final bool showTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(liveStreamQualityProvider);
    final notifier = ref.read(liveStreamQualityProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTitle)
          Padding(
            padding: EdgeInsets.fromLTRB(compact ? 0 : 16, compact ? 0 : 4, 16, 6),
            child: Row(
              children: [
                const Icon(Icons.hd_rounded, size: 16, color: Color(0xFFB832FF)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Video kalitesi',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: compact ? 12 : 13,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  settings.detailLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.start,
            children: LiveStreamQualityPreset.values.map((q) {
              final selected = settings.preset == q;
              return ChoiceChip(
                label: Text(
                  q.label,
                  style: TextStyle(
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : Colors.white70,
                  ),
                ),
                selected: selected,
                selectedColor: const Color(0xFFB832FF).withValues(alpha: 0.55),
                backgroundColor: Colors.black.withValues(alpha: 0.35),
                side: BorderSide(
                  color: selected
                      ? const Color(0xFFB832FF)
                      : Colors.white.withValues(alpha: 0.2),
                ),
                onSelected: (_) => notifier.setPreset(q),
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(compact ? 0 : 12, 10, compact ? 0 : 12, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kare hızı (FPS)',
                style: TextStyle(
                  fontSize: compact ? 10 : 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: LiveStreamFpsMode.values.map((fps) {
                  final selected = settings.fpsMode == fps;
                  return ChoiceChip(
                    label: Text(
                      fps.label,
                      style: TextStyle(
                        fontSize: compact ? 10 : 11,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : Colors.white70,
                      ),
                    ),
                    selected: selected,
                    selectedColor: const Color(0xFF5B8CFF).withValues(alpha: 0.5),
                    backgroundColor: Colors.black.withValues(alpha: 0.35),
                    side: BorderSide(
                      color: selected
                          ? const Color(0xFF5B8CFF)
                          : Colors.white.withValues(alpha: 0.2),
                    ),
                    onSelected: (_) => notifier.setFpsMode(fps),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
