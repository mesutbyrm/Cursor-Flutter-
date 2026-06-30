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

  static const popular = <GameCenterItem>[];

  static const live = <GameCenterItem>[];

  static const rewarded = <GameCenterItem>[];

  static List<GameCenterItem> get all => [...popular, ...live, ...rewarded];

  static GameCenterItem? findById(String id) {
    for (final item in all) {
      if (item.id == id) return item;
    }
    return null;
  }
}
