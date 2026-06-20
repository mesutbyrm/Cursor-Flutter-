import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/api_exception.dart';
import '../../providers/live_providers.dart';

/// Yayıncı moderasyon paneli — sustur, at, engelle, moderatör.
Future<void> showLiveModerationSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String streamId,
  required String targetUserId,
  required String targetDisplayName,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF151522),
    showDragHandle: true,
    builder: (ctx) {
      final ds = ref.read(liveStreamExtrasProvider);

      Future<void> run(
        Future<void> Function() action,
        String ok,
      ) async {
        try {
          await action();
          if (!ctx.mounted) return;
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok)));
        } catch (e) {
          if (!ctx.mounted) return;
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text(ApiException.userMessage(e))),
          );
        }
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  targetDisplayName,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: const Text('Moderasyon işlemleri'),
              ),
              ListTile(
                leading: const Icon(Icons.volume_off_rounded),
                title: const Text('Kullanıcıyı sustur'),
                onTap: () => run(
                  () => ds.muteViewer(streamId: streamId, viewerId: targetUserId),
                  'Kullanıcı susturuldu',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person_remove_rounded),
                title: const Text('Kullanıcıyı at'),
                onTap: () => run(
                  () => ds.banViewer(
                    streamId: streamId,
                    userId: targetUserId,
                    reason: 'kick',
                  ),
                  'Kullanıcı yayından atıldı',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.block_rounded),
                title: const Text('Kullanıcıyı engelle'),
                onTap: () => run(
                  () => ds.banViewer(
                    streamId: streamId,
                    userId: targetUserId,
                    reason: 'block',
                  ),
                  'Kullanıcı engellendi',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.shield_rounded),
                title: const Text('Moderatör yap'),
                onTap: () => run(
                  () => ds.addModerator(
                    streamId: streamId,
                    userId: targetUserId,
                  ),
                  'Moderatör eklendi',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.shield_outlined),
                title: const Text('Moderatörlüğü kaldır'),
                onTap: () => run(
                  () => ds.removeModerator(
                    streamId: streamId,
                    userId: targetUserId,
                  ),
                  'Moderatör kaldırıldı',
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
