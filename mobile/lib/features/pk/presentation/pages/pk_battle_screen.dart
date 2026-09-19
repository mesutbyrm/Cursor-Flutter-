import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Canlı yayın 1v1 PK ekranı — tasarım referansına birebir sadık düzen.
///
/// Ekran kendi içinde derlenir: örnek veriler `PkBattleScreen` alanlarında
/// varsayılan olarak referans görselle aynıdır; gerçek yayında video panelleri
/// [leftVideo] / [rightVideo] ile, veriler diğer alanlarla beslenir.
class PkBattleScreen extends StatelessWidget {
  const PkBattleScreen({
    super.key,
    this.leftVideo,
    this.rightVideo,
    this.roomTitle = 'CanlıFal',
    this.roomSubtitle = 'Hayata Fal Kat 💜',
    this.viewerCount = '1.2K',
    this.league = 'Lig 4',
    this.left = const PkStreamer(
      name: 'Selen',
      badgeEmoji: '💗',
      fire: '125.4K',
      verified: false,
    ),
    this.right = const PkStreamer(
      name: 'Mert',
      badgeEmoji: '',
      fire: '98.7K',
      verified: true,
    ),
    this.timerText = '00:58',
    this.leftScore = 12450,
    this.rightScore = 9870,
    this.statusText = 'PK devam ediyor!',
    this.gifts = const [
      PkGiftEvent(name: 'Deniz', action: 'Gül gönderdi', emoji: '🌹', count: 10),
      PkGiftEvent(name: 'Mete', action: 'Konfeti gönderdi', emoji: '🎉', count: 5),
    ],
    this.messages = const [
      PkChatMessage(name: 'Ayşe', text: 'Harikasın selen 💜', star: true),
      PkChatMessage(name: 'Emre', text: 'Maşallah 🔥'),
      PkChatMessage(name: 'Zeynep', text: 'Bu PK efsane 👏'),
      PkChatMessage(name: 'Murat', text: 'Mert çok iyi gidiyor 💪'),
      PkChatMessage(name: 'Elif', text: 'İkinize de başarılar 💜'),
      PkChatMessage(
        name: 'Kemal',
        text: 'Gül gönderdi 🌹 x10',
        crown: true,
        star: true,
        highlighted: true,
      ),
    ],
  });

  final Widget? leftVideo;
  final Widget? rightVideo;
  final String roomTitle;
  final String roomSubtitle;
  final String viewerCount;
  final String league;
  final PkStreamer left;
  final PkStreamer right;
  final String timerText;
  final int leftScore;
  final int rightScore;
  final String statusText;
  final List<PkGiftEvent> gifts;
  final List<PkChatMessage> messages;

