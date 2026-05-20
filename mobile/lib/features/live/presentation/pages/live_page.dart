import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_design.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../../shell/presentation/widgets/branch_quick_actions.dart';
import '../../../trtc/presentation/providers/trtc_providers.dart';
import '../../../voice_hub/presentation/voice_rooms_body.dart';
import '../../domain/entities/live_broadcast_session.dart';
import '../../domain/entities/live_stream_entity.dart';
import '../providers/live_providers.dart';

class LivePage extends ConsumerStatefulWidget {
  const LivePage({super.key});

  @override
  ConsumerState<LivePage> createState() => _LivePageState();
}

class _LivePageState extends ConsumerState<LivePage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(liveStreamsProvider);
    ref.invalidate(voiceRoomsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppDesign.bgBase,
      body: DiscoverBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: top + 8),
            DiscoverTabHeader(
              title: 'Canlı',
              subtitle: 'Yayınlar ve sesli sohbet odaları',
              actions: [
                DiscoverIconButton(
                  icon: Icons.videocam_rounded,
                  tooltip: 'Yayına başla',
                  onPressed: () => context.push('/live/prep'),
                ),
                DiscoverIconButton(
                  icon: Icons.refresh_rounded,
                  onPressed: _refresh,
                ),
              ],
            ),
            DiscoverSegmentedTabs(
              controller: _tab,
              tabs: const [
                (label: 'Yayınlar', icon: Icons.live_tv_rounded),
                (label: 'Sohbet', icon: Icons.headset_mic_rounded),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: const [
                  _LiveStreamsTab(),
                  _VoiceTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceTab extends StatelessWidget {
  const _VoiceTab();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: LiveVoiceBranchQuickActions(),
        ),
        Expanded(
          child: VoiceRoomsBody(embeddedInLiveShellTab: true),
        ),
      ],
    );
  }
}

class _LiveStreamsTab extends ConsumerWidget {
  const _LiveStreamsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(liveStreamsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: LiveStreamsBranchQuickActions(),
        ),
        Expanded(
          child: live.when(
            loading: () => const DiscoverAccentLoader(),
            error: (e, _) => DiscoverEmptyState(
              icon: Icons.live_tv_outlined,
              message: ApiException.userMessage(e),
              actionLabel: 'Yenile',
              action: () => ref.invalidate(liveStreamsProvider),
            ),
            data: (streams) {
              if (streams.isEmpty) {
                return const DiscoverEmptyState(
                  icon: Icons.videocam_off_outlined,
                  message:
                      'Şu an canlı yayın yok.\nYeni yayınlar burada görünecek.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                itemCount: streams.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                  final s = streams[i];
                  return DiscoverGlassCard(
                    onTap: s.isLive
                        ? () => _openLiveStream(context, ref, s)
                        : null,
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: SizedBox(
                            width: 72,
                            height: 88,
                            child: s.thumbnailUrl != null &&
                                    s.thumbnailUrl!.isNotEmpty
                                ? Image.network(
                                    s.thumbnailUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => _thumbFallback(),
                                  )
                                : _thumbFallback(),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (s.isLive)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppDesign.liveRed,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'LIVE',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              Text(
                                s.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${s.streamerName ?? 'Yayıncı'} · ${s.viewerCount} izleyici',
                                style: const TextStyle(
                                  color: AppDesign.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (s.isLive)
                          Icon(
                            Icons.play_circle_fill_rounded,
                            color: AppDesign.accentPink.withValues(alpha: 0.9),
                            size: 36,
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  static Future<void> _openLiveStream(
    BuildContext context,
    WidgetRef ref,
    LiveStreamEntity s,
  ) async {
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İzlemek için giriş yapın')),
      );
      return;
    }

    try {
      final cred = await ref.read(trtcRemoteProvider).fetchUserSig(
            userId: user.id,
            roomId: s.id,
          );
      if (!context.mounted) return;
      context.push(
        '/live/room',
        extra: LiveBroadcastSession.fromStream(s).copyWith(
          streamId: s.id,
          trtc: cred,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    }
  }

  static Widget _thumbFallback() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppDesign.accentPurple.withValues(alpha: 0.5),
            AppDesign.bgBase,
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.live_tv_rounded, color: Colors.white54, size: 32),
      ),
    );
  }
}
