import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/gift_display_settings.dart';
import 'global_gift_overlay_notifier.dart';

/// Site geneli hediye — en üstte bir kez sağdan sola geçer.
class GlobalGiftOverlay extends ConsumerWidget {
  const GlobalGiftOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overlay = ref.watch(globalGiftOverlayProvider);
    final active = overlay.active;
    final settings = overlay.settings;

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (active != null && settings.enabled)
          _GiftPassBar(
            key: ValueKey(active.eventId),
            label: active.label(settings),
            settings: settings,
          ),
      ],
    );
  }
}

class _GiftPassBar extends StatefulWidget {
  const _GiftPassBar({
    super.key,
    required this.label,
    required this.settings,
  });

  final String label;
  final GiftDisplaySettings settings;

  @override
  State<_GiftPassBar> createState() => _GiftPassBarState();
}

class _GiftPassBarState extends State<_GiftPassBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  double _textWidth = 160;

  static const _style = TextStyle(
    color: Colors.white,
    fontSize: 13,
    fontWeight: FontWeight.w800,
    height: 1.15,
    letterSpacing: 0.15,
  );

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.settings.displayDuration,
    )..forward();
    _measureText();
  }

  void _measureText() {
    final painter = TextPainter(
      text: TextSpan(text: widget.label, style: _style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    _textWidth = painter.width;
    painter.dispose();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + 6;
    final width = MediaQuery.sizeOf(context).width;

    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.only(top: top, left: 10, right: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: width,
              height: 36,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
                ),
              ),
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (context, child) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final viewport = constraints.maxWidth;
                      final start = viewport;
                      final end = -_textWidth - 24;
                      final dx = start + (end - start) * _ctrl.value;
                      return Stack(
                        children: [
                          Positioned(
                            left: dx,
                            top: 0,
                            bottom: 0,
                            child: child!,
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    softWrap: false,
                    style: _style,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