  static const Color _bg = Color(0xFF07070C);
  static const Color _pink = Color(0xFFFF2D6B);
  static const Color _blue = Color(0xFF2E9BFF);
  static const Color _purple = Color(0xFF8B5CF6);
  static const Color _gold = Color(0xFFFFD24A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            _buildStreamerRow(),
            Expanded(child: _buildBattleArea()),
            _buildScoreBar(),
            Expanded(child: _buildChatArea()),
            _buildControlBar(),
            _buildInputRow(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Üst başlık: geri, oda adı, izleyiciler, kapat
  // ---------------------------------------------------------------------------
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      child: Row(
        children: [
          const Icon(Icons.chevron_left, color: Colors.white, size: 30),
          const SizedBox(width: 4),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_purple, _pink],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Text(
                    roomTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('💜', style: TextStyle(fontSize: 13)),
                ],
              ),
              Text(
                roomSubtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 11.5),
              ),
            ],
          ),
          const Spacer(),
          _buildViewerAvatars(),
          const SizedBox(width: 6),
          _buildViewerPill(),
          const SizedBox(width: 6),
          const Icon(Icons.close, color: Colors.white, size: 26),
        ],
      ),
    );
  }

  Widget _buildViewerAvatars() {
    const rings = [_gold, Color(0xFFB0BEC5), Color(0xFFCD7F32)];
    return SizedBox(
      width: 74,
      height: 34,
      child: Stack(
        children: [
          for (var i = 0; i < 3; i++)
            Positioned(
              left: i * 22.0,
              child: _RankAvatar(rank: i + 1, ring: rings[i], size: 30),
            ),
        ],
      ),
    );
  }

  Widget _buildViewerPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person, color: Colors.white, size: 15),
          const SizedBox(width: 3),
          Text(
            viewerCount,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Yayıncı satırı: Sol yayıncı | PK sayacı | Sağ yayıncı
  // ---------------------------------------------------------------------------
  Widget _buildStreamerRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildStreamerCard(left, isLeft: true)),
          const SizedBox(width: 6),
          _buildTimerBadge(),
          const SizedBox(width: 6),
          Expanded(child: _buildStreamerCard(right, isLeft: false)),
        ],
      ),
    );
  }

  Widget _buildStreamerCard(PkStreamer s, {required bool isLeft}) {
    final accent = isLeft ? _pink : _blue;
    final followGradient = isLeft
        ? const [Color(0xFFFF2D6B), Color(0xFFFF5C8A)]
        : const [Color(0xFF2E9BFF), Color(0xFF4FC3F7)];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RingAvatar(ring: accent, size: 38),
          const SizedBox(width: 6),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 2),
                  if (s.verified)
                    const Icon(Icons.verified, color: _blue, size: 14)
                  else if (s.badgeEmoji.isNotEmpty)
                    Text(s.badgeEmoji, style: const TextStyle(fontSize: 11)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 10)),
                  const SizedBox(width: 2),
                  Text(
                    s.fire,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: followGradient),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              '+ Takip et',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _gold.withValues(alpha: 0.7), width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⚡', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 2),
              ShaderMask(
                shaderCallback: (r) => const LinearGradient(
                  colors: [_pink, Color(0xFFFF7AA8)],
                ).createShader(r),
                child: const Text(
                  'PK',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          Text(
            timerText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Split video + VS amblemi + katmanlar
  // ---------------------------------------------------------------------------
  Widget _buildBattleArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            Row(
              children: [
                Expanded(
                  child: leftVideo ?? const _VideoPlaceholder(isLeft: true),
                ),
                Expanded(
                  child: rightVideo ?? const _VideoPlaceholder(isLeft: false),
                ),
              ],
            ),
            // Lig rozeti
            Positioned(
              left: 8,
              top: 8,
              child: _buildLeaguePill(),
            ),
            // Mikrofon / kamera (sağ üst)
            Positioned(
              right: 8,
              top: 8,
              child: Row(
                children: [
                  _circleIcon(Icons.mic, size: 30),
                  const SizedBox(width: 6),
                  _circleIcon(Icons.videocam, size: 30),
                ],
              ),
            ),
            // VS amblemi (orta)
            const Positioned.fill(child: Center(child: _VsEmblem())),
            // Hediye akışı (sol orta-alt)
            Positioned(
              left: 6,
              bottom: 44,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final g in gifts) ...[
                    _buildGiftRow(g),
                    const SizedBox(height: 6),
                  ],
                ],
              ),
            ),
            // Yüzen kalpler (sağ)
            const Positioned(
              right: 6,
              bottom: 40,
              top: 40,
              child: _FloatingHearts(count: 5),
            ),
            // Destekçiler — sol alt
            Positioned(
              left: 6,
              bottom: 6,
              child: _buildSupporters(isLeft: true),
            ),
            // Destekçiler — sağ alt
            Positioned(
              right: 6,
              bottom: 6,
              child: _buildSupporters(isLeft: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaguePill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_purple, Color(0xFF6D28D9)]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('💎', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            league,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleIcon(IconData icon, {double size = 32}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.5),
    );
  }

  Widget _buildGiftRow(PkGiftEvent g) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _RingAvatar(ring: Colors.white24, size: 30),
          const SizedBox(width: 6),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                g.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                g.action,
                style: const TextStyle(color: Colors.white70, fontSize: 10.5),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Text(g.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 4),
          Text(
            'x${g.count}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupporters({required bool isLeft}) {
    final ring = isLeft ? _pink : _blue;
    final ranks = isLeft ? const [3, 2, 1] : const [1, 2, 3];
    return SizedBox(
      width: 88,
      height: 30,
      child: Stack(
        children: [
          for (var i = 0; i < 3; i++)
            Positioned(
              left: i * 26.0,
              child: _RankAvatar(rank: ranks[i], ring: ring, size: 28),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Skor barı: kırmızı/mavi bölünmüş bar, yüzdeler, orta durum pili
  // ---------------------------------------------------------------------------
  Widget _buildScoreBar() {
    final total = (leftScore + rightScore).clamp(1, 1 << 31);
    final leftPct = (leftScore / total * 100).round().clamp(1, 99);
    final rightPct = 100 - leftPct;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  height: 34,
                  child: Row(
                    children: [
                      Expanded(
                        flex: leftPct,
                        child: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 14),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFFF2D6B), Color(0xFFFF5C8A)],
                            ),
                          ),
                          child: Text(
                            _formatScore(leftScore),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: rightPct,
                        child: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 14),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF4FC3F7), Color(0xFF2E9BFF)],
                            ),
                          ),
                          child: Text(
                            _formatScore(rightScore),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Stack(
            alignment: Alignment.center,
            children: [
              Row(
                children: [
                  Text(
                    '$leftPct%',
                    style: const TextStyle(
                      color: _pink,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$rightPct%',
                    style: const TextStyle(
                      color: _blue,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              _buildStatusPill(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF16121F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _purple.withValues(alpha: 0.8), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⚡', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sohbet + Gönder butonu + yüzen kalpler
  // ---------------------------------------------------------------------------
  Widget _buildChatArea() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 8, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 4),
              physics: const NeverScrollableScrollPhysics(),
              itemCount: messages.length,
              itemBuilder: (context, i) => _buildChatMessage(messages[i]),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: const [
              _FloatingHearts(count: 4, height: 120),
              SizedBox(height: 8),
              _SendGiftButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessage(PkChatMessage m) {
    final nameColor = m.highlighted ? _gold : const Color(0xFFB39DDB);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: m.highlighted
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 5)
            : EdgeInsets.zero,
        decoration: m.highlighted
            ? BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _gold.withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              )
            : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RingAvatar(
              ring: m.highlighted ? _gold : Colors.white24,
              size: 26,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    if (m.crown)
                      const TextSpan(text: '👑 ', style: TextStyle(fontSize: 13)),
                    if (m.star)
                      const TextSpan(text: '⭐ ', style: TextStyle(fontSize: 12)),
                    TextSpan(
                      text: '${m.name} ',
                      style: TextStyle(
                        color: nameColor,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(
                      text: m.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        height: 1.25,
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

  // ---------------------------------------------------------------------------
  // Kontrol çubuğu: 5 yuvarlak buton
  // ---------------------------------------------------------------------------
  Widget _buildControlBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          _ControlButton(icon: Icons.mic, label: 'Mikrofon'),
          _ControlButton(icon: Icons.videocam, label: 'Kamera'),
          _ControlButton(icon: Icons.volume_off, label: 'Rakibi sessize al'),
          _ControlButton(icon: Icons.chat_bubble, label: 'Sohbet'),
          _ControlButton(
            icon: Icons.stop,
            label: "PK'yi Bitir",
            filled: true,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Mesaj satırı: emoji + input + gönder + Gül / Hediye / Daha fazla
  // ---------------------------------------------------------------------------
  Widget _buildInputRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_emotions_outlined,
                      color: Colors.white54, size: 22),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Mesajını yaz...',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          const _QuickAction(emoji: '🌹', label: 'Gül'),
          const SizedBox(width: 10),
          const _QuickAction(emoji: '🎁', label: 'Hediye'),
          const SizedBox(width: 10),
          const _QuickAction(icon: Icons.more_horiz, label: 'Daha fazla'),
        ],
      ),
    );
  }

  static String _formatScore(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// =============================================================================
// Veri modelleri
// =============================================================================
class PkStreamer {
  const PkStreamer({
    required this.name,
    required this.fire,
    this.badgeEmoji = '',
    this.verified = false,
    this.imageUrl,
  });

  final String name;
  final String fire;
  final String badgeEmoji;
  final bool verified;
  final String? imageUrl;
}

class PkGiftEvent {
  const PkGiftEvent({
    required this.name,
    required this.action,
    required this.emoji,
    required this.count,
  });

  final String name;
  final String action;
  final String emoji;
  final int count;
}

class PkChatMessage {
  const PkChatMessage({
    required this.name,
    required this.text,
    this.crown = false,
    this.star = false,
    this.highlighted = false,
  });

  final String name;
  final String text;
  final bool crown;
  final bool star;
  final bool highlighted;
}

// =============================================================================
// Küçük yardımcı widget'lar
// =============================================================================
class _VideoPlaceholder extends StatelessWidget {
  const _VideoPlaceholder({required this.isLeft});

  final bool isLeft;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isLeft
              ? const [Color(0xFF3A2233), Color(0xFF1A1020)]
              : const [Color(0xFF1B2A3A), Color(0xFF101820)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.person, color: Colors.white24, size: 72),
      ),
    );
  }
}

class _RingAvatar extends StatelessWidget {
  const _RingAvatar({required this.ring, required this.size});

  final Color ring;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ring, width: 2),
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF2A2A35),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.person, color: Colors.white38, size: size * 0.55),
      ),
    );
  }
}

