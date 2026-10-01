import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/images/canlifal_network_image.dart';
import '../../../../inbox/presentation/inbox_routes.dart';
import '../../../../inbox/presentation/providers/inbox_unread_providers.dart';
import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../../vip_gold/presentation/utils/open_voice_room_vip.dart';
import '../../providers/voice_rooms_discover_providers.dart';
import '../../utils/open_voice_chat_room_flow.dart';
import '../../utils/voice_room_category_catalog.dart';
import 'voice_rooms_fx.dart';
import 'voice_rooms_mock_data.dart';
import 'voice_rooms_skeleton.dart';
import 'voice_rooms_ui_tokens.dart';

/// Sesli Odalar 2026 — referans tasarım bileşenleri (yalnızca görsel katman;
/// oda/katılım/presence/TRTC çağrıları mevcut akışlardan gelir).

/// 12800 → "12.8K".
String voiceRoomsCount(int n) {
  if (n >= 10000) return '${(n / 1000).round()}K';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}

VoiceRoomEntity? voiceRoomById(List<VoiceRoomEntity> rooms, String id) {
  for (final r in rooms) {
    if (r.id == id) return r;
  }
  return null;
}

/// Basınca hafif küçülen dokunma yüzeyi (+ seçim titreşimi).
class VrPressable extends StatefulWidget {
  const VrPressable({
    super.key,
    required this.child,
    required this.onTap,
    this.semanticLabel,
    this.haptic = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool haptic;

  @override
  State<VrPressable> createState() => _VrPressableState();
}

class _VrPressableState extends State<VrPressable> {
  var _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTap: enabled
            ? () {
                if (widget.haptic) HapticFeedback.selectionClick();
                widget.onTap!();
              }
            : null,
        child: AnimatedScale(
          scale: _down ? 0.97 : 1,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Mor degrade "Katıl" düğmesi.
class VrJoinButton extends StatelessWidget {
  const VrJoinButton({
    super.key,
    required this.onTap,
    this.label = 'Katıl',
    this.compact = false,
  });

  final VoidCallback? onTap;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return VrPressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 18,
          vertical: compact ? 6 : 9,
        ),
        decoration: BoxDecoration(
          gradient: VoiceRoomsUiTokens.purpleGradient,
          borderRadius: BorderRadius.circular(VoiceRoomsUiTokens.radiusPill),
          boxShadow: [
            BoxShadow(
              color: VoiceRoomsUiTokens.purpleGlow.withValues(alpha: 0.28),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mic_rounded,
              size: compact ? 13 : 15,
              color: Colors.white,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 11.5 : 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Üst üste binen mini avatarlar (+N).
class VrAvatarStack extends StatelessWidget {
  const VrAvatarStack({
    super.key,
    required this.urls,
    this.extra = 0,
    this.radius = 11,
    this.fallbackColor = VoiceRoomsUiTokens.purpleEnd,
  });

  final List<String> urls;
  final int extra;
  final double radius;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    final shown = urls.where((u) => u.trim().isNotEmpty).take(3).toList();
    if (shown.isEmpty && extra <= 0) return const SizedBox.shrink();
    final step = radius * 1.35;
    final d = radius * 2;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (shown.isNotEmpty)
          SizedBox(
            width: step * (shown.length - 1) + d,
            height: d,
            child: Stack(
              children: [
                for (var i = 0; i < shown.length; i++)
                  Positioned(
                    left: i * step,
                    child: Container(
                      width: d,
                      height: d,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: fallbackColor,
                        border: Border.all(
                          color: const Color(0xFF14082A),
                          width: 1.5,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: CanlifalNetworkImage(
                        url: shown[i],
                        width: d,
                        height: d,
                        thumbnailWidth: 64,
                        fadeIn: false,
                        errorWidget: ColoredBox(color: fallbackColor),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        if (extra > 0) ...[
          const SizedBox(width: 6),
          Text(
            '+${voiceRoomsCount(extra)}',
            style: const TextStyle(
              color: VoiceRoomsUiTokens.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

/// Bölüm başlığı: simge + başlık + "Tümünü Gör >".
class VrSectionHeader extends StatelessWidget {
  const VrSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.iconColor = VoiceRoomsUiTokens.orange,
    this.actionLabel,
    this.onAction,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final Color iconColor;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final head = Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: VoiceRoomsUiTokens.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: VoiceRoomsUiTokens.textMuted,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel!,
                    style: const TextStyle(
                      color: VoiceRoomsUiTokens.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: VoiceRoomsUiTokens.textSecondary,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VoiceRoomsUiTokens.padScreenH,
        VoiceRoomsUiTokens.gapLg + 4,
        VoiceRoomsUiTokens.padScreenH,
        VoiceRoomsUiTokens.gapMd,
      ),
      child: head,
    );
  }
}

// ───────────────────────────── Üst bar ─────────────────────────────

class VoiceRoomsHeaderBar extends ConsumerWidget {
  const VoiceRoomsHeaderBar({
    super.key,
    this.title = 'Sesli Odalar',
    this.subtitle = 'Konuş, dinle, yeni insanlarla tanış!',
    this.showBack = false,
    this.onSearch,
    this.onFilter,
    this.showTrophy = true,
  });

  final String title;
  final String? subtitle;
  final bool showBack;
  final VoidCallback? onSearch;
  final VoidCallback? onFilter;
  final bool showTrophy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inbox = ref.watch(inboxUnreadCountProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
      child: Row(
        children: [
          if (showBack)
            _BarIcon(
              icon: Icons.arrow_back_ios_new_rounded,
              label: 'Geri',
              onTap: () => context.canPop() ? context.pop() : context.go('/voice-rooms'),
            )
          else
            _BarIcon(
              icon: Icons.menu_rounded,
              label: 'Menü',
              gradient: true,
              onTap: () => showVoiceRoomsMenuSheet(context, ref),
            ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (!showBack) ...[
                      const VoiceSoundWaveBars(size: 18),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: VoiceRoomsUiTokens.textPrimary,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: VoiceRoomsUiTokens.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _BarIcon(
            icon: Icons.search_rounded,
            label: 'Ara',
            onTap: onSearch ?? () => context.push('/search'),
          ),
          if (onFilter != null)
            _BarIcon(
              icon: Icons.tune_rounded,
              label: 'Filtrele',
              onTap: onFilter!,
            )
          else if (showTrophy)
            _BarIcon(
              icon: Icons.emoji_events_outlined,
              label: 'Liderlik tablosu',
              onTap: () => context.push('/gifts/leaderboard'),
            ),
          if (onFilter == null)
            _BarIcon(
              icon: Icons.notifications_none_rounded,
              label: 'Bildirimler',
              badge: inbox,
              onTap: () => InboxRoutes.open(context),
            ),
        ],
      ),
    );
  }
}

class _BarIcon extends StatelessWidget {
  const _BarIcon({
    required this.icon,
    required this.label,
    required this.onTap,
    this.gradient = false,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool gradient;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final core = Container(
      width: 40,
      height: 40,
      decoration: gradient
          ? BoxDecoration(
              gradient: VoiceRoomsUiTokens.purpleGradient,
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: Icon(icon, color: Colors.white, size: gradient ? 22 : 23),
    );
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              core,
              if (badge > 0)
                Positioned(
                  top: 3,
                  right: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: VoiceRoomsUiTokens.badgeRed,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge > 99 ? '99+' : '$badge',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showVoiceRoomsMenuSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF12081F),
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      Widget tile(IconData i, String t, VoidCallback onTap) => ListTile(
            leading: Icon(i, color: VoiceRoomsUiTokens.purpleGlow),
            title: Text(
              t,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: VoiceRoomsUiTokens.textMuted,
            ),
            onTap: () {
              Navigator.pop(ctx);
              onTap();
            },
          );
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            tile(Icons.add_circle_outline_rounded, 'Oda Aç', () {
              showOpenVoiceChatRoomFlow(context, ref);
            }),
            tile(Icons.mic_none_rounded, 'Odalarım', () {
              context.push('/voice-rooms/mine');
            }),
            tile(Icons.public_rounded, 'Tüm Odalar', () {
              context.push('/voice-rooms/list');
            }),
            tile(Icons.group_outlined, 'Arkadaşlarımın Odaları', () {
              context.push('/voice-rooms/list?tab=2');
            }),
            tile(Icons.emoji_events_outlined, 'Liderlik Tablosu', () {
              context.push('/gifts/leaderboard');
            }),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

// ───────────────────────────── Hero ─────────────────────────────

class VoiceRoomsHeroBanner extends ConsumerWidget {
  const VoiceRoomsHeroBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms = ref.watch(voiceRoomsDiscoverProvider.select((s) => s.allRooms));
    var listeners = 0;
    final avatars = <String>[];
    for (final r in rooms) {
      listeners += r.displayOnline;
      for (final a in r.recentUserAvatars) {
        if (avatars.length < 3 && a.trim().isNotEmpty) avatars.add(a);
      }
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VoiceRoomsUiTokens.padScreenH,
        VoiceRoomsUiTokens.gapSm,
        VoiceRoomsUiTokens.padScreenH,
        0,
      ),
      child: Container(
        constraints: const BoxConstraints(minHeight: 168),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(VoiceRoomsUiTokens.radiusXl),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2B0F5E), Color(0xFF5B1FA6), Color(0xFF9B2FB5)],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          boxShadow: [
            BoxShadow(
              color: VoiceRoomsUiTokens.purpleGlow.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            const Positioned(
              right: -14,
              top: 0,
              bottom: 0,
              width: 168,
              child: ExcludeSemantics(child: _HeroArt()),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sesinle',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  ShaderMask(
                    shaderCallback: (r) => const LinearGradient(
                      colors: [Color(0xFFFF8AD8), Color(0xFFB388FF)],
                    ).createShader(r),
                    child: const Text(
                      'Daha Yakın Ol',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 190),
                    child: const Text(
                      'Sohbet et, yeni arkadaşlar edin, müzik dinle.',
                      style: TextStyle(
                        color: VoiceRoomsUiTokens.textSecondary,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      VrPressable(
                        semanticLabel: 'Oda aç',
                        onTap: () => showOpenVoiceChatRoomFlow(context, ref),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFA726), Color(0xFFFF4081)],
                            ),
                            borderRadius: BorderRadius.circular(
                              VoiceRoomsUiTokens.radiusPill,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_rounded, color: Colors.white, size: 20),
                              SizedBox(width: 4),
                              Text(
                                'Oda Aç',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (listeners > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            VrAvatarStack(urls: avatars, radius: 11),
                            const SizedBox(width: 6),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  voiceRoomsCount(listeners),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    height: 1.1,
                                  ),
                                ),
                                const Text(
                                  'aktif dinleyici',
                                  style: TextStyle(
                                    color: VoiceRoomsUiTokens.textMuted,
                                    fontSize: 9.5,
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sabit (animasyonsuz) hero görseli: halkalar + kulaklıklı mikrofon.
class _HeroArt extends StatelessWidget {
  const _HeroArt();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HeroArtPainter(),
      child: const Center(
        child: Icon(
          Icons.headset_mic_rounded,
          size: 76,
          color: Color(0xE6FFFFFF),
        ),
      ),
    );
  }
}

class _HeroArtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width * 0.5, size.height * 0.5);
    for (var i = 1; i <= 3; i++) {
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.16 - i * 0.04);
      canvas.drawCircle(c, 34.0 + i * 20, p);
    }
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFE040FB).withValues(alpha: 0.45),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: c, radius: 64));
    canvas.drawCircle(c, 64, glow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────── Popüler odalar (2 kolon) ───────────────────────

Color _rankColor(int rank) => switch (rank) {
      1 => VoiceRoomsUiTokens.gold,
      2 => VoiceRoomsUiTokens.purpleGlow,
      3 => VoiceRoomsUiTokens.blue,
      4 => VoiceRoomsUiTokens.onlineGreen,
      _ => VoiceRoomsUiTokens.magenta,
    };

class VoiceRoomGridCard extends StatelessWidget {
  const VoiceRoomGridCard({
    super.key,
    required this.room,
    required this.rank,
    required this.onJoin,
  });

  final VoiceRoomEntity room;
  final int rank;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final accent = _rankColor(rank);
    final image = (room.backgroundImageUrl ?? room.ownerAvatarUrl)?.trim();
    final extra = (room.userCount > room.recentUserAvatars.length)
        ? room.userCount - room.recentUserAvatars.length
        : 0;
    return RepaintBoundary(
      child: VrPressable(
        onTap: onJoin,
        semanticLabel: '${room.displayTitle}, ${room.displayOnline} dinleyici, katıl',
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(VoiceRoomsUiTokens.radiusLg),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [accent.withValues(alpha: 0.55), const Color(0xFF1A0B33)],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (image != null && image.isNotEmpty)
                CanlifalNetworkImage(
                  url: image,
                  fit: BoxFit.cover,
                  thumbnailWidth: 360,
                  errorWidget: const SizedBox.shrink(),
                ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x55000000), Color(0x22000000), Color(0xE60B0418)],
                    stops: [0, 0.35, 1],
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent,
                  ),
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      color: rank == 1 ? Colors.black : Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.visibility_outlined, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        voiceRoomsCount(room.displayOnline),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      room.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    VrCategoryChips(room: room),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Expanded(
                          child: VrAvatarStack(
                            urls: room.recentUserAvatars,
                            extra: extra,
                            radius: 10,
                            fallbackColor: accent.withValues(alpha: 0.6),
                          ),
                        ),
                        VrJoinButton(onTap: onJoin, compact: true),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kategori + oda tipi etiketleri (en çok 2).
class VrCategoryChips extends StatelessWidget {
  const VrCategoryChips({super.key, required this.room});

  final VoiceRoomEntity room;

  @override
  Widget build(BuildContext context) {
    final labels = <String>[];
    final cat = room.category?.trim();
    if (cat != null && cat.isNotEmpty) labels.add(voiceRoomCategoryLabel(cat));
    final type = room.roomType?.trim();
    if (type != null && type.isNotEmpty && !labels.contains(type)) labels.add(type);
    if (labels.isEmpty) labels.add('Sohbet');
    return Wrap(
      spacing: 5,
      runSpacing: 4,
      children: [
        for (final l in labels.take(2))
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: Text(
              l,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class VoiceRoomsPopularGridSection extends ConsumerWidget {
  const VoiceRoomsPopularGridSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrapping = ref.watch(
      voiceRoomsDiscoverProvider.select(
        (s) => s.isBootstrapping && s.categories.isEmpty,
      ),
    );
    if (bootstrapping) return const VoiceRoomsPopularSkeleton();
    final popular = ref.watch(voiceRoomsDiscoverProvider.select((s) => s.popular));
    final all = ref.watch(voiceRoomsDiscoverProvider.select((s) => s.allRooms));
    final rooms = <VoiceRoomEntity>[];
    for (final p in popular) {
      final r = voiceRoomById(all, p.id);
      if (r != null) rooms.add(r);
    }
    if (rooms.isEmpty) return const SizedBox.shrink();

    return VoiceRoomsFx.sectionEnter(
      Column(
        children: [
          VrSectionHeader(
            icon: Icons.local_fire_department_rounded,
            title: 'Popüler Sesli Odalar',
            actionLabel: 'Tümünü Gör',
            onAction: () => context.push('/voice-rooms/list'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: VoiceRoomsUiTokens.padScreenH,
            ),
            child: LayoutBuilder(
              builder: (context, c) {
                final cols = c.maxWidth >= 600 ? 3 : 2;
                const gap = 12.0;
                final w = (c.maxWidth - gap * (cols - 1)) / cols;
                // Yüksekliği genişliğe bağla; yazı büyütmede taşmasın.
                final scale = MediaQuery.textScalerOf(context).scale(1);
                final h = (w * 1.12).clamp(176.0, 250.0) + (scale - 1).clamp(0, 0.6) * 60;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (var i = 0; i < rooms.length; i++)
                      SizedBox(
                        width: w,
                        height: h,
                        child: VoiceRoomGridCard(
                          key: ValueKey('pop_${rooms[i].id}'),
                          room: rooms[i],
                          rank: i + 1,
                          onJoin: () => openVoiceRoomWithVipGate(context, ref, rooms[i]),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      delayMs: 100,
    );
  }
}

// ─────────────────────── Günün öne çıkan odası ───────────────────────

class VoiceRoomsFeaturedBanner extends ConsumerWidget {
  const VoiceRoomsFeaturedBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featured = ref.watch(voiceRoomsDiscoverProvider.select((s) => s.featured));
    final all = ref.watch(voiceRoomsDiscoverProvider.select((s) => s.allRooms));
    if (featured.isEmpty) return const SizedBox.shrink();
    final room = voiceRoomById(all, featured.first.id);
    if (room == null) return const SizedBox.shrink();
    final image = (room.backgroundImageUrl ?? room.ownerAvatarUrl)?.trim();
    final subtitle = featured.first.subtitle;
    return VoiceRoomsFx.sectionEnter(
      Padding(
        padding: const EdgeInsets.fromLTRB(
          VoiceRoomsUiTokens.padScreenH,
          VoiceRoomsUiTokens.gapLg + 4,
          VoiceRoomsUiTokens.padScreenH,
          0,
        ),
        child: VrPressable(
          onTap: () => openVoiceRoomWithVipGate(context, ref, room),
          semanticLabel: 'Günün öne çıkan odası ${room.displayTitle}, katıl',
          child: Container(
            constraints: const BoxConstraints(minHeight: 116),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(VoiceRoomsUiTokens.radiusLg),
              gradient: const LinearGradient(
                colors: [Color(0xFF3A1470), Color(0xFF1A0B33)],
              ),
              border: Border.all(
                color: VoiceRoomsUiTokens.gold.withValues(alpha: 0.35),
              ),
            ),
            child: Stack(
              children: [
                if (image != null && image.isNotEmpty)
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.55,
                      child: CanlifalNetworkImage(
                        url: image,
                        fit: BoxFit.cover,
                        thumbnailWidth: 480,
                        errorWidget: const SizedBox.shrink(),
                      ),
                    ),
                  ),
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xF00B0418), Color(0x990B0418), Color(0x220B0418)],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.star_rounded,
                                    color: VoiceRoomsUiTokens.gold, size: 18),
                                SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    'Günün Öne Çıkan Odası',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: VoiceRoomsUiTokens.gold,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              room.displayTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: VoiceRoomsUiTokens.textSecondary,
                                fontSize: 12,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      VrJoinButton(
                        onTap: () => openVoiceRoomWithVipGate(context, ref, room),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      delayMs: 140,
    );
  }
}

// ─────────────────────── Öne çıkan kategoriler ───────────────────────

class VoiceRoomsFeaturedCategories extends ConsumerWidget {
  const VoiceRoomsFeaturedCategories({super.key});

  static const _ids = ['chat', 'music', 'love', 'fal', 'game', 'friends'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = [
      for (final id in _ids)
        VoiceRoomsMockData.categories.firstWhere((c) => c.id == id),
    ];
    return Column(
      children: [
        const VrSectionHeader(
          icon: Icons.local_fire_department_rounded,
          title: 'Öne Çıkan Kategoriler',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: VoiceRoomsUiTokens.padScreenH,
          ),
          child: LayoutBuilder(
            builder: (context, c) {
              const gap = 10.0;
              final cols = c.maxWidth >= 600 ? 6 : 3;
              final w = (c.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final it in items)
                    SizedBox(
                      width: w,
                      height: w * 0.92,
                      child: _CategoryTile(
                        item: it,
                        onTap: () {
                          final cats = ref.read(voiceRoomsDiscoverProvider).categories;
                          final idx = cats.indexWhere((c) => c.id == it.id);
                          if (idx >= 0) {
                            ref
                                .read(voiceRoomsDiscoverProvider.notifier)
                                .selectCategory(idx);
                          }
                          context.push('/voice-rooms/list');
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.item, required this.onTap});

  final VoiceCategoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = item.materialIcon ?? _fallbackIcon(item.id);
    return VrPressable(
      onTap: onTap,
      semanticLabel: '${item.label} odaları',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(VoiceRoomsUiTokens.radiusMd),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              item.colors.first.withValues(alpha: 0.55),
              const Color(0xFF14082A),
            ],
          ),
          border: Border.all(color: item.colors.first.withValues(alpha: 0.35)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: Colors.white),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _fallbackIcon(String id) => switch (id) {
        'chat' => Icons.forum_rounded,
        'music' => Icons.music_note_rounded,
        'love' => Icons.favorite_rounded,
        'game' => Icons.sports_esports_rounded,
        _ => Icons.mic_rounded,
      };
}

// ───────────────────────── Kendi odanı aç ─────────────────────────

class VoiceRoomsCreateBanner extends ConsumerWidget {
  const VoiceRoomsCreateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VoiceRoomsUiTokens.padScreenH,
        VoiceRoomsUiTokens.gapLg + 4,
        VoiceRoomsUiTokens.padScreenH,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(VoiceRoomsUiTokens.radiusLg),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3B1480), Color(0xFF1A0B33)],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: VoiceRoomsUiTokens.fabGradient,
              ),
              child: const Icon(Icons.mic_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Kendi Odanı Aç',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Arkadaşlarınla sohbet et, müzik dinle ve yeni insanlarla tanış.',
                    style: TextStyle(
                      color: VoiceRoomsUiTokens.textSecondary,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            VrPressable(
              semanticLabel: 'Oda aç',
              onTap: () => showOpenVoiceChatRoomFlow(context, ref),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: VoiceRoomsUiTokens.purpleGradient,
                  borderRadius: BorderRadius.circular(VoiceRoomsUiTokens.radiusPill),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 3),
                    Text(
                      'Oda Aç',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
