import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/okey101/okey101_models.dart';
import '../okey101/okey101_room_page.dart';
import '../pages/game_room_loading_page.dart';
import '../pages/game_room_page.dart';
import '../providers/game_providers.dart';

/// Oda tipine göre özel tahta veya genel oda ekranı.
class GameRoomRouterPage extends ConsumerWidget {
  const GameRoomRouterPage({
    super.key,
    required this.roomId,
    this.title,
    this.gameHint,
  });

  final String roomId;
  final String? title;
  final String? gameHint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hint = gameHint?.toLowerCase() ?? '';
    if (hint.contains('okey101') || hint == 'okey-101') {
      return Okey101RoomPage(roomId: roomId, title: title);
    }

    final state = ref.watch(gameRoomControllerProvider(roomId));
    return state.when(
      loading: () => GameRoomLoadingPage(title: title),
      error: (_, __) => GameRoomPage(
        roomId: roomId,
        title: title,
        gameHint: gameHint,
      ),
      data: (snapshot) {
        final okey = parseOkey101FromRoomRaw(snapshot.raw);
        final gameType = snapshot.raw['gameType']?.toString() ??
            snapshot.raw['gameId']?.toString() ??
            hint;
        if (okey != null ||
            gameType.contains('okey101') ||
            hint.contains('okey101')) {
          return Okey101RoomPage(roomId: roomId, title: title);
        }
        return GameRoomPage(
          roomId: roomId,
          title: title,
          gameHint: gameHint ?? gameType,
        );
      },
    );
  }
}
