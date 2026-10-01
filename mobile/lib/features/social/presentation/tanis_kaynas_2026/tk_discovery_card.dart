import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/images/canlifal_network_image.dart';
import '../../domain/entities/social_discovery_user.dart';
import 'tk_common.dart';
import 'tk_palette.dart';

enum TkSwipeAction { pass, like, meet }

/// Ana keşif kartı + kaydırma hareketleri (sağ: beğen, sol: geç, yukarı: tanış).
class TkDiscoveryCard extends StatefulWidget {
  const TkDiscoveryCard({
    super.key,
    required this.user,
    required this.onAction,
    required this.onOpenProfile,
    this.busy = false,
  });

  final SocialDiscoveryUser user;
  final ValueChanged<TkSwipeAction> onAction;
  final VoidCallback onOpenProfile;
  final bool busy;

  @override
  State<TkDiscoveryCard> createState() => _TkDiscoveryCardState();
}

class _TkDiscoveryCardState extends State<TkDiscoveryCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _settle;
  Offset _drag = Offset.zero;
  Offset _from = Offset.zero;
  var _hapticFired = false;

  static const _threshold = 110.0;

  @override
  void initState() {
    super.initState();
    _settle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
        setState(() {
          _drag = Offset.lerp(_from, Offset.zero,
              Curves.easeOutBack.transform(_settle.value))!;
        });
      });
  }

  @override
  void didUpdateWidget(TkDiscoveryCard old) {
    super.didUpdateWidget(old);
    if (old.user.id != widget.user.id) {
      _drag = Offset.zero;
      _hapticFired = false;
    }
  }

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  TkSwipeAction? get _pending {
    if (_drag.dy < -_threshold && _drag.dy.abs() > _drag.dx.abs()) {
      return TkSwipeAction.meet;
    }
    if (_drag.dx > _threshold) return TkSwipeAction.like;
    if (_drag.dx < -_threshold) return TkSwipeAction.pass;
    return null;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (widget.busy) return;
    setState(() => _drag += d.delta);
    final p = _pending;
    if (p != null && !_hapticFired) {
      HapticFeedback.selectionClick();
      _hapticFired = true;
    } else if (p == null) {
      _hapticFired = false;
    }
  }

  void _onPanEnd(DragEndDetails _) {
    final action = _pending;
    if (action != null && !widget.busy) {
      HapticFeedback.mediumImpact();
      widget.onAction(action);
      // Başarılıysa kart sonraki kişiyle değişir; istek başarısız olursa
      // kart ekran dışında kalmasın diye yerine döner.
      setState(() {
        _drag = Offset.zero;
        _hapticFired = false;
      });
      return;
    }
    _from = _drag;
    _settle.forward(from: 0);
    _hapticFired = false;
  }

  @override
  Widget build(BuildContext context) {
    final angle = (_drag.dx / 400).clamp(-1.0, 1.0) * (math.pi / 18);
    final pending = _pending;
    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform.translate(
        offset: _drag,
        child: Transform.rotate(
          angle: angle,
          child: Stack(
            children: [
              RepaintBoundary(
                child: _CardBody(
                  user: widget.user,
                  busy: widget.busy,
                  onAction: widget.onAction,
                  onOpenProfile: widget.onOpenProfile,
                ),
              ),
              if (pending != null)
                Positioned.fill(
                  child: IgnorePointer(child: _SwipeStamp(action: pending)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwipeStamp extends StatelessWidget {
  const _SwipeStamp({required this.action});

  final TkSwipeAction action;

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = switch (action) {
      TkSwipeAction.like => ('BEĞEN', Icons.favorite_rounded, TkPalette.pink),
      TkSwipeAction.pass => ('GEÇ', Icons.close_rounded, Colors.white70),
      TkSwipeAction.meet => ('TANIŞ', Icons.waving_hand_rounded, TkPalette.cyan),
    };
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.black.withValues(alpha: 0.28),
        border: Border.all(color: color, width: 3),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 38),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({
    required this.user,
    required this.busy,
    required this.onAction,
    required this.onOpenProfile,
  });

  final SocialDiscoveryUser user;
  final bool busy;
  final ValueChanged<TkSwipeAction> onAction;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final p = TkPalette.of(context);
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 560;
        final photo = _Photo(
          user: user,
          onTap: onOpenProfile,
          showName: !wide,
          height: wide ? 380 : (c.maxWidth * 1.05).clamp(300.0, 440.0),
          width: wide ? c.maxWidth * 0.44 : c.maxWidth,
        );
        final info = _Info(user: user, showNameBlock: wide);
        final actions = _Actions(busy: busy, onAction: onAction);
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: p.glassStrong,
            border: Border.all(
              color: TkPalette.purple.withValues(alpha: 0.45),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: TkPalette.purple.withValues(alpha: p.isDark ? 0.28 : 0.14),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    photo,
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [info, const SizedBox(height: 16), actions],
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    photo,
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [info, const SizedBox(height: 14), actions],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({
    required this.user,
    required this.onTap,
    required this.height,
    required this.width,
    required this.showName,
  });

  final bool showName;
  final SocialDiscoveryUser user;
  final VoidCallback onTap;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    final url = user.avatarUrl;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url != null && url.trim().isNotEmpty)
              CanlifalNetworkImage(
                url: url,
                width: width,
                height: height,
                fit: BoxFit.cover,
                thumbnailWidth: 720,
                errorWidget: const _PhotoFallback(),
              )
            else
              const _PhotoFallback(),
            // Alt kısım yazılar için koyulaşır.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC0B0A1E)],
                  stops: [0.55, 1],
                ),
              ),
            ),
            if (user.isOnline)
              const Positioned(left: 12, top: 12, child: _OnlinePill()),
            if (user.matchPercent != null && user.matchPercent! > 0)
              Positioned(
                right: 12,
                top: 12,
                child: _MatchBadge(percent: user.matchPercent!),
              ),
            if (showName)
              Positioned(
                left: 14,
                right: 14,
                bottom: 12,
                child: _NameBlock(user: user, onImage: true),
              ),
          ],
        ),
      ),
    );
  }
}

