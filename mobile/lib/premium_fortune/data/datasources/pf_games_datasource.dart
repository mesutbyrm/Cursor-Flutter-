import 'dart:math';

import '../../domain/entities/pf_games.dart';

class PfGamesDatasource {
  static const quests = [
    PfDailyQuest(
      id: 'q1',
      title: 'Günlük Fal',
      description: 'Bugün bir fal baktır',
      rewardCredits: 10,
      isCompleted: false,
    ),
    PfDailyQuest(
      id: 'q2',
      title: 'Reklam İzle',
      description: '1 reklam izleyerek kredi kazan',
      rewardCredits: 5,
      isCompleted: false,
    ),
    PfDailyQuest(
      id: 'q3',
      title: 'Falcıyla Sohbet',
      description: 'Bir falcıya mesaj gönder',
      rewardCredits: 8,
      isCompleted: false,
    ),
  ];

  static const badges = [
    PfBadge(
      id: 'b1',
      name: 'İlk Fal',
      description: 'İlk falınızı baktırdınız',
      icon: '🔮',
      isUnlocked: true,
    ),
    PfBadge(
      id: 'b2',
      name: 'Tarot Ustası',
      description: '10 tarot okuması yaptınız',
      icon: '🃏',
    ),
    PfBadge(
      id: 'b3',
      name: 'Şanslı Yıldız',
      description: 'Çarkta 50+ kredi kazandınız',
      icon: '⭐',
    ),
    PfBadge(
      id: 'b4',
      name: 'VIP Mistik',
      description: '500+ kredi harcadınız',
      icon: '👑',
    ),
  ];

  Future<List<PfDailyQuest>> getDailyQuests(String userId) async => quests;

  Future<void> completeQuest(String userId, String questId) async {}

  Future<int> spinWheel(String userId) async {
    final rewards = [5, 10, 15, 20, 25, 50, 5, 10];
    return rewards[Random().nextInt(rewards.length)];
  }

  Future<int> watchAdForCredits(String userId) async => 5;

  Future<List<PfBadge>> getBadges(String userId) async => badges;
}
