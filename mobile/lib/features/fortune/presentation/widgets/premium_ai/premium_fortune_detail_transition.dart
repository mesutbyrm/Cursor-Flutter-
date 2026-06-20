import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

import '../../../domain/entities/fortune_type_entity.dart';
import '../../data/fortune_type_images.dart';
import 'premium_fortune_cover.dart';

/// Falını Aç — hero büyüme, blur arka plan, Lottie geçişi.
Future<void> runPremiumFortuneOpenTransition({
  required BuildContext context,
  required FortuneTypeEntity type,
  required Future<void> Function() onOpen,
}) async {
  HapticFeedback.mediumImpact();
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  var dismissed = false;

  entry = OverlayEntry(
    builder: (ctx) => _OpenTransitionOverlay(
      type: type,
      onDone: () async {
        if (dismissed) return;
        dismissed = true;
        entry.remove();
        await onOpen();
      },
    ),
  );

  overlay.insert(entry);
}

class _OpenTransitionOverlay extends StatefulWidget {
  const _OpenTransitionOverlay({
    required this.type,
    required this.onDone,
  });

  final FortuneTypeEntity type;
  final VoidCallback onDone;

  @override
  State<_OpenTransitionOverlay> createState() => _OpenTransitionOverlayState();
}

class _OpenTransitionOverlayState extends State<_OpenTransitionOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward().then((_) {
        if (mounted) widget.onDone();
      });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final heroTag = FortuneTypeImages.heroTagFor(widget.type.slug);

    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final t = Curves.easeOutCubic.transform(_ctrl.value);
          final blur = 8.0 * t;
          final scale = 1.0 + 0.12 * t;

          return Stack(
            fit: StackFit.expand,
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: Container(color: Colors.black.withValues(alpha: 0.45 * t)),
              ),
              Center(
                child: Transform.scale(
                  scale: scale,
                  child: SizedBox(
                    width: size.width * 0.88,
                    child: Hero(
                      tag: heroTag,
                      child: Material(
                        type: MaterialType.transparency,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            PremiumFortuneCover(
                              type: widget.type,
                              height: size.height * 0.42,
                              heroTag: heroTag,
                            ),
                            if (t > 0.3)
                              SizedBox(
                                width: 72,
                                height: 72,
                                child: Lottie.asset(
                                  'assets/gifts/lottie/star.json',
                                  repeat: true,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
