import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/network/api_exception.dart';
import '../../../../games/presentation/game_center/providers/game_center_providers.dart';

/// Canlı yayın içinden oyun lobisi — yayın `streamId` bağlamı korunur.
Future<void> showLiveStreamGamesSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String streamId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF151522),
    showDragHandle: true,
    builder: (ctx) {
      Future<void> launch(String gameId, String label) async {
        Navigator.pop(ctx);
        try {
          final room = await ref
              .read(gameCenterRepositoryProvider)
              .createLiveRoom(gameId, videoStreamId: streamId);
          if (!context.mounted) return;
          if (room != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '$label odası açıldı — canlı yayın arka planda devam ediyor.',
                ),
              ),
            );
            context.push(
              '/games-hub/lobby',
              extra: {'streamId': streamId, 'roomId': room.id},
            );
          } else {
            context.push('/games-hub/lobby');
          }
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ApiException.userMessage(e))),
          );
        }
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ListTile(
                title: Text(
                  'Canlı yayın oyunları',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  'Yayın devam ederken oyun lobisine geçebilirsiniz.',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.quiz_rounded, color: Color(0xFFB832FF)),
                title: const Text('Bilgi Yarışması'),
                subtitle: const Text('1v1 canlı quiz'),
                onTap: () => unawaited(launch('quiz-1v1', 'Bilgi yarışması')),
              ),
              ListTile(
                leading: const Icon(Icons.grid_on_rounded, color: Color(0xFF7C4DFF)),
                title: const Text('Canlı Tombala'),
                subtitle: const Text('Çok oyunculu'),
                onTap: () => unawaited(launch('tombala', 'Tombala')),
              ),
              ListTile(
                leading: const Icon(Icons.sports_esports_rounded, color: Colors.orange),
                title: const Text('PK Tahmin'),
                subtitle: const Text('PK skorunu tahmin et'),
                onTap: () => unawaited(launch('pk-tahmin', 'PK tahmin')),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/games-hub');
                },
                child: const Text('Tüm oyun merkezi'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
