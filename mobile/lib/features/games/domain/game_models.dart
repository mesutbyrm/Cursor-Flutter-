import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../core/util/json_util.dart';

enum GameKind { multiplayer, mini, tournament }

class GameCatalogItem extends Equatable {
  const GameCatalogItem({
    required this.id,
    required this.title,
    required this.kind,
    this.subtitle,
    this.route,
    this.icon = Icons.sports_esports_rounded,
    this.jetonCost = 0,
  });

  factory GameCatalogItem.fromJson(Map<String, dynamic> json) {
    final id = pick(json, ['id', '_id', 'slug', 'key'])?.toString() ?? '';
    final title =
        jsonDisplayLabel(pick(json, ['title', 'name', 'label'])) ?? id;
    final type = pick(json, [
      'type',
      'kind',
      'category',
    ])?.toString().toLowerCase();
    return GameCatalogItem(
      id: id.isNotEmpty ? id : title.toLowerCase().replaceAll(' ', '-'),
      title: title,
      subtitle: pick(json, ['description', 'subtitle'])?.toString(),
      kind: type != null && type.contains('mini')
          ? GameKind.mini
          : type != null && type.contains('tournament')
          ? GameKind.tournament
          : GameKind.multiplayer,
      route: pick(json, ['route', 'path', 'url'])?.toString(),
      jetonCost: asInt(pick(json, ['jetonCost', 'cost', 'entryFee'])),
    );
  }

  final String id;
  final String title;
  final String? subtitle;
  final GameKind kind;
  final String? route;
  final IconData icon;
  final int jetonCost;

  @override
  List<Object?> get props => [
    id,
    title,
    subtitle,
    kind,
    route,
    icon,
    jetonCost,
  ];
}

class GameRoomItem extends Equatable {
  const GameRoomItem({
    required this.id,
    required this.title,
    required this.gameId,
    this.status = 'waiting',
    this.playerCount = 0,
    this.maxPlayers = 2,
    this.viewerCount = 0,
    this.jetonCost = 0,
  });

  factory GameRoomItem.fromJson(Map<String, dynamic> json) {
    final game = asJsonMap(pick(json, ['game', 'meta']));
    return GameRoomItem(
      id: pick(json, ['id', '_id', 'roomId'])?.toString() ?? '',
      title:
          jsonDisplayLabel(pick(json, ['title', 'name'])) ??
          jsonDisplayLabel(pick(game, ['title', 'name'])) ??
          'Oyun odası',
      gameId:
          pick(json, ['gameId', 'slug', 'type'])?.toString() ??
          pick(game, ['id', 'slug'])?.toString() ??
          '',
      status: pick(json, ['status', 'state'])?.toString() ?? 'waiting',
      playerCount: asInt(
        pick(json, ['playerCount', 'players', 'participantCount']),
      ),
      maxPlayers: asInt(pick(json, ['maxPlayers', 'capacity'])) == 0
          ? 2
          : asInt(pick(json, ['maxPlayers', 'capacity'])),
      viewerCount: asInt(pick(json, ['viewerCount', 'viewers'])),
      jetonCost: asInt(pick(json, ['jetonCost', 'cost', 'entryFee'])),
    );
  }

  final String id;
  final String title;
  final String gameId;
  final String status;
  final int playerCount;
  final int maxPlayers;
  final int viewerCount;
  final int jetonCost;

  @override
  List<Object?> get props => [
    id,
    title,
    gameId,
    status,
    playerCount,
    maxPlayers,
    viewerCount,
    jetonCost,
  ];
}

class GameScoreItem extends Equatable {
  const GameScoreItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.score = 0,
    this.rank,
  });

  factory GameScoreItem.fromJson(Map<String, dynamic> json) {
    final user = asJsonMap(pick(json, ['user', 'player', 'profile']));
    return GameScoreItem(
      id:
          pick(json, ['id', '_id', 'userId', 'playerId'])?.toString() ??
          pick(user, ['id'])?.toString() ??
          '',
      title:
          jsonDisplayLabel(pick(json, ['title', 'name', 'username'])) ??
          jsonDisplayLabel(user) ??
          'Oyuncu',
      subtitle: pick(json, [
        'game',
        'gameName',
        'type',
        'createdAt',
      ])?.toString(),
      score: asInt(pick(json, ['score', 'points', 'xp', 'wins'])),
      rank: asInt(pick(json, ['rank', 'position'])),
    );
  }

  final String id;
  final String title;
  final String? subtitle;
  final int score;
  final int? rank;

  @override
  List<Object?> get props => [id, title, subtitle, score, rank];
}

class GameRoomStateSnapshot extends Equatable {
  const GameRoomStateSnapshot({
    required this.roomId,
    this.status = '',
    this.turn,
    this.result,
    this.raw = const {},
    this.chat = const [],
  });

