import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'models.dart';

class AnimatedGradientBackground extends StatelessWidget {
  const AnimatedGradientBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF160021),
            Color(0xFF12001F),
            Color(0xFF101D3E),
          ],
        ),
      ),
      child: Stack(
        children: <Widget>[
          const Positioned.fill(child: _StarField()),
          Positioned(
            top: -110,
            left: -90,
            child: _GlowOrb(
              color: const Color(0xFFFF32D2).withValues(alpha: .28),
            ),
          ),
          Positioned(
            top: 120,
            right: -160,
            child: _GlowOrb(
              color: const Color(0xFF8B5CF6).withValues(alpha: .35),
            ),
          ),
          Positioned(
            bottom: -190,
            left: -140,
            child: _GlowOrb(
              color: const Color(0xFF2D6BFF).withValues(alpha: .22),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _StarField extends StatelessWidget {
  const _StarField();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _StarPainter());
  }
}

class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = Colors.white.withValues(alpha: .46);
    for (int i = 0; i < 84; i++) {
      final double x = ((i * 73) % 1000) / 1000 * size.width;
      final double y = ((i * 149) % 1000) / 1000 * size.height;
      final double radius = i % 5 == 0 ? 1.7 : .9;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
    final BorderRadius borderRadius = BorderRadius.circular(24);
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFFB832FF).withValues(alpha: .18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Material(
            color: const Color(0xFF210032).withValues(alpha: .56),
            borderRadius: borderRadius,
            child: InkWell(
              borderRadius: borderRadius,
              onTap: onTap,
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  border: Border.all(
                    color: const Color(0xFFB832FF).withValues(alpha: .36),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      Colors.white.withValues(alpha: .10),
                      const Color(0xFF6D15A8).withValues(alpha: .12),
                    ],
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
                Color(0xFFFF3EDB),
                Color(0xFFB832FF),
                Color(0xFF1CCBFF),
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
                color: const Color(0xFFFF3EDB),
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
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: CanlifalText.sectionTitle(context)),
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
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  color: Color(0xFFD88BFF),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CanlifalText {
  static TextStyle sectionTitle(BuildContext context) {
    return Theme.of(context).textTheme.titleLarge!.copyWith(
      fontWeight: FontWeight.w900,
      color: Colors.white,
      shadows: <Shadow>[
        Shadow(
          color: const Color(0xFFFF3EDB).withValues(alpha: .24),
          blurRadius: 10,
        ),
      ],
    );
  }
}

class NeonIconTile extends StatelessWidget {
  const NeonIconTile({
    required this.icon,
    required this.label,
    this.gradient,
    this.onTap,
    this.size = 104,
    super.key,
  });

  final String icon;
  final String label;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      child: Column(
        children: <Widget>[
          GlassCard(
            padding: EdgeInsets.zero,
            onTap: onTap,
            child: Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient:
                    gradient ??
                    const LinearGradient(
                      colors: <Color>[Color(0xFF6D15A8), Color(0xFFD91CE8)],
                    ),
              ),
              child: Text(icon, style: const TextStyle(fontSize: 38)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class CircleLogo extends StatelessWidget {
  const CircleLogo({
    required this.imageUrl,
    required this.label,
    this.subtitle,
    this.badge,
    this.size = 68,
    this.onTap,
    super.key,
  });

  final String imageUrl;
  final String label;
  final String? subtitle;
  final IconData? badge;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size + 20,
        child: Column(
          children: <Widget>[
            Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: <Color>[Color(0xFFFF2D95), Color(0xFFB832FF)],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: size / 2,
                    backgroundColor: const Color(0xFF6D15A8),
                    backgroundImage: CachedNetworkImageProvider(imageUrl),
                    onBackgroundImageError:
                        (Object error, StackTrace? stackTrace) {},
                    child: imageUrl.isEmpty
                        ? Text(
                            label.characters.first.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 24,
                            ),
                          )
                        : null,
                  ),
                ),
                if (badge != null)
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: CircleAvatar(
                      radius: 13,
                      backgroundColor: const Color(0xFFFF3EDB),
                      child: Icon(badge, size: 14),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Colors.white54),
              ),
          ],
        ),
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
