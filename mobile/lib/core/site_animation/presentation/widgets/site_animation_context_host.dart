import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../site_animation_provider.dart';
import 'site_animation_overlay_host.dart';

/// Site animasyon bağlamı — sesli oda dışı ekranlar.
enum SiteAnimationContext {
  social('ctx_social'),
  liveStream('ctx_live'),
  profile('ctx_profile'),
  gift('ctx_gift'),
  game('ctx_game');

  const SiteAnimationContext(this.overlayId);

  final String overlayId;
}

/// Sosyal / canlı / profil / hediye overlay host.
class SiteAnimationContextHost extends ConsumerWidget {
  const SiteAnimationContextHost({
    super.key,
    required this.context,
    required this.child,
  });

  final SiteAnimationContext context;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SiteAnimationOverlayHost(
      roomId: this.context.overlayId,
      child: child,
    );
  }
}

/// Profil açılışında kısa giriş efekti (native fade + scale).
class SiteAnimationProfileReveal extends StatefulWidget {
  const SiteAnimationProfileReveal({super.key, required this.child});

  final Widget child;

  @override
  State<SiteAnimationProfileReveal> createState() =>
      _SiteAnimationProfileRevealState();
}

class _SiteAnimationProfileRevealState extends State<SiteAnimationProfileReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.98, end: 1).animate(
          CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
        ),
        child: widget.child,
      ),
    );
  }
}
