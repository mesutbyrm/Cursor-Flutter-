import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Site içi tanıtım (AdMob reklamı yoksa): sesli odalar, canlı yayınlar,
/// sosyal paylaşım, jeton, CFC ve Gold/Premium üyelik.
class HousePromo {
  const HousePromo({
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.route,
    required this.icon,
    required this.colors,
    this.emoji = '',
  });

  final String title;
  final String subtitle;
  final String cta;
  final String route;
  final IconData icon;
  final List<Color> colors;
  final String emoji;
}

const housePromos = <HousePromo>[
  HousePromo(
    title: 'Sesli Odalara Katıl',
    subtitle: 'Sohbet et, şarkı söyle, hediye gönder. Yüzlerce oda şu an açık!',
    cta: 'Odalara git',
    route: '/voice-rooms',
    icon: Icons.mic_rounded,
    emoji: '🎙️',
    colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
  ),
  HousePromo(
    title: 'Canlı Yayınları İzle',
    subtitle: 'Canlı falcılar ve yayıncılar seni bekliyor. Hemen katıl!',
    cta: 'Canlıları gör',
    route: '/live',
    icon: Icons.videocam_rounded,
    emoji: '🔴',
    colors: [Color(0xFFFE2C55), Color(0xFFFF8A00)],
  ),
  HousePromo(
    title: 'Gold Üyelik',
    subtitle: 'Özel çerçeveler, isim efektleri, Kim Baktı ve daha fazlası.',
    cta: 'Gold ol',
    route: '/premium-membership?plan=gold',
    icon: Icons.workspace_premium_rounded,
    emoji: '👑',
    colors: [Color(0xFFF59E0B), Color(0xFFB45309)],
  ),
  HousePromo(
    title: 'Jeton Yükle',
    subtitle: 'Sevdiğin yayıncıya hediye gönder, öne çık. Avantajlı paketler!',
    cta: 'Jeton al',
    route: '/jeton-store',
    icon: Icons.toll_rounded,
    emoji: '💎',
    colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
  ),
  HousePromo(
    title: 'Paylaş, Keşfedil',
    subtitle: 'Fotoğraf, video veya falını paylaş; GirLive Keşfet\'e çık!',
    cta: 'Paylaşım yap',
    route: '/social/create',
    icon: Icons.add_a_photo_rounded,
    emoji: '✨',
    colors: [Color(0xFF25F4EE), Color(0xFF0EA5E9)],
  ),
  HousePromo(
    title: 'CFC ile Fal Baktır',
    subtitle: 'Tarot, kahve, aşk falı… CFC ile tüm fallar bir dokunuşta.',
    cta: 'CFC al',
    route: '/cfc-store',
    icon: Icons.auto_awesome_rounded,
    emoji: '🔮',
    colors: [Color(0xFF6D28D9), Color(0xFFDB2777)],
  ),
  HousePromo(
    title: 'Premium & Diamond',
    subtitle: 'En görkemli efektler, öncelikli destek ve özel rozetler.',
    cta: 'Planları gör',
    route: '/premium-membership',
    icon: Icons.diamond_rounded,
    emoji: '💠',
    colors: [Color(0xFF22D3EE), Color(0xFF6366F1)],
  ),
];

HousePromo housePromoFor(int seed) => housePromos[seed.abs() % housePromos.length];

/// Alt sekme (shell) rotaları `go`, diğerleri `push` ile açılır.
void openHousePromo(BuildContext context, HousePromo promo) {
  if (promo.route == '/live' || promo.route == '/social') {
    context.go(promo.route);
  } else {
    context.push(promo.route);
  }
}

/// Tam ekran site reklamı.
class SocialHouseAdPage extends StatelessWidget {
  const SocialHouseAdPage({
    super.key,
    required this.promo,
    required this.topInset,
    required this.bottomInset,
  });

  final HousePromo promo;
  final double topInset;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [promo.colors.first, const Color(0xFF0B0B12), promo.colors.last],
          stops: const [0, 0.55, 1],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(28, topInset + 70, 28, bottomInset + 40),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Sponsorlu · GirLive',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const Spacer(),
            Container(
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: promo.colors),
                boxShadow: [
                  BoxShadow(
                    color: promo.colors.first.withValues(alpha: 0.6),
                    blurRadius: 48,
                    spreadRadius: 4,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(promo.emoji, style: const TextStyle(fontSize: 64)),
            ),
            const SizedBox(height: 30),
            Text(
              promo.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              promo.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 16,
                height: 1.4,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: promo.colors),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextButton.icon(
                  onPressed: () => openHousePromo(context, promo),
                  icon: Icon(promo.icon, color: Colors.white),
                  label: Text(
                    promo.cta,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Kaydırarak devam et',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// Keşfet ızgarası için küçük tanıtım kutusu.
class SocialHouseAdTile extends StatelessWidget {
  const SocialHouseAdTile({super.key, required this.promo});

  final HousePromo promo;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openHousePromo(context, promo),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: promo.colors,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sponsorlu',
                  style: TextStyle(color: Colors.white70, fontSize: 9)),
              const Spacer(),
              Text(promo.emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 4),
              Text(
                promo.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
