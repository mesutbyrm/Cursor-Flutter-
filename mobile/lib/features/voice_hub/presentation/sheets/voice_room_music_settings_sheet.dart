import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../live/domain/entities/voice_room_entity.dart';
import '../providers/chat_room_providers.dart';

/// Oda sahibi — `PATCH /music-settings` (DJ açık, istek ücreti, kuyruk limiti).
Future<void> showVoiceRoomMusicSettingsDialog(
  BuildContext context,
  WidgetRef ref, {
  required VoiceRoomEntity room,
}) async {
  final live = ref.read(voiceRoomLiveProvider(room.liveKey));
  var enabled = live.dj.musicEnabled;
  var cost = live.dj.musicRequestCost;
  var maxQ = live.dj.maxMusicQueue;

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        backgroundColor: const Color(0xFF1A0F2E),
        title: const Text(
          'Müzik ayarları',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text(
                'DJ / müzik sistemi',
                style: TextStyle(color: Colors.white70),
              ),
              value: enabled,
              onChanged: (v) => setLocal(() => enabled = v),
            ),
            ListTile(
              title: const Text(
                'İstek ücreti (jeton)',
                style: TextStyle(color: Colors.white70),
              ),
              subtitle: Text('$cost', style: const TextStyle(color: Colors.white)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () =>
                        setLocal(() => cost = (cost - 1).clamp(0, 500)),
                    icon: const Icon(Icons.remove, color: Colors.white),
                  ),
                  IconButton(
                    onPressed: () =>
                        setLocal(() => cost = (cost + 1).clamp(0, 500)),
                    icon: const Icon(Icons.add, color: Colors.white),
                  ),
                ],
              ),
            ),
            ListTile(
              title: const Text(
                'Maks. kuyruk',
                style: TextStyle(color: Colors.white70),
              ),
              subtitle: Text('$maxQ', style: const TextStyle(color: Colors.white)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () =>
                        setLocal(() => maxQ = (maxQ - 1).clamp(1, 50)),
                    icon: const Icon(Icons.remove, color: Colors.white),
                  ),
                  IconButton(
                    onPressed: () =>
                        setLocal(() => maxQ = (maxQ + 1).clamp(1, 50)),
                    icon: const Icon(Icons.add, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final err = await ref
                  .read(voiceRoomLiveProvider(room.liveKey).notifier)
                  .updateMusicSettings(
                    musicEnabled: enabled,
                    musicRequestCost: cost,
                    maxMusicQueue: maxQ,
                  );
              if (err != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(err)),
                );
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    ),
  );
}
