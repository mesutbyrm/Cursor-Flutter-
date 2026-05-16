import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'models.dart';

class AnimatedGradientBackground extends StatelessWidget {
  const AnimatedGradientBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF080713),
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -160,
            right: -120,
            child: _GlowOrb(color: Colors.purpleAccent.withValues(alpha: .34)),
          ),
          Positioned(
            bottom: -180,
            left: -130,
            child: _GlowOrb(color: Colors.cyanAccent.withValues(alpha: .18)),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: .85, end: 1.12),
      duration: const Duration(seconds: 4),
      curve: Curves.easeInOut,
      builder: (BuildContext context, double scale, Widget? child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: 320,
        height: 320,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: <BoxShadow>[
            BoxShadow(color: color, blurRadius: 110, spreadRadius: 50),
          ],
        ),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius borderRadius = BorderRadius.circular(28);
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Material(
            color: Colors.white.withValues(alpha: .07),
            borderRadius: borderRadius,
            child: InkWell(
              borderRadius: borderRadius,
              onTap: onTap,
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .10),
                  ),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ResponsiveMaxWidth extends StatelessWidget {
  const ResponsiveMaxWidth({
    required this.child,
    this.maxWidth = 980,
    super.key,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

class GradientAvatar extends StatelessWidget {
  const GradientAvatar({
    required this.imageUrl,
    this.radius = 28,
    this.isLive = false,
    super.key,
  });

  final String imageUrl;
  final double radius;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(2.5),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: <Color>[
                Color(0xFFFF2D75),
                Color(0xFF7C3AED),
                Color(0xFF22D3EE),
              ],
            ),
          ),
          child: CircleAvatar(
            radius: radius,
            backgroundColor: Colors.black,
            backgroundImage: CachedNetworkImageProvider(imageUrl),
          ),
        ),
        if (isLive)
          Positioned(
            bottom: -2,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: const Color(0xFFFF2D75),
              ),
              child: const Text(
                'LIVE',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
              ),
            ),
          ),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white60),
                  ),
              ],
            ),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class StatPill extends StatelessWidget {
  const StatPill({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: .08),
        border: Border.all(color: Colors.white.withValues(alpha: .1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: const Color(0xFF22D3EE)),
          const SizedBox(width: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white60)),
        ],
      ),
    );
  }
}

class AsyncValueSliver<T> extends StatelessWidget {
  const AsyncValueSliver({
    required this.value,
    required this.builder,
    super.key,
  });

  final AsyncSnapshot<T> value;
  final Widget Function(T data) builder;

  @override
  Widget build(BuildContext context) {
    if (value.connectionState == ConnectionState.waiting) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (value.hasError) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('İçerik yüklenemedi: ${value.error}'),
        ),
      );
    }
    return SliverToBoxAdapter(child: builder(value.data as T));
  }
}

String compactNumber(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  }
  return '$value';
}

String badgeLabel(BadgeKind badge) {
  return switch (badge) {
    BadgeKind.verified => 'Onaylı',
    BadgeKind.topCreator => 'Trend',
    BadgeKind.oracle => 'Falcı',
    BadgeKind.moderator => 'Mod',
    BadgeKind.founder => 'Kurucu',
  };
}

String tierLabel(MembershipTier tier) {
  return switch (tier) {
    MembershipTier.free => 'Free',
    MembershipTier.fan => 'FanClub',
    MembershipTier.premium => 'Premium',
    MembershipTier.vip => 'VIP',
  };
}
