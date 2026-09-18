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
/// Değer değişince kısa scale bump (istatistik satırı).
class CanlifalValueBump extends StatefulWidget {
  const CanlifalValueBump({
    super.key,
    required this.token,
    required this.child,
  });

  final Object token;
  final Widget child;

  @override
  State<CanlifalValueBump> createState() => _CanlifalValueBumpState();
}

class _CanlifalValueBumpState extends State<CanlifalValueBump>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale;
  Object? _lastToken;

  @override
  void initState() {
    super.initState();
    _lastToken = widget.token;
    _c = AnimationController(
      vsync: this,
      duration: CanlifalMotionTokens.micro,
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.12), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _c, curve: CanlifalMotionTokens.spring));
  }

  @override
  void didUpdateWidget(covariant CanlifalValueBump oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.token != _lastToken) {
      _lastToken = widget.token;
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}

/// Beğeni / burst — `burstToken` artınca kalp scale.
class CanlifalBurstIcon extends StatefulWidget {
  const CanlifalBurstIcon({
    super.key,
    required this.burstToken,
    required this.icon,
    required this.color,
    this.size = 24,
    this.onTap,
  });

  final int burstToken;
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback? onTap;

  @override
  State<CanlifalBurstIcon> createState() => _CanlifalBurstIconState();
}

class _CanlifalBurstIconState extends State<CanlifalBurstIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale;
  var _lastBurst = 0;

  @override
  void initState() {
    super.initState();
    _lastBurst = widget.burstToken;
    _c = AnimationController(
      vsync: this,
      duration: CanlifalMotionTokens.microMax,
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 55),
    ]).animate(CurvedAnimation(parent: _c, curve: CanlifalMotionTokens.spring));
  }

  @override
  void didUpdateWidget(covariant CanlifalBurstIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.burstToken > _lastBurst) {
      _lastBurst = widget.burstToken;
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CanlifalPressable(
      onTap: widget.onTap,
      scale: CanlifalMotionTokens.pressScale,
      child: ScaleTransition(
        scale: _scale,
        child: Icon(widget.icon, size: widget.size, color: widget.color),
      ),
    );
  }
}

/// Kategori / filtre chip — basınç + seçim scale.
class CanlifalFilterChip extends StatelessWidget {
  const CanlifalFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CanlifalPressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: CanlifalMotionTokens.micro,
        curve: CanlifalMotionTokens.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: selected
              ? cs.primary.withValues(alpha: 0.22)
              : cs.surfaceContainerHighest.withValues(alpha: 0.65),
          border: Border.all(
            color: selected
                ? cs.primary.withValues(alpha: 0.55)
                : cs.outlineVariant.withValues(alpha: 0.5),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.25),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: selected ? cs.primary : cs.onSurfaceVariant),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? cs.onSurface : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
