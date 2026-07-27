import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../gifts/presentation/widgets/gift_stage_layout.dart';
import '../../../../live/domain/entities/live_gift_event.dart';

/// Sesli oda / canlı yayın — koltuk altı ↔ mesaj alanı arasında büyük hediye.
class VoiceGiftFlightOverlay extends StatefulWidget {
  const VoiceGiftFlightOverlay({
    super.key,
    required this.events,
    required this.onFinished,
    this.enabled = true,
    this.stageContext = GiftStageContext.voiceRoom,
  });

  final List<LiveGiftEvent> events;
  final void Function(String eventId) onFinished;
  final bool enabled;
  final GiftStageContext stageContext;

  @override
  State<VoiceGiftFlightOverlay> createState() => _VoiceGiftFlightOverlayState();
}

class _VoiceGiftFlightOverlayState extends State<VoiceGiftFlightOverlay>
    with SingleTickerProviderStateMixin {
  final Set<String> _started = {};
  LiveGiftEvent? _current;
  AnimationController? _ctrl;

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _tryStartNext();
  }

  @override
  void didUpdateWidget(covariant VoiceGiftFlightOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _tryStartNext();
  }

  void _tryStartNext() {
    if (_current != null) return;
    for (final e in widget.events) {
      if (_started.add(e.id)) {
        _show(e);
        break;
      }
    }
  }

  void _show(LiveGiftEvent e) {
    _ctrl?.dispose();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );
    setState(() => _current = e);
    _ctrl!.forward().then((_) {
      if (!mounted) return;
      widget.onFinished(e.id);
      setState(() {
        _current = null;
        _ctrl?.dispose();
        _ctrl = null;
      });
      for (final next in widget.events) {
        if (_started.add(next.id)) {
          _show(next);
          break;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || _current == null) return const SizedBox.shrink();

    final event = _current!;
    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GiftStageBand(
            stage: widget.stageContext,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = GiftStageMetrics.giftSizeFor(constraints);
                return GiftStageLargeDisplay(
                  event: event,
                  giftSize: size,
                  preferFastVisual:
                      widget.stageContext == GiftStageContext.voiceRoom,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
