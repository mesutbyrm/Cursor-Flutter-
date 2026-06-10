import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Liderlik tablosu periyodu.
enum LeaderboardPeriod {
  daily('daily', 'Günlük'),
  weekly('weekly', 'Haftalık'),
  monthly('monthly', 'Aylık');

  const LeaderboardPeriod(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

/// Oyun merkezi bölüm türü.
enum GameCenterSection {
  popular,
  live,
  rewarded,
}

/// Tek bir oyun kartı tanımı.
class GameCenterItem extends Equatable {
  const GameCenterItem({
    required this.id,
    required this.title,
    required this.section,
    required this.icon,
    required this.gradient,
    required this.route,
    this.subtitle,
    this.jetonCost = 0,
    this.badge,
    this.liveCount,
    this.heroTag,
  });

  final String id;
  final String title;
  final String? subtitle;
  final GameCenterSection section;
  final IconData icon;
  final List<Color> gradient;
  final String route;
  final int jetonCost;
  final String? badge;
  final int? liveCount;
  final String? heroTag;

  @override
  List<Object?> get props => [
    id,
    title,
    subtitle,
    section,
    route,
    jetonCost,
    badge,
    liveCount,
  ];
}

/// Liderlik satırı.
class LeaderboardEntry extends Equatable {
  const LeaderboardEntry({
    required this.id,
    required this.name,
    required this.score,
    this.rank,
    this.avatarUrl,
    this.isCurrentUser = false,
  });

  final String id;
  final String name;
  final int score;
  final int? rank;
  final String? avatarUrl;
  final bool isCurrentUser;

  @override
  List<Object?> get props => [id, name, score, rank, avatarUrl, isCurrentUser];
}

/// Oyun sonucu kaydı.
class GameResultPayload extends Equatable {
  const GameResultPayload({
    required this.gameId,
    required this.score,
    this.won = false,
    this.jetonDelta = 0,
    this.metadata = const {},
  });

  final String gameId;
  final int score;
  final bool won;
  final int jetonDelta;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => {
    'gameId': gameId,
    'score': score,
    'won': won,
    if (jetonDelta != 0) 'jetonDelta': jetonDelta,
    ...metadata,
  };

  @override
  List<Object?> get props => [gameId, score, won, jetonDelta, metadata];
}

/// Oyun merkezi statik katalog.
abstract final class GameCenterCatalog {
  static const purple = Color(0xFF8B5CF6);
  static const pink = Color(0xFFEC4899);
  static const orange = Color(0xFFF59E0B);
  static const green = Color(0xFF10B981);
  static const blue = Color(0xFF0EA5E9);

  static const popular = <GameCenterItem>[
    GameCenterItem(
      id: 'kader-carki',
      title: 'Kader Çarkı',
      section: GameCenterSection.popular,
      icon: Icons.casino_rounded,
      gradient: [orange, pink],
      route: '/games-hub/wheel',
      jetonCost: 10,
      heroTag: 'game-kader-carki',
    ),
    GameCenterItem(
      id: 'quiz',
      title: 'Bilgi Yarışması',
      section: GameCenterSection.popular,
      icon: Icons.quiz_rounded,
      gradient: [blue, purple],
      route: '/games-hub/quiz',
      heroTag: 'game-quiz',
    ),
    GameCenterItem(
      id: 'kelime-duellosu',
      title: 'Kelime Düellosu',
      section: GameCenterSection.popular,
      icon: Icons.spellcheck_rounded,
      gradient: [green, blue],
      route: '/games-hub/word-duel',
      jetonCost: 5,
      heroTag: 'game-word-duel',
    ),
    GameCenterItem(
      id: 'ask-uyumu',
      title: 'Aşk Uyumu',
      section: GameCenterSection.popular,
      icon: Icons.favorite_rounded,
      gradient: [pink, purple],
      route: '/games-hub/love-match',
      heroTag: 'game-love',
    ),
    GameCenterItem(
      id: 'tavla',
      title: 'Tavla',
      section: GameCenterSection.popular,
      icon: Icons.grid_on_rounded,
      gradient: [Color(0xFF92400E), orange],
      route: '/games-hub/backgammon',
      jetonCost: 20,
      heroTag: 'game-tavla',
    ),
  ];

  static const live = <GameCenterItem>[
    GameCenterItem(
      id: 'oda-quiz',
      title: 'Oda Bilgi Yarışması',
      subtitle: 'Canlı yarışma odası',
      section: GameCenterSection.live,
      icon: Icons.groups_rounded,
      gradient: [purple, blue],
      route: '/games-hub/live-quiz',
      badge: 'CANLI',
      liveCount: 128,
    ),
    GameCenterItem(
      id: 'pk-tahmin',
      title: 'PK Tahmin Oyunu',
      subtitle: 'Yayın skorunu tahmin et',
      section: GameCenterSection.live,
      icon: Icons.emoji_events_rounded,
      gradient: [pink, orange],
      route: '/games-hub/pk-prediction',
      badge: 'CANLI',
      liveCount: 64,
    ),
    GameCenterItem(
      id: 'canli-tombala',
      title: 'Canlı Tombala',
      subtitle: 'Çok oyunculu tombala',
      section: GameCenterSection.live,
      icon: Icons.celebration_rounded,
      gradient: [green, purple],
      route: '/games-hub/bingo',
      badge: 'CANLI',
      liveCount: 210,
    ),
  ];

  static const rewarded = <GameCenterItem>[
    GameCenterItem(
      id: 'hazine-sandigi',
      title: 'Günlük Hazine Sandığı',
      subtitle: 'Her gün ücretsiz ödül',
      section: GameCenterSection.rewarded,
      icon: Icons.inventory_2_rounded,
      gradient: [orange, Color(0xFFEAB308)],
      route: '/games-hub/treasure',
    ),
    GameCenterItem(
      id: 'sansli-zar',
      title: 'Şanslı Zar',
      subtitle: 'Zar at, jeton kazan',
      section: GameCenterSection.rewarded,
      icon: Icons.casino_outlined,
      gradient: [blue, green],
      route: '/games-hub/lucky-dice',
      jetonCost: 5,
    ),
    GameCenterItem(
      id: 'gunluk-gorevler',
      title: 'Günlük Görevler',
      subtitle: 'Görevleri tamamla, XP kazan',
      section: GameCenterSection.rewarded,
      icon: Icons.task_alt_rounded,
      gradient: [purple, pink],
      route: '/profile/growth',
    ),
  ];

  static List<GameCenterItem> get all => [...popular, ...live, ...rewarded];

  static GameCenterItem? findById(String id) {
    for (final item in all) {
      if (item.id == id) return item;
    }
    return null;
  }
}
