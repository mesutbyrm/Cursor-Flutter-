import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../domain/game_models.dart';
import '../providers/game_providers.dart';

/// Okey 101 lobisi — oda oluştur / eşleş.
class Okey101LobbyPage extends ConsumerWidget {
  const Okey101LobbyPage({super.key});

  static const game = GameCatalogItem(
    id: 'okey101',
    title: 'Okey 101',
    subtitle: '4 oyunculu, 101 puanla aç, çok oyunculu',
    kind: GameKind.multiplayer,
    icon: Icons.view_module_rounded,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms = ref.watch(gameRoomsProvider);
    final okeyRooms = rooms.valueOrNull
            ?.where((r) => r.gameId.contains('okey101') || r.gameId == 'okey101')
            .toList() ??
        [];

    return DiscoverSubPage(
      title: 'Okey 101',
      subtitle: '101 puanla aç · 2–4 oyuncu · site API uyumlu',
      onRefresh: () async {
        ref.invalidate(gameRoomsProvider);
        await ref.read(gameRoomsProvider.future);
      },
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
        children: [
          _HeroCard(),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _createRoom(context, ref),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Oda oluştur'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _autoMatch(context, ref),
            icon: const Icon(Icons.shuffle_rounded),
            label: const Text('Otomatik eşleş (2–4 kişi)'),
          ),
          const SizedBox(height: 20),
          Text(
            'Açık Okey 101 odaları',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: context.colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          if (rooms.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (okeyRooms.isEmpty)
            Text(
              'Açık oda yok. Oda oluştur veya otomatik eşleş.',
              style: TextStyle(color: context.colors.onSurfaceMuted),
            )
          else
            for (final room in okeyRooms)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.groups_rounded),
                  title: Text(room.title),
                  subtitle: Text(
                    '${room.playerCount}/${room.maxPlayers} · ${room.status}',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _joinRoom(context, ref, room.id, room.title),
                ),
              ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.push('/games-hub/lobby'),
            child: const Text('Tüm oyun lobisi'),
          ),
        ],
      ),
    );
  }

  Future<void> _createRoom(BuildContext context, WidgetRef ref) async {
    try {
      final room = await ref.read(gameRemoteProvider).createRoom(game);
      if (!context.mounted || room == null) return;
      context.push(
        '/games-room/${room.id}?title=${Uri.encodeComponent(room.title)}&game=okey101',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    }
  }

  Future<void> _autoMatch(BuildContext context, WidgetRef ref) async {
    try {
      final room = await ref.read(gameRemoteProvider).autoMatch(game);
      if (!context.mounted || room == null) return;
      context.push(
        '/games-room/${room.id}?title=${Uri.encodeComponent(room.title)}&game=okey101',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    }
  }

  Future<void> _joinRoom(
    BuildContext context,
    WidgetRef ref,
    String roomId,
    String title,
  ) async {
    try {
      await ref.read(gameRemoteProvider).joinRoom(roomId);
      if (!context.mounted) return;
      context.push(
        '/games-room/$roomId?title=${Uri.encodeComponent(title)}&game=okey101',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    }
  }
}

class _HeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF065F46), Color(0xFF047857), Color(0xFF10B981)],
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '101 Okey',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Klasik Türk okey kuralları: 101 puanla aç, elini bitir. '
            'Gerçek zamanlı oda senkronu canlifal.com API ile.',
            style: TextStyle(color: Colors.white70, height: 1.35),
          ),
        ],
      ),
    );
  }
}
