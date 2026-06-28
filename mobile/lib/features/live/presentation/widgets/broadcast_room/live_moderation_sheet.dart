import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../../core/network/api_exception.dart';
import '../../../data/datasources/live_stream_extras_datasource.dart';
import '../../providers/live_providers.dart';

final liveModerationProvider =
    StateNotifierProvider.family<LiveModerationNotifier, AsyncValue<void>, String>(
  (ref, streamId) => LiveModerationNotifier(ref, streamId),
);

class LiveModerationNotifier extends StateNotifier<AsyncValue<void>> {
  LiveModerationNotifier(this._ref, this.streamId) : super(const AsyncData(null));

  final Ref _ref;
  final String streamId;

  LiveStreamExtrasDataSource get _ds => _ref.read(liveStreamExtrasProvider);

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    try {
      await action();
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> addModerator(String userId) => _run(
        () => _ds.addModerator(streamId: streamId, userId: userId),
      );

  Future<bool> removeModerator(String userId) => _run(
        () => _ds.removeModerator(streamId: streamId, userId: userId),
      );

  Future<bool> muteUser(String userId) => _run(
        () => _ds.muteViewer(streamId: streamId, viewerId: userId),
      );

  Future<bool> kickUser(String userId) => _run(
        () => _ds.banViewer(
          streamId: streamId,
          userId: userId,
          reason: 'kick',
        ),
      );

  Future<bool> banUser(String userId) => _run(
        () => _ds.banViewer(
          streamId: streamId,
          userId: userId,
          reason: 'block',
        ),
      );
}

/// Live yayın moderasyon paneli — sustur, at, engelle, moderatör.
Future<void> showLiveModerationSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String streamId,
  required String targetUserId,
  required String targetDisplayName,
  String? targetAvatarUrl,
  bool isModerator = false,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF1E1030),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _LiveModerationSheet(
      streamId: streamId,
      targetUserId: targetUserId,
      targetDisplayName: targetDisplayName,
      targetAvatarUrl: targetAvatarUrl,
      isModerator: isModerator,
    ),
  );
}

class _LiveModerationSheet extends ConsumerWidget {
  const _LiveModerationSheet({
    required this.streamId,
    required this.targetUserId,
    required this.targetDisplayName,
    this.targetAvatarUrl,
    required this.isModerator,
  });

  final String streamId;
  final String targetUserId;
  final String targetDisplayName;
  final String? targetAvatarUrl;
  final bool isModerator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(liveModerationProvider(streamId).notifier);
    final state = ref.watch(liveModerationProvider(streamId));
    final isLoading = state is AsyncLoading;
    final errorMsg = state is AsyncError
        ? ApiException.userMessage(state.error)
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: targetAvatarUrl != null && targetAvatarUrl!.isNotEmpty
                    ? canlifalImageProvider(targetAvatarUrl!)
                    : null,
                backgroundColor: const Color(0xFF6C3FC5),
                child: targetAvatarUrl == null || targetAvatarUrl!.isEmpty
                    ? Text(
                        targetDisplayName.isNotEmpty
                            ? targetDisplayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(color: Colors.white),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        targetDisplayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isModerator) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C3FC5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Moderatör',
                          style: TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white12),
          const SizedBox(height: 8),
          if (errorMsg != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                errorMsg,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: Color(0xFF6C3FC5)),
            )
          else ...[
            _ActionTile(
              icon: Icons.shield_rounded,
              label: isModerator ? 'Moderatörlüğü Kaldır' : 'Moderatör Yap',
              color: const Color(0xFF6C3FC5),
              onTap: () async {
                final ok = isModerator
                    ? await notifier.removeModerator(targetUserId)
                    : await notifier.addModerator(targetUserId);
                if (!context.mounted) return;
                Navigator.pop(context);
                _showSnack(
                  context,
                  ok
                      ? (isModerator
                          ? 'Moderatörlük kaldırıldı'
                          : '$targetDisplayName moderatör yapıldı')
                      : 'İşlem başarısız',
                  ok,
                );
              },
            ),
            _ActionTile(
              icon: Icons.mic_off_rounded,
              label: 'Sustur',
              color: Colors.orange,
              onTap: () async {
                final ok = await notifier.muteUser(targetUserId);
                if (!context.mounted) return;
                Navigator.pop(context);
                _showSnack(
                  context,
                  ok ? '$targetDisplayName susturuldu' : 'Hata',
                  ok,
                );
              },
            ),
            _ActionTile(
              icon: Icons.logout_rounded,
              label: 'Yayından At',
              color: Colors.redAccent,
              onTap: () async {
                final ok = await notifier.kickUser(targetUserId);
                if (!context.mounted) return;
                Navigator.pop(context);
                _showSnack(
                  context,
                  ok ? '$targetDisplayName atıldı' : 'Hata',
                  ok,
                );
              },
            ),
            _ActionTile(
              icon: Icons.block_rounded,
              label: 'Engelle (Ban)',
              color: Colors.red,
              onTap: () async {
                final confirmed = await _confirmDialog(
                  context,
                  '$targetDisplayName banlanacak. Emin misiniz?',
                );
                if (!confirmed || !context.mounted) return;
                final ok = await notifier.banUser(targetUserId);
                if (!context.mounted) return;
                Navigator.pop(context);
                _showSnack(
                  context,
                  ok ? '$targetDisplayName banlandı' : 'Hata',
                  ok,
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  void _showSnack(BuildContext ctx, String msg, bool ok) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: ok ? const Color(0xFF6C3FC5) : Colors.red,
      ),
    );
  }

  Future<bool> _confirmDialog(BuildContext ctx, String msg) async {
    return await showDialog<bool>(
          context: ctx,
          builder: (dialogCtx) => AlertDialog(
            backgroundColor: const Color(0xFF1E1030),
            title: const Text('Onay', style: TextStyle(color: Colors.white)),
            content: Text(msg, style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: const Text('İptal', style: TextStyle(color: Colors.white54)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, true),
                child: const Text('Evet', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color, fontSize: 15)),
      onTap: onTap,
    );
  }
}
