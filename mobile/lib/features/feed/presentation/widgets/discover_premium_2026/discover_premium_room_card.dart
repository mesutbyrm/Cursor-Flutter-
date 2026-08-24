import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../../core/ui/premium_2026/premium_motion.dart';
import 'discover_premium_visual.dart';
import 'discover_room_visuals.dart';
import '../../../domain/discover_category.dart';
import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../../voice_hub/presentation/widgets/premium_2026/voice_discover_2026.dart';

/// Neon glow sesli oda kartı — canlı dalga, rozetler, konuşan avatar vurgusu.
class DiscoverPremiumRoomCard extends StatefulWidget {
  const DiscoverPremiumRoomCard({
    super.key,
    required this.room,
    required this.onTap,
    this.width = 168,
    this.compact = false,
    this.enableMotion = true,
  });

  final VoiceRoomEntity room;
  final VoidCallback onTap;
  final double width;
  final bool compact;
  final bool enableMotion;

  @override
  State<DiscoverPremiumRoomCard> createState() =>
      _DiscoverPremiumRoomCardState();
}

class _DiscoverPremiumRoomCardState extends State<DiscoverPremiumRoomCard>
    with TickerProviderStateMixin {
  var _pressed = false;
  late final AnimationController _waveCtrl;
  late final AnimationController _spinCtrl;
  late final AnimationController _micCtrl;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _micCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.enableMotion) {
      _waveCtrl.repeat();
      _spinCtrl.repeat();
      _micCtrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _spinCtrl.dispose();
    _micCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final online = widget.room.displayOnline;
    final bg = widget.room.backgroundImageUrl;
    final h = widget.compact ? 200.0 : 220.0;
    final isVip = matchesDiscoverCategory(widget.room, 'vip');
    final roomType = widget.room.roomType?.trim().toLowerCase() ?? '';
    final level = _roomLevel(online);
    final popularity = _popularityLabel(online);
    final showMusic = widget.room.hasMusicActivity;
    final showPk = widget.room.isPkLive;
    final occupied = online > 0;

    return RepaintBoundary(
      child: Opacity(
        opacity: occupied ? 1 : 0.58,
        child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: PremiumMotion.fast,
          curve: PremiumMotion.spring,
          child: AnimatedContainer(
            duration: PremiumMotion.medium,
            width: widget.width,
            height: h,
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(DiscoverPremiumVisual.cardRadius),
              boxShadow: DiscoverPremiumVisual.cardGlow(pressed: _pressed),
            ),
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(DiscoverPremiumVisual.cardRadius),
              child: Stack(
                fit: StackFit.expand,
                children: [
                if (bg != null && bg.isNotEmpty)
                  CanlifalNetworkImage(url: bg, fit: BoxFit.cover)
                else
                  DecoratedBox(
                    decoration: DiscoverRoomVisuals.fallbackDecoration(widget.room),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.1),
                          Colors.black.withValues(alpha: 0.82),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 72,
                    child: _LiveWaveform(controller: _waveCtrl),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    right: 10,
                    child: Row(
                      children: [
                        _GlowingOnlinePill(count: online),
                        const Spacer(),
                        if (showPk)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF5252), Color(0xFFD50000)],
                              ),
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF5252)
                                      .withValues(alpha: 0.45),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Text(
                              'PK',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        if (showMusic)
                          RotationTransition(
                            turns: _spinCtrl,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.4),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.music_note_rounded,
                                size: 14,
                                color: Color(0xFFFFD54F),
                              ),
                            ),
                          ),
                        if (showMusic) const SizedBox(width: 6),
                        if (online > 0) _MicPulse(controller: _micCtrl),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 38,
                    left: 10,
                    right: 10,
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        if (showPk)
                          const _RoomBadge(
                            label: 'PK Canlı',
                            colors: [Color(0xFFFF5252), Color(0xFFB71C1C)],
                          ),
                        if (showMusic)
                          const _RoomBadge(
                            label: 'Müzik',
                            colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                          ),
                        if (isVip) const _RoomBadge(label: 'VIP', colors: [Color(0xFFFFE082), Color(0xFFFF8F00)]),
                        if (roomType.contains('gold')) const _RoomBadge(label: 'Gold', colors: [Color(0xFFFFF176), Color(0xFFFFB300)]),
                        if (roomType.contains('admin')) const _RoomBadge(label: 'Admin', colors: [Color(0xFFEF5350), Color(0xFFB71C1C)]),
                        _RoomBadge(label: 'Lv.$level', colors: const [Color(0xFF7C4DFF), Color(0xFF448AFF)]),
                        if (popularity != null)
                          _RoomBadge(label: popularity, colors: const [Color(0xFF26A69A), Color(0xFF00897B)]),
                        if (roomType.isNotEmpty && !roomType.contains('gold') && !roomType.contains('admin'))
                          _RoomBadge(
                            label: DiscoverRoomVisuals.categoryLabel(widget.room) ??
                                _categoryLabel(roomType),
                            colors: const [Color(0xFF5C6BC0), Color(0xFF3949AB)],
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.room.displayTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: Colors.white,
                            height: 1.15,
                          ),
                        ),
                        if (widget.room.ownerName != null &&
                            widget.room.ownerName!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const _RoomBadge(
                                label: 'Sahip',
                                colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  widget.room.ownerName!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.65),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        _SpeakingAvatarStrip(
                          avatars: widget.room.recentUserAvatars,
                          online: online,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }

  int _roomLevel(int online) {
    if (online >= 200) return 5;
    if (online >= 100) return 4;
    if (online >= 50) return 3;
    if (online >= 20) return 2;
    return 1;
  }

  String? _popularityLabel(int online) {
    if (online >= 150) return '🔥 Popüler';
    if (online >= 50) return '⭐ Aktif';
    return null;
  }

  String _categoryLabel(String type) {
    if (type.contains('tarot')) return 'Tarot';
    if (type.contains('burc') || type.contains('zodiac')) return 'Burç';
    if (type.contains('kahve') || type.contains('coffee')) return 'Kahve';
    if (type.contains('muzik') || type.contains('music')) return 'Müzik';
    if (type.contains('sohbet') || type.contains('chat')) return 'Sohbet';
    return type.length > 12 ? '${type.substring(0, 12)}…' : type;
  }
}

