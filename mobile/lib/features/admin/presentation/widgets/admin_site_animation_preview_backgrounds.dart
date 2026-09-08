import 'package:flutter/material.dart';

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
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(decoration: const BoxDecoration(gradient: VoiceRoomTokens.roomGradient)),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MockSeat(label: 'HOST', highlight: true),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  _MockSeat(label: '2'),
                  SizedBox(width: 12),
                  _MockSeat(label: '3', occupied: true),
                  SizedBox(width: 12),
                  _MockSeat(label: '4'),
                ],
              ),
            ],
          ),
        ),
        const _BottomNavMock(activeIndex: 2),
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
          Stack(
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
          const SizedBox(height: 12),
          const Text(
            'Mesut Bayram',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Gold Member · Seviye 42',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
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

class _MockSeat extends StatelessWidget {
  const _MockSeat({
    required this.label,
    this.highlight = false,
    this.occupied = false,
  });

  final String label;
  final bool highlight;
  final bool occupied;

  @override
  Widget build(BuildContext context) {
    final color = highlight ? VoiceRoomTokens.gold : VoiceRoomTokens.neonPurple;
    return Column(
      children: [
        Container(
          width: highlight ? 64 : 52,
          height: highlight ? 64 : 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.7), width: 2),
            color: Colors.white.withValues(alpha: occupied ? 0.12 : 0.05),
          ),
          child: occupied
              ? Icon(Icons.person, color: color.withValues(alpha: 0.8), size: 24)
              : Icon(Icons.add, color: Colors.white38, size: 20),
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
