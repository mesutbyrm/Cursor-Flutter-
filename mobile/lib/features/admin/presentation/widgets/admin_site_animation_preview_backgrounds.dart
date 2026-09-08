import 'package:flutter/material.dart';

import '../../../../core/site_animation/presentation/utils/site_animation_voice_room_layout.dart';
import '../../../../core/site_animation/presentation/widgets/site_animation_profile_entrance_stagger.dart';
import '../../../voice_hub/presentation/theme/voice_room_tokens.dart';

/// Admin animasyon önizlemesi — CanlıFal ekran mock arka planları.
enum AdminSiteAnimationPreviewScreen {
  voice,
  social,
  profile,
  falTarot;

  String get label => switch (this) {
        AdminSiteAnimationPreviewScreen.voice => 'Sesli Oda',
        AdminSiteAnimationPreviewScreen.social => 'CanlıFal Sosyal',
        AdminSiteAnimationPreviewScreen.profile => 'Profil',
        AdminSiteAnimationPreviewScreen.falTarot => 'Fal & Tarot',
      };

  IconData get icon => switch (this) {
        AdminSiteAnimationPreviewScreen.voice => Icons.mic_rounded,
        AdminSiteAnimationPreviewScreen.social => Icons.people_rounded,
        AdminSiteAnimationPreviewScreen.profile => Icons.person_rounded,
        AdminSiteAnimationPreviewScreen.falTarot => Icons.auto_awesome_rounded,
      };
}

/// Tasarım referans paleti — mevcut uygulama tonları.
abstract final class CanlifalPreviewPalette {
  static const bgDeep = Color(0xFF0A0814);
  static const bgCard = Color(0xFF151126);
  static const purple = Color(0xFF6D2CE8);
  static const purpleLight = Color(0xFF8B4DFF);
  static const magenta = Color(0xFFC026D3);
  static const cyan = Color(0xFF00D9D9);
  static const gold = Color(0xFFFFD45A);
}

class AdminSiteAnimationPreviewBackground extends StatelessWidget {
  const AdminSiteAnimationPreviewBackground({
    super.key,
    required this.screen,
  });

  final AdminSiteAnimationPreviewScreen screen;

  @override
  Widget build(BuildContext context) {
    return switch (screen) {
      AdminSiteAnimationPreviewScreen.voice => const _VoiceRoomMock(),
      AdminSiteAnimationPreviewScreen.social => const _SocialMock(),
      AdminSiteAnimationPreviewScreen.profile => const _ProfileMock(),
      AdminSiteAnimationPreviewScreen.falTarot => const _FalTarotMock(),
    };
  }
}

class _VoiceRoomMock extends StatelessWidget {
  const _VoiceRoomMock();

  @override
  Widget build(BuildContext context) {
    const stageTop = SiteAnimationVoiceRoomLayout.headerHeight;
    final width = MediaQuery.sizeOf(context).width;
    final m = SiteAnimationVoiceRoomLayout.metrics(width);

    return SiteAnimationVoiceRoomLayoutScope(
      stageTop: stageTop,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(gradient: VoiceRoomTokens.roomGradient),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _VoicePreviewHeader(),
              SizedBox(
                height: m.totalH,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SiteAnimationVoiceRoomLayout.hPad,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _PreviewSeat(
                        label: 'HOST',
                        highlight: true,
                        size: m.hostSize,
                        occupied: true,
                      ),
                      const SizedBox(width: SiteAnimationVoiceRoomLayout.gap),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _PreviewSeatRow(
                              seats: m.topSeats,
                              cell: m.cell,
                              occupiedSeat: 3,
                            ),
                            const SizedBox(
                              height: SiteAnimationVoiceRoomLayout.gap,
                            ),
                            _PreviewSeatRow(
                              seats: m.bottomSeats,
                              cell: m.cell,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Container(
                  height: 34,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: [
                        VoiceRoomTokens.gold.withValues(alpha: 0.35),
                        Colors.black.withValues(alpha: 0.75),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              const _BottomNavMock(activeIndex: 2),
            ],
          ),
        ],
      ),
    );
  }
}

class _VoicePreviewHeader extends StatelessWidget {
  const _VoicePreviewHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: SiteAnimationVoiceRoomLayout.headerHeight,
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.72),
            Colors.black.withValues(alpha: 0.28),
          ],
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 18,
            backgroundColor: VoiceRoomTokens.neonPurple.withValues(alpha: 0.35),
            child: const Text('🎤', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'CanlıFal Sohbet',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'ID: preview-room',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '968.240',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewSeatRow extends StatelessWidget {
  const _PreviewSeatRow({
    required this.seats,
    required this.cell,
    this.occupiedSeat,
  });

  final List<int> seats;
  final double cell;
  final int? occupiedSeat;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < seats.length; i++) ...[
          if (i > 0) const SizedBox(width: SiteAnimationVoiceRoomLayout.gap),
          _PreviewSeat(
            label: '${seats[i]}',
            size: cell,
            occupied: seats[i] == occupiedSeat,
          ),
        ],
      ],
    );
  }
}