  factory GameRoomStateSnapshot.fromJson(
    String roomId,
    Map<String, dynamic> json,
  ) {
    final data = json['data'] is Map ? asJsonMap(json['data']) : json;
    final room = data['room'] is Map ? asJsonMap(data['room']) : data;
    final chatRaw = pick(data, ['chat', 'messages']);
    final chat = <String>[];
    if (chatRaw is List) {
      for (final item in chatRaw) {
        final map = asJsonMap(item);
        final text = pick(map, ['text', 'content', 'message'])?.toString();
        if (text != null && text.isNotEmpty) chat.add(text);
      }
    }
    return GameRoomStateSnapshot(
      roomId: roomId,
      status: pick(room, ['status', 'state'])?.toString() ?? '',
      turn: pick(room, ['turn', 'currentTurn', 'currentPlayer'])?.toString(),
      result: pick(room, ['result', 'winner', 'outcome'])?.toString(),
      raw: room,
      chat: chat,
    );
  }

  final String roomId;
  final String status;
  final String? turn;
  final String? result;
  final Map<String, dynamic> raw;
  final List<String> chat;

  @override
  List<Object?> get props => [roomId, status, turn, result, raw, chat];
}

abstract final class GameCatalogFallback {
  static const multiplayer = [
    GameCatalogItem(id: 'xox', title: 'XOX', kind: GameKind.multiplayer),
    GameCatalogItem(
      id: 'tombala',
      title: 'Tombala',
      kind: GameKind.multiplayer,
    ),
    GameCatalogItem(id: 'tavla', title: 'Tavla', kind: GameKind.multiplayer),
    GameCatalogItem(id: 'pisti', title: 'Pişti', kind: GameKind.multiplayer),
    GameCatalogItem(
      id: 'sayi-tahmin',
      title: 'Sayı Tahmin',
      kind: GameKind.multiplayer,
    ),
    GameCatalogItem(id: 'zar', title: 'Zar', kind: GameKind.multiplayer),
    GameCatalogItem(id: 'okey', title: 'Okey', kind: GameKind.multiplayer),
    GameCatalogItem(
      id: 'okey101',
      title: 'Okey 101',
      kind: GameKind.multiplayer,
    ),
    GameCatalogItem(
      id: 'connect4',
      title: 'Connect 4',
      kind: GameKind.multiplayer,
    ),
    GameCatalogItem(
      id: 'reversi',
      title: 'Reversi',
      kind: GameKind.multiplayer,
    ),
    GameCatalogItem(id: 'dama', title: 'Dama', kind: GameKind.multiplayer),
    GameCatalogItem(
      id: 'mangala',
      title: 'Mangala',
      kind: GameKind.multiplayer,
    ),
    GameCatalogItem(id: 'gomoku', title: 'Gomoku', kind: GameKind.multiplayer),
    GameCatalogItem(
      id: 'amiral-batti',
      title: 'Amiral Battı',
      kind: GameKind.multiplayer,
    ),
    GameCatalogItem(
      id: 'kelime-duellosu',
      title: 'Kelime Düellosu',
      kind: GameKind.multiplayer,
    ),
    GameCatalogItem(
      id: 'quiz-1v1',
      title: 'Quiz 1v1',
      kind: GameKind.multiplayer,
    ),
    GameCatalogItem(
      id: 'kart-eslestirme-pvp',
      title: 'Kart Eşleştirme PvP',
      kind: GameKind.multiplayer,
    ),
    GameCatalogItem(id: 'sos', title: 'SOS', kind: GameKind.multiplayer),
    GameCatalogItem(
      id: 'tas-kagit-makas',
      title: 'Taş Kağıt Makas',
      kind: GameKind.multiplayer,
    ),
  ];

  static const mini = [
    GameCatalogItem(id: '2048', title: '2048', kind: GameKind.mini),
    GameCatalogItem(id: 'anagram', title: 'Anagram', kind: GameKind.mini),
    GameCatalogItem(id: 'carkifelek', title: 'Çarkıfelek', kind: GameKind.mini),
    GameCatalogItem(
      id: 'color-sort',
      title: 'Renk Sıralama',
      kind: GameKind.mini,
    ),
    GameCatalogItem(id: 'hangman', title: 'Adam Asmaca', kind: GameKind.mini),
    GameCatalogItem(id: 'logo-quiz', title: 'Logo Quiz', kind: GameKind.mini),
    GameCatalogItem(id: 'mastermind', title: 'Mastermind', kind: GameKind.mini),
    GameCatalogItem(
      id: 'memory-match',
      title: 'Hafıza Eşleştirme',
      kind: GameKind.mini,
    ),
    GameCatalogItem(
      id: 'minesweeper',
      title: 'Mayın Tarlası',
      kind: GameKind.mini,
    ),
    GameCatalogItem(id: 'quiz', title: 'Bilgi Yarışması', kind: GameKind.mini),
    GameCatalogItem(id: 'scratch', title: 'Kazı Kazan', kind: GameKind.mini),
    GameCatalogItem(id: 'slot', title: 'Slot', kind: GameKind.mini),
    GameCatalogItem(id: 'sudoku', title: 'Sudoku', kind: GameKind.mini),
    GameCatalogItem(id: 'word-hunt', title: 'Kelime Avı', kind: GameKind.mini),
    GameCatalogItem(
      id: 'word-puzzle',
      title: 'Kelime Bulmacası',
      kind: GameKind.mini,
    ),
  ];

  static List<GameCatalogItem> get all => [...multiplayer, ...mini];
}
