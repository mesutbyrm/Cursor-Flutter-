import 'package:equatable/equatable.dart';

import '../../../home/domain/entities/home_game_entity.dart';
import 'profile_stats_entity.dart';

class GrowthProgressEntity extends Equatable {
  const GrowthProgressEntity({
    required this.level,
    required this.xp,
    required this.currentLevelXp,
    required this.nextLevelXp,
    required this.tasks,
    required this.badges,
    required this.dailyRewards,
  });

  factory GrowthProgressEntity.fromSignals({
    required ProfileStatsEntity stats,
    required List<DailyRewardEntity> dailyRewards,
    int jeton = 0,
    int cfc = 0,
    int invitedCount = 0,
    bool hasPremium = false,
  }) {
    final claimedRewards = dailyRewards.where((r) => r.claimed).length;
    final xp = (stats.likes * 2) +
        (stats.followers * 12) +
        (stats.following * 3) +
        (stats.liveStreams * 80) +
        (stats.giftsReceivedCount * 30) +
        (stats.giftsReceivedCoins ~/ 5) +
        (jeton ~/ 20) +
        (cfc ~/ 10) +
        (invitedCount * 120) +
        (claimedRewards * 50);
    final level = xp ~/ xpPerLevel + 1;
    final currentLevelXp = (level - 1) * xpPerLevel;
    final nextLevelXp = level * xpPerLevel;
    final dailyReward = dailyRewards.isNotEmpty ? dailyRewards.first : null;

    return GrowthProgressEntity(
      level: level,
      xp: xp,
      currentLevelXp: currentLevelXp,
      nextLevelXp: nextLevelXp,
      dailyRewards: dailyRewards,
      tasks: [
        GrowthTaskEntity(
          id: 'daily-login',
          title: 'Günlük giriş ödülünü topla',
          description: dailyReward?.description ??
              'Her gün giriş yap, seri devam ettikçe Jeton fırsatlarını kaçırma.',
          current: dailyReward?.claimed == true ? 1 : 0,
          target: 1,
          rewardLabel: dailyReward != null && dailyReward.rewardJeton > 0
              ? '+${dailyReward.rewardJeton} Jeton'
              : '+50 XP',
          route: dailyReward?.route ?? '/feed',
          icon: '🎁',
        ),
        GrowthTaskEntity(
          id: 'voice-room',
          title: 'Bir sesli odaya katıl',
          description: 'Sohbet odalarında görünür ol, arkadaş çevreni büyüt.',
          current: stats.following > 0 ? 1 : 0,
          target: 1,
          rewardLabel: '+60 XP',
          route: '/voice-rooms',
          icon: '🎙️',
        ),
        GrowthTaskEntity(
          id: 'live-discovery',
          title: 'Canlı yayınları keşfet',
          description: 'Yayınlara katıl, beğeni ve hediye etkileşimini artır.',
          current: stats.liveStreams > 0 ? 1 : 0,
          target: 1,
          rewardLabel: '+80 XP',
          route: '/live',
          icon: '📺',
        ),
        GrowthTaskEntity(
          id: 'invite-friend',
          title: 'Arkadaş davet et',
          description: 'Davet bağlantını paylaş, topluluğa yeni kullanıcı kazandır.',
          current: invitedCount,
          target: 1,
          rewardLabel: '+120 XP',
          route: '/invite-friends',
          icon: '🤝',
        ),
        GrowthTaskEntity(
          id: 'social-profile',
          title: 'Profil etkileşimini büyüt',
          description: 'Takipçi, beğeni ve sosyal etkileşimlerin seviyeni yükseltir.',
          current: stats.followers,
          target: 10,
          rewardLabel: '+120 XP',
          route: '/profile',
          icon: '✨',
        ),
        GrowthTaskEntity(
          id: 'gift-collection',
          title: 'Hediye koleksiyonunu genişlet',
          description: 'Aldığın hediyeler rozet ve seviye ilerlemesine katkı verir.',
          current: stats.giftsReceivedCount,
          target: 3,
          rewardLabel: '+90 XP',
          route: '/profile/gifts',
          icon: '💎',
        ),
      ],
      badges: [
        GrowthBadgeEntity(
          id: 'first-step',
          title: 'İlk Adım',
          description: '100 XP eşiğini geç.',
          unlocked: xp >= 100,
          icon: '🌟',
        ),
        GrowthBadgeEntity(
          id: 'social-spark',
          title: 'Sosyal Kıvılcım',
          description: '10 takipçi veya takip edilen kullanıcıya ulaş.',
          unlocked: stats.followers >= 10 || stats.following >= 10,
          icon: '💬',
        ),
        GrowthBadgeEntity(
          id: 'broadcaster',
          title: 'Yayıncı',
          description: 'İlk canlı yayın aktiviteni tamamla.',
          unlocked: stats.liveStreams > 0,
          icon: '📡',
        ),
        GrowthBadgeEntity(
          id: 'gift-hunter',
          title: 'Hediye Avcısı',
          description: '3 hediye koleksiyonuna ulaş.',
          unlocked: stats.giftsReceivedCount >= 3,
          icon: '🎁',
        ),
        GrowthBadgeEntity(
          id: 'inviter',
          title: 'Davetçi',
          description: 'En az 1 arkadaşını Canlifal topluluğuna davet et.',
          unlocked: invitedCount > 0,
          icon: '🫶',
        ),
        GrowthBadgeEntity(
          id: 'vip-path',
          title: 'VIP Yolcusu',
          description: 'Aktif premium/VIP üyelik avantajlarını kullan.',
          unlocked: hasPremium,
          icon: '👑',
        ),
      ],
    );
  }

  static const int xpPerLevel = 500;

  final int level;
  final int xp;
  final int currentLevelXp;
  final int nextLevelXp;
  final List<GrowthTaskEntity> tasks;
  final List<GrowthBadgeEntity> badges;
  final List<DailyRewardEntity> dailyRewards;

  double get levelProgress {
    final span = nextLevelXp - currentLevelXp;
    if (span <= 0) return 0;
    return ((xp - currentLevelXp) / span).clamp(0, 1).toDouble();
  }

  int get unlockedBadgeCount => badges.where((b) => b.unlocked).length;

  int get completedTaskCount => tasks.where((t) => t.isComplete).length;

  @override
  List<Object?> get props => [
        level,
        xp,
        currentLevelXp,
        nextLevelXp,
        tasks,
        badges,
        dailyRewards,
      ];

}

class GrowthTaskEntity extends Equatable {
  const GrowthTaskEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.current,
    required this.target,
    required this.rewardLabel,
    required this.route,
    required this.icon,
  });

  final String id;
  final String title;
  final String description;
  final int current;
  final int target;
  final String rewardLabel;
  final String route;
  final String icon;

  bool get isComplete => current >= target;

  double get progress {
    if (target <= 0) return 0;
    return (current / target).clamp(0, 1).toDouble();
  }

  String get progressLabel => '${current.clamp(0, target)}/$target';

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        current,
        target,
        rewardLabel,
        route,
        icon,
      ];
}

class GrowthBadgeEntity extends Equatable {
  const GrowthBadgeEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.unlocked,
    required this.icon,
  });

  final String id;
  final String title;
  final String description;
  final bool unlocked;
  final String icon;

  @override
  List<Object?> get props => [id, title, description, unlocked, icon];
}
