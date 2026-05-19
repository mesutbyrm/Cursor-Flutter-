import 'package:flutter/material.dart';

import '../models/premium_live_stream.dart';
import '../models/premium_quick_action.dart';
import '../models/premium_tarot_offer.dart';
import '../models/premium_voice_room_sphere.dart';
import '../theme/premium_live_theme.dart';

abstract final class PremiumHomeDummyData {
  static const String userName = 'Cemre';

  static String _pic(String seed) =>
      'https://picsum.photos/seed/$seed/400/640';

  static String _face(String seed) =>
      'https://i.pravatar.cc/150?u=$seed';

  static List<PremiumLiveStream> get heroStreams => [
        PremiumLiveStream(
          id: '1',
          streamerName: 'Özge',
          categoryLabel: 'Müzik • Sohbet',
          viewers: 4892,
          imageUrl: _pic('canli_ozge'),
          avatarUrls: [_face('a1'), _face('a2'), _face('a3')],
        ),
        PremiumLiveStream(
          id: '2',
          streamerName: 'Ela',
          categoryLabel: 'Gece Yayını',
          viewers: 2310,
          imageUrl: _pic('canli_ela'),
          avatarUrls: [_face('b1'), _face('b2')],
        ),
        PremiumLiveStream(
          id: '3',
          streamerName: 'Arda',
          categoryLabel: 'Eğlence',
          viewers: 1204,
          imageUrl: _pic('canli_arda'),
          avatarUrls: [_face('c1'), _face('c2'), _face('c3'), _face('c4')],
        ),
      ];

  static List<PremiumQuickAction> get quickActions => const [
        PremiumQuickAction(
          title: 'Canlı Yayın Başlat',
          icon: Icons.videocam_rounded,
          gradientIndex: 0,
        ),
        PremiumQuickAction(
          title: 'Sesli Odaya Gir',
          icon: Icons.graphic_eq_rounded,
          gradientIndex: 1,
        ),
        PremiumQuickAction(
          title: 'Arkadaşlarını Davet Et',
          icon: Icons.group_add_rounded,
          gradientIndex: 2,
        ),
        PremiumQuickAction(
          title: 'Hediye Yolla',
          icon: Icons.card_giftcard_rounded,
          gradientIndex: 3,
        ),
        PremiumQuickAction(
          title: 'Jeton Yükle',
          icon: Icons.diamond_rounded,
          gradientIndex: 4,
        ),
      ];

  static List<PremiumVoiceRoomSphere> get voiceRooms => [
        PremiumVoiceRoomSphere(
          name: 'Müzik Keyfi',
          participants: 12,
          centerIcon: Icons.mic_rounded,
          glowColors: [PremiumLiveTheme.neonPink, PremiumLiveTheme.neonPurple],
          avatarUrls: [_face('v1'), _face('v2'), _face('v3')],
        ),
        PremiumVoiceRoomSphere(
          name: 'Gece Sohbeti',
          participants: 28,
          centerIcon: Icons.chat_bubble_rounded,
          glowColors: [PremiumLiveTheme.neonBlue, PremiumLiveTheme.neonPurple],
          avatarUrls: [_face('v4'), _face('v5')],
        ),
        PremiumVoiceRoomSphere(
          name: 'Yıldızların Altında',
          participants: 9,
          centerIcon: Icons.nightlight_round,
          glowColors: [PremiumLiveTheme.neonPurple, const Color(0xFFFFD700)],
          avatarUrls: [_face('v6'), _face('v7'), _face('v8')],
        ),
        PremiumVoiceRoomSphere(
          name: 'Kahve Molası',
          participants: 15,
          centerIcon: Icons.local_cafe_rounded,
          glowColors: [const Color(0xFF8D5524), PremiumLiveTheme.neonGold],
          avatarUrls: [_face('v9'), _face('v10')],
        ),
      ];

  static List<PremiumTarotOffer> get tarotOffers => [
        PremiumTarotOffer(
          title: 'Günlük Tarot',
          subtitle: 'Kartların bugünkü mesajı',
          icon: Icons.auto_fix_high_rounded,
          borderGradient: const LinearGradient(
            colors: [Color(0xFF4FACFE), PremiumLiveTheme.neonGold],
          ),
          cardGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A237E), Color(0xFF0D0221)],
          ),
        ),
        PremiumTarotOffer(
          title: 'Aşk Falı',
          subtitle: 'Kalp enerjisi ve uyum',
          icon: Icons.favorite_rounded,
          borderGradient: const LinearGradient(
            colors: [PremiumLiveTheme.neonPink, PremiumLiveTheme.neonPurple],
          ),
          cardGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4A0E4E), Color(0xFF12081E)],
          ),
        ),
        PremiumTarotOffer(
          title: 'Kahve Falı',
          subtitle: 'Fincandaki semboller',
          icon: Icons.local_cafe_rounded,
          borderGradient: const LinearGradient(
            colors: [Color(0xFF8D5524), PremiumLiveTheme.neonGold],
          ),
          cardGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3E2723), Color(0xFF0D0618)],
          ),
        ),
        PremiumTarotOffer(
          title: 'Kariyer Falı',
          subtitle: 'İş ve yol haritası',
          icon: Icons.star_rounded,
          borderGradient: const LinearGradient(
            colors: [PremiumLiveTheme.neonPurple, PremiumLiveTheme.neonBlue],
          ),
          cardGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF311B92), Color(0xFF050210)],
          ),
        ),
      ];
}