class _GlowingOnlinePill extends StatelessWidget {
  const _GlowingOnlinePill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFD54F).withValues(alpha: 0.85),
        ),
        boxShadow: count > 0
            ? [
                BoxShadow(
                  color: const Color(0xFFFFD54F).withValues(alpha: 0.45),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: count > 0
                  ? const Color(0xFFFFD54F)
                  : Colors.white.withValues(alpha: 0.35),
              boxShadow: count > 0
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFFD54F).withValues(alpha: 0.8),
                        blurRadius: 6,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            VoiceLiveHeader2026Format.count(count),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Color(0xFFFFEE58),
              shadows: [
                Shadow(color: Color(0xFFFFD54F), blurRadius: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MicPulse extends StatelessWidget {
  const _MicPulse({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final scale = 0.9 + controller.value * 0.2;
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppThemeColors.accentPink.withValues(alpha: 0.35),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppThemeColors.accentPink.withValues(alpha: 0.8),
              ),
            ),
            child: const Icon(
              Icons.mic_rounded,
              size: 12,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}

class _LiveWaveform extends StatelessWidget {
  const _LiveWaveform({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return SizedBox(
          height: 18,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(16, (i) {
              final phase = (controller.value + i * 0.08) % 1.0;
              final h = 3 + math.sin(phase * math.pi * 2) * 6 + 4;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0.5),
                  child: Container(
                    height: h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          const Color(0xFFB832FF).withValues(alpha: 0.9),
                          const Color(0xFF00E5FF).withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class _RoomBadge extends StatelessWidget {
  const _RoomBadge({required this.label, required this.colors});

  final String label;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _SpeakingAvatarStrip extends StatelessWidget {
  const _SpeakingAvatarStrip({
    required this.avatars,
    this.online = 0,
  });

  final List<String> avatars;
  final int online;

  @override
  Widget build(BuildContext context) {
    final urls = avatars.where((u) => u.isNotEmpty).take(5).toList();
    if (urls.isEmpty) {
      if (online <= 0) return const SizedBox(height: 26);
      return SizedBox(
        height: 26,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '$online kişi odada',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ),
      );
    }

    final extra = online > urls.length ? online - urls.length : 0;

    return SizedBox(
      height: 26,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < urls.length; i++)
            Positioned(
              left: i * 14.0,
              bottom: 0,
              child: AnimatedContainer(
                duration: PremiumMotion.fast,
                width: i == 0 ? 26 : 22,
                height: i == 0 ? 26 : 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: i == 0
                        ? AppThemeColors.accentPink
                        : Colors.white.withValues(alpha: 0.35),
                    width: i == 0 ? 2 : 1,
                  ),
                  boxShadow: i == 0
                      ? AppThemeColors.glowShadow(
                          AppThemeColors.accentPink,
                          blur: 10,
                        )
                      : null,
                ),
                child: CircleAvatar(
                  radius: i == 0 ? 12 : 10,
                  backgroundColor: const Color(0xFF1E1033),
                  backgroundImage: canlifalImageProvider(urls[i]),
                ),
              ),
            ),
          if (extra > 0)
            Positioned(
              left: urls.length * 14.0 + 4,
              bottom: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFFFD54F).withValues(alpha: 0.6),
                  ),
                ),
                child: Text(
                  '+$extra',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFFEE58),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