class _RankAvatar extends StatelessWidget {
  const _RankAvatar({
    required this.rank,
    required this.ring,
    required this.size,
  });

  final int rank;
  final Color ring;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size + 4,
      height: size + 8,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _RingAvatar(ring: ring, size: size),
          Positioned(
            bottom: 0,
            left: size / 2 - 7,
            child: Container(
              width: 15,
              height: 15,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ring,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1),
              ),
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VsEmblem extends StatelessWidget {
  const _VsEmblem();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 96,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFF2D6B).withValues(alpha: 0.5),
                const Color(0xFF2E9BFF).withValues(alpha: 0.5),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.6),
                blurRadius: 30,
                spreadRadius: 4,
              ),
            ],
          ),
        ),
        const Text(
          'VS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 42,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: 2,
            shadows: [
              Shadow(color: Color(0xFFFF2D6B), blurRadius: 12),
              Shadow(color: Color(0xFF2E9BFF), blurRadius: 12),
            ],
          ),
        ),
      ],
    );
  }
}

class _SendGiftButton extends StatelessWidget {
  const _SendGiftButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🌹', style: TextStyle(fontSize: 24)),
          SizedBox(height: 4),
          Text(
            'Gönder',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 66,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: filled
                  ? const Color(0xFFFF2D4B)
                  : Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: filled
                  ? null
                  : Border.all(color: Colors.white24, width: 1),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({this.emoji, this.icon, required this.label});

  final String? emoji;
  final IconData? icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 28,
          child: Center(
            child: emoji != null
                ? Text(emoji!, style: const TextStyle(fontSize: 24))
                : Icon(icon, color: Colors.white, size: 24),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10.5),
        ),
      ],
    );
  }
}

