import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';

/// Takipçi yönetimi — Falcının fan listesi, takipçi seviyeleri, notifikasyon kontrol
class PsychicFollowersScreen extends ConsumerStatefulWidget {
  const PsychicFollowersScreen({super.key});

  @override
  ConsumerState<PsychicFollowersScreen> createState() =>
      _PsychicFollowersScreenState();
}

class _PsychicFollowersScreenState extends ConsumerState<PsychicFollowersScreen> {
  final List<Map<String, dynamic>> followers = [
    {
      'id': 'follower_001',
      'name': 'Aylin Şahin',
      'avatar': '👩',
      'followDate': '2025-01-15',
      'notificationsEnabled': true,
      'followerTier': 'premium',
      'sessions': 8,
      'spent': 480,
      'engagement': 92,
    },
    {
      'id': 'follower_002',
      'name': 'Elif Kara',
      'avatar': '👩',
      'followDate': '2024-12-10',
      'notificationsEnabled': true,
      'followerTier': 'diamond',
      'sessions': 12,
      'spent': 720,
      'engagement': 98,
    },
    {
      'id': 'follower_003',
      'name': 'Mehmet Yılmaz',
      'avatar': '👨',
      'followDate': '2025-01-20',
      'notificationsEnabled': false,
      'followerTier': 'standard',
      'sessions': 5,
      'spent': 220,
      'engagement': 65,
    },
    {
      'id': 'follower_004',
      'name': 'Zara Hasan',
      'avatar': '👩',
      'followDate': '2025-02-01',
      'notificationsEnabled': true,
      'followerTier': 'standard',
      'sessions': 3,
      'spent': 150,
      'engagement': 78,
    },
    {
      'id': 'follower_005',
      'name': 'Can Demir',
      'avatar': '👨',
      'followDate': '2025-01-28',
      'notificationsEnabled': true,
      'followerTier': 'premium',
      'sessions': 7,
      'spent': 420,
      'engagement': 88,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final totalFollowers = followers.length;
    final premiumFollowers =
        followers.where((f) => f['followerTier'] == 'premium').length;
    final diamondFollowers =
        followers.where((f) => f['followerTier'] == 'diamond').length;
    final avgEngagement =
        followers.isEmpty ? 0 : followers.map((f) => f['engagement'] as int).reduce((a, b) => a + b) / followers.length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Takipçiler'),
      ),
      body: DiscoverBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Cards
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
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatBox(
                          icon: Icons.people_outline,
                          label: 'Toplam',
                          value: '$totalFollowers',
                          color: AppThemeColors.accentCyan,
                        ),
                        _StatBox(
                          icon: Icons.diamond_outlined,
                          label: 'Diamond',
                          value: '$diamondFollowers',
                          color: Colors.amber,
                        ),
                        _StatBox(
                          icon: Icons.star_outline,
                          label: 'Premium',
                          value: '$premiumFollowers',
                          color: Colors.orange,
                        ),
                        _StatBox(
                          icon: Icons.show_chart_rounded,
                          label: 'Ort. Bağlılık',
                          value: '${avgEngagement.toStringAsFixed(0)}%',
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tier Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppThemeColors.accentCyan.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Takipçi Seviyeleri',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const _TierBadge(
                      tier: 'diamond',
                      description: 'Diamond: 50+ seans, %100 bağlılık',
                    ),
                    const SizedBox(height: 4),
                    const _TierBadge(
                      tier: 'premium',
                      description: 'Premium: 6+ seans, %80+ bağlılık',
                    ),
                    const SizedBox(height: 4),
                    const _TierBadge(
                      tier: 'standard',
                      description: 'Standard: 1+ seans',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Followers List
              const Text(
                'Takipçi Listesi',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              ...followers.map((follower) {
                return _FollowerCard(
                  follower: follower,
                  onNotificationToggle: () =>
                      _toggleNotifications(follower['id']),
                  onRemove: () => _removeFollower(follower['id']),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleNotifications(String followerId) {
    setState(() {
      final idx = followers.indexWhere((f) => f['id'] == followerId);
      if (idx >= 0) {
        followers[idx]['notificationsEnabled'] =
            !followers[idx]['notificationsEnabled'];
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bildirim ayarı güncellendi'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _removeFollower(String followerId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Takipçiyi Kaldır?'),
        content: const Text(
          'Bu takipçi engellenmeyecek, sadece takipçi listesinden kaldırılacak.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                followers.removeWhere((f) => f['id'] == followerId);
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Takipçi kaldırıldı'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Kaldır'),
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
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
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

class _TierBadge extends StatelessWidget {
  const _TierBadge({
    required this.tier,
    required this.description,
  });

  final String tier;
  final String description;

  Color get tierColor {
    switch (tier) {
      case 'diamond':
        return Colors.cyan;
      case 'premium':
        return Colors.orange;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 16,
          decoration: BoxDecoration(
            color: tierColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          description,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _FollowerCard extends StatelessWidget {
  const _FollowerCard({
    required this.follower,
    required this.onNotificationToggle,
    required this.onRemove,
  });

  final Map<String, dynamic> follower;
  final VoidCallback onNotificationToggle;
  final VoidCallback onRemove;

  Color get tierColor {
    switch (follower['followerTier']) {
      case 'diamond':
        return Colors.cyan;
      case 'premium':
        return Colors.orange;
      default:
        return Colors.white;
    }
  }

  String get tierLabel {
    switch (follower['followerTier']) {
      case 'diamond':
        return 'Diamond';
      case 'premium':
        return 'Premium';
      default:
        return 'Standard';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          border: Border.all(
            color: tierColor.withValues(alpha: 0.2),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  child: Center(
                    child: Text(
                      follower['avatar'],
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              follower['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: tierColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tierLabel,
                              style: TextStyle(
                                fontSize: 9,
                                color: tierColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Takipçi: ${follower['followDate']}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${follower['sessions']} seans',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    Text(
                      '${follower['spent']} jeton',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Bağlılık: ${follower['engagement']}%',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onNotificationToggle,
                    icon: Icon(
                      follower['notificationsEnabled']
                          ? Icons.notifications_active_outlined
                          : Icons.notifications_off_outlined,
                      size: 14,
                    ),
                    label: Text(
                      follower['notificationsEnabled']
                          ? 'Bildirim Açık'
                          : 'Bildirim Kapalı',
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close_outlined, size: 14),
                  label: const Text('Kaldır'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
