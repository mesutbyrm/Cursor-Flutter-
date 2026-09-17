import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/cds_fx.dart';
import 'canlifal_motion_tokens.dart';

/// Basınçta hafif scale — 60 FPS, tek controller yok.
class CanlifalPressable extends StatefulWidget {
  const CanlifalPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.scale = CanlifalMotionTokens.pressScale,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enabled;
  final double scale;

  @override
  State<CanlifalPressable> createState() => _CanlifalPressableState();
}

class _CanlifalPressableState extends State<CanlifalPressable> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final target = widget.enabled && _pressed ? widget.scale : 1.0;
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: widget.enabled ? () => setState(() => _pressed = false) : null,
      onTap: widget.enabled ? widget.onTap : null,
      onLongPress: widget.enabled ? widget.onLongPress : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: target,
        duration: CanlifalMotionTokens.micro,
        curve: CanlifalMotionTokens.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Liste/kart girişi — fade + hafif slide.
class CanlifalEntranceFadeSlide extends StatelessWidget {
  const CanlifalEntranceFadeSlide({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.slideY = 0.04,
  });

  final Widget child;
  final Duration delay;
  final double slideY;

  @override
  Widget build(BuildContext context) {
    return child
        .animate(delay: delay)
        .fadeIn(
          duration: CanlifalMotionTokens.normal,
          curve: CanlifalMotionTokens.easeOut,
        )
        .slideY(
          begin: slideY,
          end: 0,
          duration: CanlifalMotionTokens.normal,
          curve: CanlifalMotionTokens.easeOut,
        );
  }
}

/// Alt nav ikon — seçimde scale + opacity.
class CanlifalNavIcon extends StatelessWidget {
  const CanlifalNavIcon({
    super.key,
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.inactiveColor,
  });

  final IconData icon;
  final bool active;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: active ? CanlifalMotionTokens.navActiveScale : 1.0,
      duration: CanlifalMotionTokens.micro,
      curve: CanlifalMotionTokens.spring,
      child: AnimatedOpacity(
        opacity: active ? 1 : 0.72,
        duration: CanlifalMotionTokens.micro,
        child: Icon(
          icon,
          size: 24,
          color: active ? activeColor : inactiveColor,
        ),
      ),
    );
  }
}

/// Gold profil halkası — tek döngü pulse, sonra durur (FX kapalıysa yok).
class CanlifalGoldRingPulse extends ConsumerStatefulWidget {
  const CanlifalGoldRingPulse({
    super.key,
    required this.child,
    required this.gradient,
    this.size = 72,
    this.padding = 3.5,
    this.enabled = true,
  });

  final Widget child;
  final Gradient gradient;
  final double size;
  final double padding;
  final bool enabled;

  @override
  ConsumerState<CanlifalGoldRingPulse> createState() =>
      _CanlifalGoldRingPulseState();
}

class _CanlifalGoldRingPulseState extends ConsumerState<CanlifalGoldRingPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: CanlifalMotionTokens.premium,
    );
    _glow = CurvedAnimation(parent: _c, curve: CanlifalMotionTokens.easeOut);
  }

  var _played = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_played) return;
    _played = true;
    final fx = ref.read(cdsFxProvider);
    if (!widget.enabled || fx.decorativeDisabled) return;
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fx = ref.watch(cdsFxProvider);
    final showPulse = widget.enabled && !fx.decorativeDisabled;

    return AnimatedBuilder(
      animation: _glow,
      builder: (context, _) {
        final t = showPulse ? _glow.value : 0.0;
        final blur = 8.0 + t * 10;
        final spread = t * 1.5;
        return Container(
          width: widget.size,
          height: widget.size,
          padding: EdgeInsets.all(widget.padding),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: widget.gradient,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD54F).withValues(alpha: 0.25 + t * 0.2),
                blurRadius: blur,
                spreadRadius: spread,
              ),
            ],
          ),
          child: ClipOval(child: widget.child),
        );
      },
    );
  }
}
