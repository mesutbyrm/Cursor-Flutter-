import 'dart:math';

import '../domain/game_models.dart';
import '../domain/okey101/okey101_engine.dart';

/// Üretim `/api/games/rooms` 404 döndürdüğünde oturum içi Okey 101 odaları.
class Okey101LocalSession {
  Okey101LocalSession._();
  static final Okey101LocalSession instance = Okey101LocalSession._();

  final _rooms = <String, _LocalRoom>{};
  final _rng = Random();

  static bool isLocalRoomId(String roomId) => roomId.startsWith('local-');

  bool hasRoom(String roomId) => _rooms.containsKey(roomId);

  List<GameRoomItem> openRooms({String gameId = 'okey101'}) {
    return _rooms.values
        .where(
          (r) =>
              r.gameId == gameId &&
              (r.state.phase == 'waiting' || r.state.phase == 'playing'),
        )
        .map((r) => r.toItem())
        .toList();
  }

  GameRoomItem createRoom({
    required String hostUserId,
    required String hostName,
    required GameCatalogItem game,
  }) {
    final id = 'local-${_rng.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    final state = createOkey101State(hostUserId, hostName);
    _rooms[id] = _LocalRoom(
      id: id,
      title: game.title,
      gameId: game.id,
      state: state,
    );
    return _rooms[id]!.toItem();
  }

  GameRoomItem? autoMatch({
    required String userId,
    required String displayName,
    required GameCatalogItem game,
  }) {
    final waiting = _rooms.values.where(
      (r) =>
          r.gameId == game.id &&
          r.state.phase == 'waiting' &&
          r.state.players.length < r.state.maxPlayers &&
          !r.state.players.any((p) => p.userId == userId),
    );
    if (waiting.isNotEmpty) {
      final room = waiting.first;
      room.state = addPlayer(room.state, userId, displayName);
      return room.toItem();
    }
    return createRoom(
      hostUserId: userId,
      hostName: displayName,
      game: game,
    );
  }

  GameRoomItem? joinRoom({
    required String roomId,
    required String userId,
    required String displayName,
  }) {
    final room = _rooms[roomId];
    if (room == null) return null;
    room.state = addPlayer(room.state, userId, displayName);
    return room.toItem();
  }

  Map<String, dynamic> roomState(String roomId, String viewerUserId) {
    final room = _rooms[roomId];
    if (room == null) throw StateError('Oda bulunamadı');
    return _roomPayload(room, viewerUserId);
  }

  Map<String, dynamic> sendMove({
    required String roomId,
    required String userId,
    required Map<String, dynamic> move,
  }) {
    final room = _rooms[roomId];
    if (room == null) throw StateError('Oda bulunamadı');
    room.state = applyMove(room.state, userId, Okey101Move.fromJson(move));
    return _roomPayload(room, userId);
  }

  void sendChat({
    required String roomId,
    required String userId,
    required String text,
  }) {
    final room = _rooms[roomId];
    if (room == null) return;
    room.chat.add(_ChatLine(userId: userId, text: text));
    if (room.chat.length > 100) {
      room.chat.removeAt(0);
    }
  }

  Map<String, dynamic> _roomPayload(_LocalRoom room, String viewerUserId) {
    final okey101 = publicView(room.state, viewerUserId);
    return {
      'id': room.id,
      'roomId': room.id,
      'title': room.title,
      'gameId': room.gameId,
      'slug': room.gameId,
      'status': room.state.status,
      'gameType': 'okey101',
      'maxPlayers': room.state.maxPlayers,
      'playerCount': room.state.players.length,
      'turn': okey101['turnUserId'],
      'currentTurn': okey101['turnUserId'],
      'winner': room.state.winnerId,
      'result': room.state.winnerName,
      'okey101': okey101,
      'localFallback': true,
      'chat': room.chat
          .map(
            (c) => {
              'text': c.text,
              'content': c.text,
              'message': c.text,
              'userId': c.userId,
            },
          )
          .toList(),
    };
  }
}

class _LocalRoom {
  _LocalRoom({
    required this.id,
    required this.title,
    required this.gameId,
    required this.state,
  });

  final String id;
  final String title;
  final String gameId;
  Okey101GameState state;
  final List<_ChatLine> chat = [];

  GameRoomItem toItem() => GameRoomItem(
        id: id,
        title: title,
        gameId: gameId,
        status: state.status,
        playerCount: state.players.length,
        maxPlayers: state.maxPlayers,
      );
}

class _ChatLine {
  _ChatLine({required this.userId, required this.text});
  final String userId;
  final String text;
}
