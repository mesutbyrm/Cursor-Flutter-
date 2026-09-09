import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../../../live/presentation/providers/live_streams_list_notifier.dart';
import '../../../live/presentation/utils/open_live_stream.dart';
import '../../../live/presentation/widgets/broadcast_room/live_moderation_sheet.dart';
import '../widgets/admin_live_viewer_picker_sheet.dart';
import '../providers/staff_access_provider.dart';

/// Admin — aktif canlı yayınlar (`GET /api/video-streams`).
class AdminLiveStreamsPage extends ConsumerWidget {
  const AdminLiveStreamsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(staffAccessProvider);
    if (!access.canManageLiveStreams && !access.canManagePayments) {
      return _locked(context);
    }

    final streamsAsync = ref.watch(liveStreamsListNotifierProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: Column(
          children: [
            SizedBox(height: MediaQuery.paddingOf(context).top + 4),
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 12),
              child: Row(
                children: [
                  DiscoverIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: () => context.pop(),
                  ),
                  const Expanded(
                    child: DiscoverTabHeader(
                      title: 'Canlı Yayın Yönetimi',
                      subtitle: 'Aktif yayınlar — izleyici ve moderasyon',
                    ),
                  ),
                  DiscoverIconButton(
                    icon: Icons.refresh_rounded,
                    onPressed: () =>
                        ref.invalidate(liveStreamsListNotifierProvider),
                  ),
                ],
              ),
            ),
            Expanded(
              child: streamsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppThemeColors.accentPink,
                  ),
                ),
                error: (e, _) => Center(
                  child: DiscoverEmptyState(
                    icon: Icons.error_outline_rounded,
                    message: ApiException.userMessage(e),
                    actionLabel: 'Tekrar',
                    action: () =>
                        ref.invalidate(liveStreamsListNotifierProvider),
                  ),
                ),
                data: (streams) {
                  final live = streams.where((s) => s.isLive).toList();
                  if (live.isEmpty) {
                    return Center(
                      child: DiscoverEmptyState(
                        icon: Icons.live_tv_outlined,
                        message: 'Şu anda aktif canlı yayın yok.',
                      ),
                    );
                  }
                  return RefreshIndicator(
                    color: AppThemeColors.accentPink,
                    onRefresh: () async {
                      ref.invalidate(liveStreamsListNotifierProvider);
                      await ref.read(liveStreamsListNotifierProvider.future);
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                      itemCount: live.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final s = live[i];
                        return _StreamCard(stream: s);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _locked(BuildContext context) {
    return Scaffold(
      body: DiscoverBackground(
        child: Center(
          child: DiscoverEmptyState(
            icon: Icons.lock_outline_rounded,
            message: 'Canlı yayın yönetimi için yetkiniz yok.',
            actionLabel: 'Geri',
            action: () => Navigator.of(context).maybePop(),
          ),
        ),
      ),
    );
  }
}

class _StreamCard extends ConsumerWidget {
  const _StreamCard({required this.stream});
  final LiveStreamEntity stream;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewers = stream.viewerCount;
    final host = stream.streamerName ?? stream.hostUserId ?? '—';
    return DiscoverGlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.live_tv_rounded, color: AppThemeColors.liveRed),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  stream.title.isNotEmpty ? stream.title : 'Canlı Yayın',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppThemeColors.liveRed.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'CANLI',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppThemeColors.liveRed,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Yayıncı: $host',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          Text(
            'İzleyici: $viewers',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      openLiveStreamNative(context, ref, stream),
                  child: const Text('Yayına gir'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _openModeration(context, ref, stream),
                  child: const Text('Moderasyon'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppThemeColors.liveRed,
              ),
              onPressed: () => _endStream(context, ref, stream),
              child: const Text('Yayını sonlandır'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openModeration(
    BuildContext context,
    WidgetRef ref,
    LiveStreamEntity stream,
  ) async {
    final streamId = stream.id;
    if (streamId.isEmpty) return;

    final viewer = await showAdminLiveViewerPicker(
      context: context,
      ref: ref,
      streamId: streamId,
    );
    if (viewer == null || !context.mounted) return;

    await showLiveModerationSheet(
      context: context,
      ref: ref,
      streamId: streamId,
      targetUserId: viewer.userId,
      targetDisplayName:
          viewer.userName ?? viewer.nickname ?? viewer.userId,
    );
  }

  Future<void> _endStream(
    BuildContext context,
    WidgetRef ref,
    LiveStreamEntity stream,
  ) async {
    final streamId = stream.id;
    if (streamId.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yayını sonlandır'),
        content: const Text(
          'Bu canlı yayın sunucuda sonlandırılacak. Emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sonlandır'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(liveRemoteProvider).endVideoStream(streamId);
      ref.invalidate(liveStreamsListNotifierProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yayın sonlandırıldı')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    }
  }
}
