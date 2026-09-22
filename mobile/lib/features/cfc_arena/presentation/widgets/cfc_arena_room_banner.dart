import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../data/cfc_arena_repository.dart';
import '../../domain/cfc_arena_context.dart';
import '../../domain/cfc_arena_contest_filters.dart';
import '../providers/cfc_arena_providers.dart';

/// Canlı yayın / sesli odada aktif sezon yarışması — katılım CTA.
class CfcArenaRoomBanner extends ConsumerStatefulWidget {
  const CfcArenaRoomBanner({super.key, required this.surface});

  final CfcArenaSurface surface;

  @override
  ConsumerState<CfcArenaRoomBanner> createState() => _CfcArenaRoomBannerState();
}

class _CfcArenaRoomBannerState extends ConsumerState<CfcArenaRoomBanner> {
  String? _joiningId;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(cfcArenaContestsForSurfaceProvider(widget.surface));
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (contests) {
        if (contests.isEmpty) return const SizedBox.shrink();
        final primary = contests.first;
        final id = cfcContestId(primary);
        if (id.isEmpty) return const SizedBox.shrink();

        final name = (primary['name'] ?? 'Sezon yarışması').toString();
        final scope = (primary['scope'] ?? 'seasonal').toString();
        final participants = cfcContestParticipantCount(primary);
        final extra = contests.length > 1 ? ' +${contests.length - 1}' : '';

        return Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.only(top: 4, bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppThemeColors.accentPurple.withValues(alpha: 0.85),
                  AppThemeColors.accentPink.withValues(alpha: 0.75),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppThemeColors.accentCyan.withValues(alpha: 0.55),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppThemeColors.accentPink.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sezon yarışması$extra',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '$scope · $participants katılımcı',
                        style: const TextStyle(color: Colors.white60, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _joiningId == id
                      ? null
                      : () => _join(context, id),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black.withValues(alpha: 0.25),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  child: _joiningId == id
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Katıl', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
                  onPressed: () => context.push('/cfc-arena/$id'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _join(BuildContext context, String contestId) async {
    setState(() => _joiningId = contestId);
    try {
      await ref.read(cfcArenaRepositoryProvider).joinContest(contestId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sezon yarışmasına katıldınız')),
      );
      ref.invalidate(cfcArenaContestsForSurfaceProvider(widget.surface));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _joiningId = null);
    }
  }
}
