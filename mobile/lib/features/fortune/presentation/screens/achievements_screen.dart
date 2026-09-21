import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/achievements_provider.dart';

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen>
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Başarılar & Serileri'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Genel Bakış'),
            Tab(text: 'Başarılar'),
            Tab(text: 'Seviye'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildAchievementsTab(),
          _buildLevelTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Consumer(
      builder: (context, ref, child) {
        final streakAsync = ref.watch(userStreakProvider);

        return streakAsync.when(
          data: (streak) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Streak card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Text(
                          'Günlük Serim',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              '🔥',
                              style: TextStyle(fontSize: 48),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${streak.currentStreak} gün',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'En iyi: ${streak.bestStreak} gün',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Toplam okumalar: ${streak.totalReadingsInStreak}',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Milestones
                const Text(
                  'Hedefler',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...streak.milestones.map((m) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: Text(
                        m.locked ? '🔒' : '🏆',
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text('${m.streakDays} Günlük Seri'),
                      subtitle: m.achievedAt != null
                          ? Text(
                              'Başarıldı: ${DateFormat('d MMMM', 'tr_TR').format(m.achievedAt!)}',
                            )
                          : const Text('Kilitli'),
                      trailing: m.locked
                          ? null
                          : const Icon(Icons.check_circle, color: Colors.green),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Hata: $err')),
        );
      },
    );
  }

  Widget _buildAchievementsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final achievementsAsync = ref.watch(
          achievementsProvider((limit: 20, offset: 0)),
        );

        return achievementsAsync.when(
          data: (achievements) => GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              return GestureDetector(
                onTap: () => _showAchievementDetail(context, achievement),
                child: Card(
                  color: achievement.unlocked ? null : Colors.grey[300],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        achievement.icon,
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        achievement.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!achievement.unlocked)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${achievement.progress}/${achievement.maxProgress}',
                            style: const TextStyle(fontSize: 8),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Hata: $err')),
        );
      },
    );
  }

  Widget _buildLevelTab() {
    return Consumer(
      builder: (context, ref, child) {
        final levelAsync = ref.watch(userLevelProvider);

        return levelAsync.when(
          data: (level) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          'Seviye ${level.level}',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          level.levelName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: level.levelProgress / 100,
                            minHeight: 12,
                            backgroundColor: Colors.grey[300],
                            valueColor:
                                const AlwaysStoppedAnimation(Colors.cyan),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${level.currentXP} / ${level.currentXP + level.xpNeeded} XP',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // XP breakdown
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _buildXPCard('Okumalar', level.currentXP),
                            _buildXPCard('Paylaşımlar', level.currentXP ~/ 2),
                            _buildXPCard('Beğeniler', level.currentXP ~/ 4),
                            _buildXPCard('Doğruluk', level.currentXP ~/ 4),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Hata: $err')),
        );
      },
    );
  }

  Widget _buildXPCard(String label, int value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.cyan[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.cyan,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  void _showAchievementDetail(BuildContext context, Achievement achievement) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              achievement.icon,
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              achievement.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              achievement.description,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (!achievement.unlocked)
              LinearProgressIndicator(
                value: achievement.progress / achievement.maxProgress,
                minHeight: 8,
              ),
            const SizedBox(height: 16),
            Chip(
              label: Text('${achievement.points} Puan'),
              backgroundColor: Colors.amber[100],
            ),
            const SizedBox(height: 16),
            if (achievement.unlocked)
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kapat'),
              ),
          ],
        ),
      ),
    );
  }
}
