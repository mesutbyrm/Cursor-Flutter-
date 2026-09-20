import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';

/// Sertifikalar & Rozetler — Milestone, ödüller, başarılar
class PsychicBadgesScreen extends ConsumerWidget {
  const PsychicBadgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badges = [
      {
        'icon': '⭐',
        'title': 'Yıldız Falcı',
        'description': 'İlk 100 seansı tamamla',
        'unlocked': true,
        'unlockedDate': '2026-07-15',
        'rarity': 'common',
      },
      {
        'icon': '🎯',
        'title': 'Doğru Hedef',
        'description': '95%+ yanıt hızını koru',
        'unlocked': true,
        'unlockedDate': '2026-08-20',
        'rarity': 'uncommon',
      },
      {
        'icon': '🏆',
        'title': 'Şampiyonluk',
        'description': '200+ beş yıldızlı yorum al',
        'unlocked': true,
        'unlockedDate': '2026-09-10',
        'rarity': 'rare',
      },
      {
        'icon': '💎',
        'title': 'Elmas Hizmet',
        'description': 'Ayda 500+ saat seans yap',
        'unlocked': false,
        'unlockedDate': null,
        'rarity': 'epic',
      },
      {
        'icon': '🔥',
        'title': 'Sıcak Trend',
        'description': '7 gün üst üste çevrimiçi ol',
        'unlocked': true,
        'unlockedDate': '2026-09-18',
        'rarity': 'uncommon',
      },
      {
        'icon': '👑',
        'title': 'Taç Sahibi',
        'description': 'Kategori liderliği kazanıldı',
        'unlocked': false,
        'unlockedDate': null,
        'rarity': 'legendary',
      },
      {
        'icon': '🌟',
        'title': 'Işıltı',
        'description': '1000+ takipçiye ulaş',
        'unlocked': false,
        'unlockedDate': null,
        'rarity': 'epic',
      },
      {
        'icon': '🎁',
        'title': 'Hediye Sevgilisi',
        'description': '100+ hediye al',
        'unlocked': true,
        'unlockedDate': '2026-08-30',
        'rarity': 'uncommon',
      },
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: Column(
          children: [
            SizedBox(height: MediaQuery.paddingOf(context).top + 4),
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 12),
              child: Row(
                children: [
                  DiscoverIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: () => context.pop(),
                  ),
                  const Expanded(
                    child: DiscoverTabHeader(
                      title: 'Sertifikalar & Rozetler',
                      subtitle: 'Başarılarını göster',
                    ),
                  ),
                  DiscoverIconButton(
                    icon: Icons.emoji_events_rounded,
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Rozet koleksiyonunu paylaş'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  // İstatistikler
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                '5',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 24,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Açılmış',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                '3',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 24,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Yakında',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Açılmış Rozetler
                  const Text(
                    'Açılmış Rozetler',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: badges.where((b) => b['unlocked'] == true).length,
                    itemBuilder: (context, index) {
                      final unlockedBadges =
                          badges.where((b) => b['unlocked'] == true).toList();
                      final badge = unlockedBadges[index];
                      return _BadgeCard(badge: badge);
                    },
                  ),
                  const SizedBox(height: 20),

                  // Kilitli Rozetler
                  const Text(
                    'Hedef Rozetleri',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: badges.where((b) => b['unlocked'] == false).length,
                    itemBuilder: (context, index) {
                      final lockedBadges =
                          badges.where((b) => b['unlocked'] == false).toList();
                      final badge = lockedBadges[index];
                      return _BadgeCard(badge: badge, locked: true);
                    },
                  ),
                  const SizedBox(height: 20),

                  // Rozet Açıklaması
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppThemeColors.accentCyan.withValues(alpha: 0.1),
                      border: Border.all(
                        color: AppThemeColors.accentCyan.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rozet Seviyeleri',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppThemeColors.accentCyan,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _RarityInfo(
                          label: 'Yaygın',
                          color: Colors.grey,
                          count: 2,
                        ),
                        const SizedBox(height: 6),
                        _RarityInfo(
                          label: 'Nadir',
                          color: Colors.green,
                          count: 2,
                        ),
                        const SizedBox(height: 6),
                        _RarityInfo(
                          label: 'Çok Nadir',
                          color: Colors.blue,
                          count: 2,
                        ),
                        const SizedBox(height: 6),
                        _RarityInfo(
                          label: 'Efsanevi',
                          color: Colors.purple,
                          count: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Başarı Tarihleri
                  const Text(
                    'Son Açılmış',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...badges
                      .where((b) => b['unlocked'] == true)
                      .toList()
                      .take(3)
                      .map(
                        (badge) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  badge['icon'] as String,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        badge['title'] as String,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Açıldı: ${badge['unlockedDate']}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.white.withValues(alpha: 0.5),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({
    required this.badge,
    this.locked = false,
  });

  final Map<String, dynamic> badge;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final title = badge['title'] as String;
        final description = badge['description'] as String;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title\n$description')),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: locked
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getRarityColor(badge['rarity'] as String)
                .withValues(alpha: locked ? 0.1 : 0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (locked)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  size: 20,
                  color: Colors.white70,
                ),
              )
            else
              Text(
                badge['icon'] as String,
                style: const TextStyle(fontSize: 32),
              ),
            const SizedBox(height: 8),
            Text(
              badge['title'] as String,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 10,
                color: locked ? Colors.white54 : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case 'common':
        return Colors.grey;
      case 'uncommon':
        return Colors.green;
      case 'rare':
        return Colors.blue;
      case 'epic':
        return Colors.purple;
      case 'legendary':
        return Colors.orange;
      default:
        return Colors.white;
    }
  }
}

class _RarityInfo extends StatelessWidget {
  const _RarityInfo({
    required this.label,
    required this.color,
    required this.count,
  });

  final String label;
  final Color color;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
        const Spacer(),
        Text(
          '$count rozet',
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