/// Yukarı süzülen kalpler — dekoratif, hafif animasyon.
class _FloatingHearts extends StatefulWidget {
  const _FloatingHearts({this.count = 5, this.height = 200});

  final int count;
  final double height;

  @override
  State<_FloatingHearts> createState() => _FloatingHeartsState();
}

class _FloatingHeartsState extends State<_FloatingHearts>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<double> _phases;
  late final List<double> _dx;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random(7);
    _phases = List.generate(widget.count, (_) => rnd.nextDouble());
    _dx = List.generate(widget.count, (_) => rnd.nextDouble() * 16 - 8);
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const colors = [
      Color(0xFFFF4D8D),
      Color(0xFFFF7AA8),
      Color(0xFFE91E63),
    ];
    return SizedBox(
      width: 30,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < widget.count; i++)
                _heart(i, colors[i % colors.length]),
            ],
          );
        },
      ),
    );
  }

  Widget _heart(int i, Color color) {
    final t = (_c.value + _phases[i]) % 1.0;
    final y = widget.height * (1 - t);
    final opacity = (t < 0.15 ? t / 0.15 : (t > 0.8 ? (1 - t) / 0.2 : 1.0))
        .clamp(0.0, 1.0);
    return Positioned(
      bottom: widget.height - y,
      left: 6 + _dx[i] + math.sin(t * math.pi * 3) * 4,
      child: Opacity(
        opacity: opacity,
        child: Icon(Icons.favorite, color: color, size: 18 + (i % 2) * 4),
      ),
    );
  }
}
