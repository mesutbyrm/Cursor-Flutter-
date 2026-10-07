import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/providers/auth_selectors.dart';
import '../providers/game_providers.dart';
import 'sos_start_sheet.dart';

/// `GET /api/games/lobby?section=live_tables` satırı (oyun odası veya SOS).
class LobbyTable {
  const LobbyTable({
    required this.id,
    required this.gameType,
    required this.status,
    this.player1Id,
    this.player2Id,
  });

  factory LobbyTable.fromJson(Map<String, dynamic> json) => LobbyTable(
        id: json['id']?.toString() ?? '',
        gameType: json['gameType']?.toString().toLowerCase() ?? '',
        status: json['status']?.toString() ?? '',
        player1Id: json['player1Id']?.toString(),
        player2Id: json['player2Id']?.toString(),
      );

  final String id;
  final String gameType;
  final String status;
  final String? player1Id;
  final String? player2Id;

  bool get isSos => gameType == 'sos';
  bool get isWaiting => status == 'waiting';

  bool isMine(String? userId) =>
      userId != null &&
      userId.isNotEmpty &&
      (userId == player1Id || userId == player2Id);

  /// Bekleyen ve kullanıcının olmayan masaya katılınır; diğerleri izlenir.
  bool shouldJoin(String? userId) => isWaiting && !isMine(userId);

  String get path => isSos
      ? sosGamePath(id)
      : '/games-room/${Uri.encodeComponent(id)}?game=${Uri.encodeComponent(gameType)}';
}

/// Masaya katıl (`POST /api/games/sos/{id}` veya `POST /api/games/room/{id}`)
/// ya da izle; ardından oyun ekranını aç.
Future<void> openLobbyTable(
  BuildContext context,
  WidgetRef ref,
  LobbyTable table,
) async {
  final userId = ref.read(currentUserIdProvider);
  if (table.shouldJoin(userId)) {
    final remote = ref.read(gameRemoteProvider);
    try {
      if (table.isSos) {
        await remote.joinSosGame(table.id);
      } else {
        await remote.joinRoom(table.id);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
      return;
    }
  }
  if (context.mounted) context.push(table.path);
}
