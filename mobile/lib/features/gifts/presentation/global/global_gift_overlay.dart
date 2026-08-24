import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/gift_display_settings.dart';
import 'global_gift_overlay_notifier.dart';

/// Küçük, zarif global hediye bildirimi — tüm sayfalarda ortak.
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
          _GiftToast(
            key: ValueKey(active.eventId),
            label: active.label(settings),
            settings: settings,
          ),
      ],
    );
  }
}

class _GiftToast extends StatefulWidget {
  const _GiftToast({
    super.key,
    required this.label,
    required this.settings,
  });

  final String label;
  final GiftDisplaySettings settings;

  @override
  State<_GiftToast> createState() => _GiftToastState();
}

class _GiftToastState extends State<_GiftToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Alignment _alignment(GiftOverlayPosition pos) {
    return switch (pos) {
      GiftOverlayPosition.top => Alignment.topCenter,
      GiftOverlayPosition.topLeft => Alignment.topLeft,
      GiftOverlayPosition.topRight => Alignment.topRight,
      GiftOverlayPosition.topCenter => Alignment.topCenter,
    };
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + 8;
    final settings = widget.settings;
    final align = _alignment(settings.position);
    final margin = EdgeInsets.only(
      top: top,
      left: settings.position == GiftOverlayPosition.topRight ? 12 : settings.size.horizontalMargin,
      right: settings.position == GiftOverlayPosition.topLeft ? 12 : settings.size.horizontalMargin,
    );

    return IgnorePointer(
      child: Align(
        alignment: align,
        child: SlideTransition(
          position: _slide,
          child: FadeTransition(
            opacity: _fade,
            child: Padding(
              padding: margin,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.88,
                    minHeight: settings.size.height,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: settings.backgroundOpacity),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🎁', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
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