class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3B1E6E), Color(0xFF1A1440)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(Icons.person_rounded, size: 96, color: Colors.white24),
      ),
    );
  }
}

class _OnlinePill extends StatelessWidget {
  const _OnlinePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 4, backgroundColor: TkPalette.online),
          SizedBox(width: 6),
          Text(
            'Çevrimiçi',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sunucunun ortak ilgi alanlarından hesapladığı `matchPercent`.
class _MatchBadge extends StatelessWidget {
  const _MatchBadge({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TkPalette.pink.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite_rounded, color: TkPalette.pink, size: 18),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '%$percent',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  height: 1,
                ),
              ),
              const Text(
                'Uyum',
                style: TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NameBlock extends StatelessWidget {
  const _NameBlock({required this.user, this.onImage = false});

  final SocialDiscoveryUser user;
  final bool onImage;

  @override
  Widget build(BuildContext context) {
    final p = TkPalette.of(context);
    final main = onImage ? Colors.white : p.text;
    final sub = onImage ? Colors.white70 : p.textMuted;
    final place = [
      if (user.city != null && user.city!.trim().isNotEmpty) user.city!.trim(),
      if (user.distanceLabel != null && user.distanceLabel!.trim().isNotEmpty)
        user.distanceLabel!.trim(),
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                user.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: main,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (user.isVerified) ...[
              const SizedBox(width: 6),
              const Icon(Icons.verified_rounded, color: TkPalette.blue, size: 22),
            ],
            if (user.age != null) ...[
              const SizedBox(width: 8),
              Text(
                '${user.age}',
                style: TextStyle(
                  color: sub,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        if (place.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    color: TkPalette.pink, size: 16),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    place,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: sub, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.user, required this.showNameBlock});

  final SocialDiscoveryUser user;
  final bool showNameBlock;

  static const _hobbyIcons = <String, IconData>{
    'müzik': Icons.music_note_rounded,
    'film': Icons.movie_rounded,
    'kahve': Icons.coffee_rounded,
    'gezi': Icons.flight_rounded,
    'seyahat': Icons.flight_rounded,
    'kitap': Icons.menu_book_rounded,
    'oyun': Icons.sports_esports_rounded,
    'futbol': Icons.sports_soccer_rounded,
    'spor': Icons.fitness_center_rounded,
    'dans': Icons.nightlife_rounded,
    'fotoğraf': Icons.photo_camera_rounded,
  };

  static const _hobbyColors = <Color>[
    TkPalette.pink,
    TkPalette.purple,
    TkPalette.amber,
    TkPalette.online,
    TkPalette.blue,
  ];

  @override
  Widget build(BuildContext context) {
    final p = TkPalette.of(context);
    final bio = user.bio?.trim() ?? '';
    final hobbies = user.hobbies;
    const maxChips = 5;
    final common = user.commonHobbies.map((e) => e.toLowerCase()).toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showNameBlock) ...[
          _NameBlock(user: user),
          const SizedBox(height: 10),
        ],
        if (bio.isNotEmpty)
          Text(
            '“$bio”',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: p.textMuted, fontSize: 14.5, height: 1.35),
          ),
        if (hobbies.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < hobbies.length && i < maxChips; i++)
                _HobbyChip(
                  label: hobbies[i],
                  icon: _hobbyIcons[hobbies[i].toLowerCase()] ??
                      Icons.tag_rounded,
                  color: _hobbyColors[i % _hobbyColors.length],
                  common: common.contains(hobbies[i].toLowerCase()),
                ),
              if (hobbies.length > maxChips)
                _HobbyChip(
                  label: '+${hobbies.length - maxChips}',
                  color: p.textMuted,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _HobbyChip extends StatelessWidget {
  const _HobbyChip({
    required this.label,
    required this.color,
    this.icon,
    this.common = false,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool common;

  @override
  Widget build(BuildContext context) {
    final p = TkPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: common ? 0.22 : 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: p.text,
              fontSize: 13,
              fontWeight: common ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.busy, required this.onAction});

  final bool busy;
  final ValueChanged<TkSwipeAction> onAction;

  @override
  Widget build(BuildContext context) {
    final p = TkPalette.of(context);
    VoidCallback? tap(TkSwipeAction a) => busy ? null : () => onAction(a);
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: TkPressable(
            onTap: tap(TkSwipeAction.pass),
            semanticLabel: 'Geç',
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: p.glass,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: p.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.close_rounded, color: p.textMuted, size: 22),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Geç',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: p.textMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 5,
          child: TkGradientButton(
            label: 'Tanış',
            icon: Icons.waving_hand_rounded,
            gradient: TkPalette.ctaGradient,
            height: 52,
            onTap: tap(TkSwipeAction.meet),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 5,
          child: TkGradientButton(
            label: 'Beğen',
            icon: Icons.favorite_rounded,
            height: 52,
            onTap: tap(TkSwipeAction.like),
          ),
        ),
      ],
    );
  }
}

/// Keşif kartı iskeleti.
class TkDiscoveryCardSkeleton extends StatelessWidget {
  const TkDiscoveryCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return TkShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TkSkeletonBox(height: 320, radius: 28),
          const SizedBox(height: 14),
          const TkSkeletonBox(width: 180, height: 18),
          const SizedBox(height: 10),
          const TkSkeletonBox(height: 12),
          const SizedBox(height: 6),
          const TkSkeletonBox(width: 220, height: 12),
          const SizedBox(height: 14),
          Row(
            children: List.generate(
              3,
              (_) => const Padding(
                padding: EdgeInsets.only(right: 8),
                child: TkSkeletonBox(width: 72, height: 30, radius: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
