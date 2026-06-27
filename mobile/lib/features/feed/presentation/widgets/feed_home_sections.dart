import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/cached_cover_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glow_panel.dart';
import '../../../../core/widgets/quick_action_tile.dart';
import '../../../live/domain/entities/live_stream_entity.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../../../live/presentation/utils/open_live_stream.dart';

/// Ana sayfa hızlı işlemler (davet, jeton).
class FeedQuickActions extends StatelessWidget {
  const FeedQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlowPanel(
        borderRadius: 18,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitleRow(
              icon: Icons.bolt_rounded,
              title: 'Hızlı işlemler',
              accent: AppTheme.accentSecondary,
            ),
            const SizedBox(height: 12),
            QuickActionGrid(
              rows: [
                [
                  QuickActionTile(
                    icon: Icons.person_add_alt_1_rounded,
                    label: 'Arkadaşlarını\ndavet et',
                    gradient: [
                      AppTheme.accent.withValues(alpha: 0.45),
                      AppTheme.accentSecondary.withValues(alpha: 0.3),
                    ],
                    onTap: () => context.push('/invite-friends'),
                  ),
                  QuickActionTile(
                    icon: Icons.monetization_on_rounded,
                    label: 'Jeton\nyükle',
                    gradient: [
                      const Color(0xFF5C4020).withValues(alpha: 0.85),
                      const Color(0xFF2A1C10).withValues(alpha: 0.9),
                    ],
                    onTap: () => context.push('/jeton-store'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Ana sayfa (Akış) üstünde canlifal.com canlı yayın şeridi.
class FeedLiveStrip extends ConsumerWidget {
  const FeedLiveStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(liveStreamsProvider);
    return live.when(
      loading: () => const SizedBox(
        height: 100,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (streams) {
        final onAir = streams.where((s) => s.isLive).toList();
        if (onAir.isEmpty) return const SizedBox.shrink();
        return GlowPanel(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitleRow(
                icon: Icons.live_tv_rounded,
                title: 'Canlı yayınlar',
                accent: AppTheme.accentSecondary,
                trailing: TextButton(
                  onPressed: () => context.go('/live'),
                  child: const Text('Tümü'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 138,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  itemCount: onAir.length > 12 ? 12 : onAir.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (ctx, i) {
                    final s = onAir[i];
                    return _LiveChip(stream: s, ref: ref);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LiveChip extends StatelessWidget {
  const _LiveChip({required this.stream, required this.ref});

  final LiveStreamEntity stream;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceElevated,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: stream.isLive
            ? () => openLiveStreamNative(context, ref, stream)
            : null,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 118,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      stream.thumbnailUrl != null &&
                              stream.thumbnailUrl!.isNotEmpty
                          ? CachedCoverImage(
                              url: stream.thumbnailUrl!,
                              fit: BoxFit.cover,
                              fallback: const ColoredBox(
                                color: AppTheme.surface,
                                child: Icon(Icons.live_tv_rounded,
                                    color: AppTheme.accent, size: 36),
                              ),
                            )
                          : const ColoredBox(
                              color: AppTheme.surface,
                              child: Icon(Icons.live_tv_rounded,
                                  color: AppTheme.accent, size: 36),
                            ),
                      if (stream.isLive)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: const Text(
                              'CANLI',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stream.streamerName ?? 'Yayıncı',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      '${stream.viewerCount} izleyici',
                      style: TextStyle(
                        color: AppTheme.muted.withValues(alpha: 0.95),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
