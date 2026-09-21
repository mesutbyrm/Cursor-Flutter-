import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';

/// Başarı rozetleri — Falcının kazandığı rozetler ve hedef rozetler
class PsychicBadgesScreen extends ConsumerStatefulWidget {
  const PsychicBadgesScreen({super.key});

  @override
  ConsumerState<PsychicBadgesScreen> createState() =>
      _PsychicBadgesScreenState();
}

class _PsychicBadgesScreenState extends ConsumerState<PsychicBadgesScreen> {
  final List<Map<String, dynamic>> unlockedBadges = [
    {
      'id': 'badge_001',
      'title': 'Sertifikalı Falcı',
      'emoji': '📜',
      'rarity': 'epic',
      'description': 'Başvuru onayı ve sertifikasyon',
      'unlockedDate': '2024-12-01',
      'progress': 100,
    },
    {
      'id': 'badge_002',
      'title': 'Aylık Top 5',
      'emoji': '⭐',
      'rarity': 'legendary',
      'description': 'Bu ay en popüler 5 falcı arasında',
      'unlockedDate': '2025-02-10',
      'progress': 100,
    },
    {
      'id': 'badge_003',
      'title': 'Hızlı Yanıtlı',
      'emoji': '⚡',
      'rarity': 'rare',
      'description': 'Ortalama yanıt süresi < 2 dakika',
      'unlockedDate': '2025-01-15',
      'progress': 100,
    },
    {
      'id': 'badge_004',
      'title': '100 Seans Ustası',
      'emoji': '🎯',
      'rarity': 'rare',
      'description': '100+ tamamlanmış seans',
      'unlockedDate': '2025-01-05',
      'progress': 100,
    },
    {
      'id': 'badge_005',
      'title': 'Takipçi Magneți',
      'emoji': '❤️',
      'rarity': 'uncommon',
      'description': '50+ aktif takipçi',
      'unlockedDate': '2025-02-03',
      'progress': 100,
    },
  ];

