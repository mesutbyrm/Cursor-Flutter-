import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/ui/premium_2026/cosmic_galaxy_background.dart';
import 'package:canlifal_social/core/widgets/discover_background.dart';

class PsychicGamificationScreen extends ConsumerStatefulWidget {
  const PsychicGamificationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PsychicGamificationScreen> createState() =>
      _PsychicGamificationScreenState();
}

class _PsychicGamificationScreenState
    extends ConsumerState<PsychicGamificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DiscoverBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.black.withValues(alpha: 0.3),
          centerTitle: true,
          title: const Text(
            'Gamifikasyon',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppThemeColors.accentCyan,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Puanlar'),
              Tab(text: 'Görevler'),
              Tab(text: 'Liderlik'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _PointsTab(),
            _ChallengesTab(),
            _LeaderboardTab(),
          ],
        ),
      ),
    );
  }
}

class _PointsTab extends StatefulWidget {
  @override
  State<_PointsTab> createState() => _PointsTabState();
}

class _PointsTabState extends State<_PointsTab> {
  late List<Map<String, dynamic>> pointsHistory;

  @override
  void initState() {
    super.initState();
    pointsHistory = [
      {
        'title': '5 Yıldızlı Seans Tamamla',
        'points': 50,
        'icon': Icons.star_rounded,
        'color': Colors.amber,
        'date': '2024-02-20',
        'count': 12,
      },
      {
        'title': 'İlk Mesaj Cevapla',
        'points': 25,
        'icon': Icons.message_rounded,
        'color': Colors.blue,
        'date': '2024-02-20',
        'count': 3,
      },
      {
        'title': '10 Seans Tamamla',
        'points': 100,
        'icon': Icons.check_circle_rounded,
        'color': Colors.green,
        'date': '2024-02-19',
        'count': 2,
      },
      {
        'title': 'Rozet Aç',
        'points': 75,
        'icon': Icons.emoji_events_rounded,
        'color': Colors.purple,
        'date': '2024-02-18',
        'count': 1,
      },
      {
        'title': 'Profili Tamamla',
        'points': 30,
        'icon': Icons.person_rounded,
        'color': Colors.pink,
        'date': '2024-02-15',
        'count': 1,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    const totalPoints = 2850;
    const level = 12;
    const nextLevelPoints = 500;
    const currentLevelPoints = 350;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Level Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppThemeColors.accentCyan.withValues(alpha: 0.2),
                AppThemeColors.accentPurple.withValues(alpha: 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppThemeColors.accentCyan.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seviye $level',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'İleri',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Toplam Puan',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$totalPoints XP',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Sonraki Seviyeye',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        '$currentLevelPoints / $nextLevelPoints XP',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: currentLevelPoints / nextLevelPoints,
                      minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation(
                        AppThemeColors.accentCyan,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Rewards Available
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.card_giftcard_rounded, color: Colors.green, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hediyeleri Talep Et',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Text(
                      'Yeni seviyede 500 bonus puan kazandın',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Hediye talep edildi!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text('Talep Et',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Points History
        const Text(
          'Son Puanlar',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ...pointsHistory.map((item) => _buildPointsCard(item)),
      ],
    );
  }

  Widget _buildPointsCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (item['color'] as Color).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              item['icon'],
              color: item['color'],
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'],
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      item['date'],
                      style: TextStyle(fontSize: 10, color: Colors.white54),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        'x${item['count']}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '+${item['points']}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: (item['color'] as Color),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengesTab extends StatefulWidget {
  @override
  State<_ChallengesTab> createState() => _ChallengesTabState();
}

class _ChallengesTabState extends State<_ChallengesTab> {
  late List<Map<String, dynamic>> challenges;

  @override
  void initState() {
    super.initState();
    challenges = [
      {
        'title': 'Haftalık Çalışkan',
        'description': '7 gün üst üste çevrimiçi ol',
        'progress': 5,
        'total': 7,
        'reward': 150,
        'icon': Icons.calendar_today_rounded,
        'status': 'active',
      },
      {
        'title': 'Müşteri Odaklı',
        'description': 'Bu hafta 10 seans tamamla',
        'progress': 6,
        'total': 10,
        'reward': 200,
        'icon': Icons.people_rounded,
        'status': 'active',
      },
      {
        'title': 'Beş Yıldız Ustası',
        'description': 'Aynı gün 3 adet 5 yıldız al',
        'progress': 1,
        'total': 3,
        'reward': 175,
        'icon': Icons.star_rounded,
        'status': 'active',
      },
      {
        'title': 'Hızlı Yanıt',
        'description': '30 dakika içinde mesajı cevapla',
        'progress': 15,
        'total': 15,
        'reward': 100,
        'icon': Icons.flash_on_rounded,
        'status': 'completed',
      },
      {
        'title': 'Sosyal Kelebek',
        'description': '5 yeni takipçi kazanırırsan',
        'progress': 3,
        'total': 5,
        'reward': 125,
        'icon': Icons.favorite_rounded,
        'status': 'locked',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Aktif Görevler',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ...(challenges
            .where((c) => c['status'] == 'active')
            .toList()
            .map((challenge) => _buildChallengeCard(challenge))),
        const SizedBox(height: 24),
        const Text(
          'Tamamlananlar',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ...(challenges
            .where((c) => c['status'] == 'completed')
            .toList()
            .map((challenge) => _buildChallengeCard(challenge))),
      ],
    );
  }

  Widget _buildChallengeCard(Map<String, dynamic> challenge) {
    final isCompleted = challenge['status'] == 'completed';
    final isLocked = challenge['status'] == 'locked';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCompleted
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCompleted
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green.withValues(alpha: 0.2)
                      : AppThemeColors.accentCyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  challenge['icon'],
                  color: isCompleted
                      ? Colors.green
                      : AppThemeColors.accentCyan,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge['title'],
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      challenge['description'],
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCompleted)
                const Icon(Icons.check_circle_rounded,
                    color: Colors.green, size: 24)
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '+${challenge['reward']}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.amber,
                      ),
                    ),
                    const Text(
                      'XP',
                      style: TextStyle(fontSize: 9, color: Colors.white54),
                    ),
                  ],
                ),
            ],
          ),
          if (!isCompleted) ...[
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'İlerleme',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      '${challenge['progress']} / ${challenge['total']}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: challenge['progress'] / challenge['total'],
                    minHeight: 4,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation(
                      AppThemeColors.accentCyan,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LeaderboardTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Current Rank
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppThemeColors.accentPurple.withValues(alpha: 0.2),
                AppThemeColors.accentCyan.withValues(alpha: 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppThemeColors.accentPurple.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Senin Sıralaması',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '#27',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '2,850 XP · Ayda 142. ↑',
                    style: TextStyle(fontSize: 10, color: Colors.white54),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppThemeColors.accentCyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(
                        'https://api.dicebear.com/7.x/avataaars/svg?seed=You',
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Senin',
                      style: TextStyle(fontSize: 10, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Leaderboard
        const Text(
          'Global Liderlik Tablosu',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ...[
          ('Ayşe Akarlı', 6850, 1),
          ('Zeynep Çetin', 5420, 2),
          ('Fatma Yılmaz', 4950, 3),
          ('Melek Kaya', 3780, 4),
          ('Seda Gül', 3450, 5),
          ('Elif Demir', 3200, 6),
          ('Gamze İşler', 2950, 7),
          ('Hilal Uçar', 2880, 8),
          ('Senin Adın', 2850, 27),
        ].map((entry) => _buildLeaderboardRow(
              entry.$1,
              entry.$2,
              entry.$3,
              entry.$1 == 'Senin Adın',
            )),
      ],
    );
  }

  Widget _buildLeaderboardRow(
      String name, int xp, int rank, bool isCurrentUser) {
    Color rankColor;
    if (rank == 1) {
      rankColor = const Color(0xFFFFD700);
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0);
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32);
    } else {
      rankColor = Colors.white54;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppThemeColors.accentCyan.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrentUser
              ? AppThemeColors.accentCyan.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: rankColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$xp XP',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
          if (rank <= 3)
            Icon(
              Icons.emoji_events_rounded,
              color: rankColor,
              size: 20,
            )
          else
            Text(
              '+${6850 - xp} XP',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white54,
              ),
            ),
        ],
      ),
    );
  }
}
