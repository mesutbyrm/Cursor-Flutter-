import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_design.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../canlifal_web/presentation/canlifal_web_view_page.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../../voice_hub/presentation/voice_rooms_body.dart';
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
                  VoiceRoomsBody(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveStreamsTab extends ConsumerWidget {
  const _LiveStreamsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(liveStreamsProvider);

    return live.when(
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
            message: 'Şu an canlı yayın yok.\nYeni yayınlar burada görünecek.',
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
                  ? () => context.push(
                        CanlifalWebRoute.location(
                          relativePath: '/sohbet/video?watch=${s.id}',
                          title: s.title,
                          streamIdForGifts: s.id,
                        ),
                      )
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
    );
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