  final List<Map<String, dynamic>> targetBadges = [
    {
      'id': 'badge_101',
      'title': 'Aylık Çift Top',
      'emoji': '👑',
      'rarity': 'legendary',
      'description': 'Iki ay üst üste top 5',
      'progress': 75,
      'requirement': '2 ay top 5',
    },
    {
      'id': 'badge_102',
      'title': '1000 Jeton Kazanç',
      'emoji': '💰',
      'rarity': 'epic',
      'description': 'Toplam 1000+ jeton kazanç',
      'progress': 82,
      'requirement': '1000 jeton',
    },
    {
      'id': 'badge_103',
      'title': 'Mükemmel Hizmet',
      'emoji': '✨',
      'rarity': 'epic',
      'description': '20 seans, tümü 5 yıldız',
      'progress': 95,
      'requirement': '20x 5⭐',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final totalBadges = unlockedBadges.length;
    final lockedBadges = targetBadges.length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Başarı Rozetleri'),
      ),
      body: DiscoverBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  border: Border.all(
                    color: AppThemeColors.accentCyan.withValues(alpha: 0.2),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatBox(
                      icon: Icons.workspace_premium_outlined,
                      label: 'Açılmış',
                      value: '$totalBadges',
                      color: Colors.amber,
                    ),
                    _StatBox(
                      icon: Icons.lock_outline,
                      label: 'Hedef',
                      value: '$lockedBadges',
                      color: AppThemeColors.accentCyan,
                    ),
                    _StatBox(
                      icon: Icons.percent_outlined,
                      label: 'İlerleme',
                      value: '${((totalBadges / (totalBadges + lockedBadges)) * 100).toStringAsFixed(0)}%',
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Unlocked Badges
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
                  crossAxisCount: 2,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: unlockedBadges.length,
                itemBuilder: (context, index) {
                  final badge = unlockedBadges[index];
                  return _BadgeCard(
                    badge: badge,
                    onTap: () => _showBadgeDetails(badge),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Target Badges
              const Text(
                'Hedef Rozetler',
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
                  crossAxisCount: 2,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: targetBadges.length,
                itemBuilder: (context, index) {
                  final badge = targetBadges[index];
                  return _TargetBadgeCard(
                    badge: badge,
                    onTap: () => _showBadgeDetails(badge),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Rarity Info
              const Text(
                'Rarity Seviyeleri',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              ..._getRarityLevels().map((rarity) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _RarityInfo(rarity: rarity),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getRarityLevels() {
    return [
      {
        'name': 'Common',
        'color': Colors.grey,
        'description': 'Kolay ulaşılabilir, çoğu oyuncu buna sahip',
      },
      {
        'name': 'Uncommon',
        'color': Colors.green,
        'description': 'Biraz daha zor, fark yaratıyor',
      },
      {
        'name': 'Rare',
        'color': Colors.blue,
        'description': 'Nadir, özel çaba gerekli',
      },
      {
        'name': 'Epic',
        'color': Colors.purple,
        'description': 'Çok nadir, yüksek başarı gerekli',
      },
      {
        'name': 'Legendary',
        'color': Colors.amber,
        'description': 'En nadir, ustalar için',
      },
    ];
  }

  void _showBadgeDetails(Map<String, dynamic> badge) {
    final isLocked = badge['progress'] != null && (badge['progress'] as int) < 100;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Text(
              badge['emoji'],
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(badge['title']),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                badge['description'],
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              if (isLocked) ...[
                const Text(
                  'İlerleme',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${badge['progress']}%',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Gereklilik: ${badge['requirement']}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (badge['progress'] as int) / 100,
                        minHeight: 6,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation(
                          AppThemeColors.accentCyan,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outlined,
                          color: Colors.green, size: 20),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Açılmış',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            'Tarih: ${badge['unlockedDate']}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _RarityBadge(rarity: badge['rarity']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({
    required this.badge,
    required this.onTap,
  });

  final Map<String, dynamic> badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: _getGradientForRarity(badge['rarity']),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getBorderColorForRarity(badge['rarity']),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  _getBorderColorForRarity(badge['rarity']).withValues(alpha: 0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              badge['emoji'],
              style: const TextStyle(fontSize: 36),
            ),
            const SizedBox(height: 8),
            Text(
              badge['title'],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            _RarityBadge(rarity: badge['rarity']),
          ],
        ),
      ),
    );
  }
}

class _TargetBadgeCard extends StatelessWidget {
  const _TargetBadgeCard({
    required this.badge,
    required this.onTap,
  });

  final Map<String, dynamic> badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = badge['progress'] as int;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  badge['emoji'],
                  style: TextStyle(
                    fontSize: 28,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  badge['title'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress / 100,
                          minHeight: 3,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation(
                            _getBorderColorForRarity(badge['rarity']),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$progress%',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  size: 12,
                  color: Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RarityBadge extends StatelessWidget {
  const _RarityBadge({required this.rarity});

  final String rarity;

  @override
  Widget build(BuildContext context) {
    final color = _getBorderColorForRarity(rarity);
    final label = rarity[0].toUpperCase() + rarity.substring(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _RarityInfo extends StatelessWidget {
  const _RarityInfo({required this.rarity});

  final Map<String, dynamic> rarity;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 16,
          decoration: BoxDecoration(
            color: rarity['color'],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rarity['name'],
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              Text(
                rarity['description'],
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Gradient _getGradientForRarity(String rarity) {
  switch (rarity) {
    case 'legendary':
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.amber.withValues(alpha: 0.3),
          Colors.orange.withValues(alpha: 0.2),
        ],
      );
    case 'epic':
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.purple.withValues(alpha: 0.25),
          Colors.indigo.withValues(alpha: 0.15),
        ],
      );
    case 'rare':
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.blue.withValues(alpha: 0.25),
          Colors.cyan.withValues(alpha: 0.15),
        ],
      );
    case 'uncommon':
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.green.withValues(alpha: 0.25),
          Colors.teal.withValues(alpha: 0.15),
        ],
      );
    default:
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.grey.withValues(alpha: 0.25),
          Colors.blueGrey.withValues(alpha: 0.15),
        ],
      );
  }
}

Color _getBorderColorForRarity(String rarity) {
  switch (rarity) {
    case 'legendary':
      return Colors.amber;
    case 'epic':
      return Colors.purple;
    case 'rare':
      return Colors.blue;
    case 'uncommon':
      return Colors.green;
    default:
      return Colors.grey;
  }
}
