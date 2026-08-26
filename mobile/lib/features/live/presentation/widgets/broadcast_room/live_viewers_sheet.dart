import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/network/api_exception.dart';
import '../../../../../core/theme/app_theme_colors.dart';
import '../../../../../core/widgets/user_avatar.dart';
import '../../../domain/entities/live_stream_viewer.dart';
import '../../providers/live_stream_viewers_provider.dart';
import 'live_moderation_sheet.dart';

Future<void> showLiveViewersSheet(
  BuildContext context,
  WidgetRef ref, {
  required String streamId,
  bool isHost = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF12081F),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (_, scroll) => Consumer(
        builder: (context, ref, _) {
          final async = ref.watch(liveStreamViewersProvider(streamId));
          return Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'İzleyiciler',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ),
              Expanded(
                child: async.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(ApiException.userMessage(e)),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () =>
                              ref.invalidate(liveStreamViewersProvider(streamId)),
                          child: const Text('Tekrar dene'),
                        ),
                      ],
                    ),
                  ),
                  data: (viewers) {
                    if (viewers.isEmpty) {
                      return const Center(
                        child: Text('Henüz izleyici yok'),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(liveStreamViewersProvider(streamId));
                        await ref.read(liveStreamViewersProvider(streamId).future);
                      },
                      child: ListView.builder(
                        controller: scroll,
                        itemCount: viewers.length,
                        itemBuilder: (context, i) => _ViewerTile(
                          viewer: viewers[i],
                          streamId: streamId,
                          isHost: isHost,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _ViewerTile extends ConsumerWidget {
  const _ViewerTile({
    required this.viewer,
    required this.streamId,
    this.isHost = false,
  });

  final LiveStreamViewer viewer;
  final String streamId;
  final bool isHost;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seen = viewer.lastSeen != null
        ? DateFormat('HH:mm').format(viewer.lastSeen!.toLocal())
        : null;

    return ListTile(
      leading: UserAvatar(url: viewer.avatarUrl, radius: 22),
      title: Text(
        viewer.displayName,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        [
          if (viewer.username != null && viewer.username!.isNotEmpty)
            '@${viewer.username}',
          if (seen != null) 'Son: $seen',
        ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Wrap(
        spacing: 4,
        children: [
          if (viewer.isBroadcaster) _Badge('Yayıncı', AppThemeColors.liveRed),
          if (viewer.isModerator) _Badge('Mod', AppThemeColors.accentCyan),
          if (viewer.isVip) _Badge('VIP', AppThemeColors.coinGold),
        ],
      ),
      onLongPress: isHost && viewer.id.isNotEmpty
          ? () {
              showLiveModerationSheet(
                context: context,
                ref: ref,
                streamId: streamId,
                targetUserId: viewer.id,
                targetDisplayName: viewer.displayName,
                targetAvatarUrl: viewer.avatarUrl,
                isModerator: viewer.isModerator,
              );
            }
          : null,
      onTap: viewer.id.isEmpty
          ? null
          : () {
              Navigator.pop(context);
              context.push('/user/${viewer.id}');
            },
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