class _PreviewSeat extends StatelessWidget {
  const _PreviewSeat({
    required this.label,
    required this.size,
    this.highlight = false,
    this.occupied = false,
  });

  final String label;
  final double size;
  final bool highlight;
  final bool occupied;

  @override
  Widget build(BuildContext context) {
    final color = highlight ? VoiceRoomTokens.gold : VoiceRoomTokens.neonPurple;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.7), width: 2),
            color: Colors.white.withValues(alpha: occupied ? 0.12 : 0.05),
          ),
          child: occupied
              ? Icon(Icons.person, color: color.withValues(alpha: 0.85), size: size * 0.45)
              : Icon(Icons.add, color: Colors.white38, size: size * 0.38),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: color.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}

class _SocialMock extends StatelessWidget {
  const _SocialMock();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0E0524), Color(0xFF12082A)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'CanlıFal Sosyal',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 6,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) => Container(
                width: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      CanlifalPreviewPalette.purple.withValues(alpha: 0.9),
                      CanlifalPreviewPalette.magenta.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 2,
              itemBuilder: (_, i) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CanlifalPreviewPalette.bgCard.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: CanlifalPreviewPalette.purple.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: CanlifalPreviewPalette.purple.withValues(alpha: 0.4),
                      child: const Icon(Icons.person, color: Colors.white70, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            i == 0 ? 'Mesut Bayram' : 'CanlıFal Üyesi',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'Premium sosyal gönderi kartı',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const _BottomNavMock(activeIndex: 1),
        ],
      ),
    );
  }
}

class _ProfileMock extends StatelessWidget {
  const _ProfileMock();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF151126), Color(0xFF0A0814)],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 56),
          SiteAnimationProfileEntranceStagger(
            avatar: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: CanlifalPreviewPalette.gold, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: CanlifalPreviewPalette.gold.withValues(alpha: 0.35),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: CanlifalPreviewPalette.bgCard,
                    child: Icon(
                      Icons.person,
                      size: 44,
                      color: CanlifalPreviewPalette.purpleLight,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD45A), Color(0xFFFFA726)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'GOLD',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF3D2A00),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            nameRow: const Text(
              'Mesut Bayram',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            membershipRow: Text(
              'Gold Member · Seviye 42',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ProfileStat(label: 'Jeton', value: '12.4K'),
              _ProfileStat(label: 'Elmas', value: '890'),
              _ProfileStat(label: 'Hediye', value: '156'),
            ],
          ),
          const Spacer(),
          const _BottomNavMock(activeIndex: 4),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: CanlifalPreviewPalette.gold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _FalTarotMock extends StatelessWidget {
  const _FalTarotMock();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.3),
              radius: 1.2,
              colors: [
                Color(0xFF24103D),
                Color(0xFF0A0814),
                Color(0xFF050308),
              ],
            ),
          ),
        ),
        ...List.generate(24, (i) {
          return Positioned(
            left: (i * 37.0) % 280,
            top: (i * 53.0) % 420,
            child: Icon(
              Icons.star_rounded,
              size: 4 + (i % 3).toDouble(),
              color: Colors.white.withValues(alpha: 0.15 + (i % 5) * 0.05),
            ),
          );
        }),
        Center(
          child: Container(
            width: 140,
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  CanlifalPreviewPalette.purple.withValues(alpha: 0.5),
                  CanlifalPreviewPalette.magenta.withValues(alpha: 0.35),
                ],
              ),
              border: Border.all(
                color: CanlifalPreviewPalette.cyan.withValues(alpha: 0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: CanlifalPreviewPalette.purple.withValues(alpha: 0.45),
                  blurRadius: 24,
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white70,
              size: 48,
            ),
          ),
        ),
        const Positioned(
          top: 48,
          left: 16,
          child: Text(
            'Fal & Tarot',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ),
        const _BottomNavMock(activeIndex: 3),
      ],
    );
  }
}

class _BottomNavMock extends StatelessWidget {
  const _BottomNavMock({required this.activeIndex});

  final int activeIndex;

  static const _labels = ['Ana', 'Sosyal', 'Sesli', 'Fal', 'Profil'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: CanlifalPreviewPalette.bgDeep.withValues(alpha: 0.92),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_labels.length, (i) {
          final active = i == activeIndex;
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.circle,
                size: 8,
                color: active
                    ? CanlifalPreviewPalette.purpleLight
                    : Colors.white24,
              ),
              const SizedBox(height: 2),
              Text(
                _labels[i],
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: active
                      ? CanlifalPreviewPalette.purpleLight
                      : Colors.white38,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
