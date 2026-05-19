import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/cosmic_background.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glow_panel.dart';
import '../../../canlifal_web/presentation/canlifal_web_view_page.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (b) => LinearGradient(
            colors: [
              AppTheme.accentGold,
              AppTheme.accent,
            ],
          ).createShader(b),
          child: const Text(
            'Canlı & odalar',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: () {
              ref.invalidate(liveStreamsProvider);
              ref.invalidate(voiceRoomsProvider);
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppTheme.accent,
          labelColor: Colors.white,
          unselectedLabelColor: AppTheme.muted,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'Yayınlar', icon: Icon(Icons.live_tv_rounded)),
            Tab(text: 'Sohbet', icon: Icon(Icons.headset_mic_rounded)),
          ],
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CosmicBackground(),
          TabBarView(
            controller: _tab,
            children: [
              const _LiveStreamsTab(),
              VoiceRoomsBody(embedInParentScaffold: true),
            ],
          ),
        ],
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => RefreshIndicator(
        color: AppTheme.accent,
        onRefresh: () async => ref.invalidate(liveStreamsProvider),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            GlowPanel(
              child: Column(
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: 44,
                    color: AppTheme.muted.withValues(alpha: 0.85),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ApiException.userMessage(e),
                    textAlign: TextAlign.center,
                    style: const TextStyle(height: 1.35),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => ref.invalidate(liveStreamsProvider),
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    label: const Text('Tekrar dene'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.push(
                      CanlifalWebRoute.location(
                        relativePath: '/sohbet/video',
                        title: 'Canlı yayınlar',
                      ),
                    ),
                    child: const Text('Web’de canlı yayınlar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      data: (streams) {
        if (streams.isEmpty) {
          return RefreshIndicator(
            color: AppTheme.accent,
            onRefresh: () async => ref.invalidate(liveStreamsProvider),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                GlowPanel(
                  child: Column(
                    children: [
                      Icon(
                        Icons.live_tv_rounded,
                        size: 48,
                        color: AppTheme.accent.withValues(alpha: 0.85),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Uygulama listesinde şu an yayın yok.\n'
                        'Yayıncılar açınca burada görünür; isterseniz doğrudan sitedeki canlı sayfasını açın.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          height: 1.35,
                          color: AppTheme.muted.withValues(alpha: 0.98),
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: () => context.push(
                          CanlifalWebRoute.location(
                            relativePath: '/sohbet/video',
                            title: 'Canlı yayınlar',
                          ),
                        ),
                        icon: const Icon(Icons.play_circle_outline_rounded,
                            size: 22),
                        label: const Text('Canlı yayınlara git'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          color: AppTheme.accent,
          onRefresh: () async => ref.invalidate(liveStreamsProvider),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: streams.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) {
              final s = streams[i];
              return Material(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: s.isLive
                      ? () => context.push(
                            CanlifalWebRoute.location(
                              relativePath: '/sohbet/video?watch=${s.id}',
                              title: s.title,
                              streamIdForGifts: s.id,
                            ),
                          )
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 64,
                            height: 64,
                            child: s.thumbnailUrl != null &&
                                    s.thumbnailUrl!.isNotEmpty
                                ? Image.network(
                                    s.thumbnailUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const ColoredBox(
                                      color: AppTheme.surface,
                                      child: Icon(Icons.live_tv_rounded,
                                          color: AppTheme.accent),
                                    ),
                                  )
                                : const ColoredBox(
                                    color: AppTheme.surface,
                                    child: Icon(Icons.live_tv_rounded,
                                        color: AppTheme.accent),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${s.streamerName ?? 'Yayıncı'} · ${s.viewerCount} izleyici',
                                style: const TextStyle(color: AppTheme.muted),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: s.isLive
                                ? AppTheme.accent.withValues(alpha: 0.2)
                                : AppTheme.muted.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            s.isLive ? 'CANLI' : 'BİTTİ',
                            style: TextStyle(
                              color:
                                  s.isLive ? AppTheme.accent : AppTheme.muted,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        if (s.isLive) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right, color: AppTheme.muted),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
