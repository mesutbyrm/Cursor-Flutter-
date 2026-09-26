import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/cfc_arena_repository.dart';
import '../../domain/cfc_arena_context.dart';
import '../../domain/cfc_arena_contest_detail.dart';
import '../../domain/cfc_arena_contest_filters.dart';
import '../providers/cfc_arena_providers.dart';
import 'cfc_arena_contest_sheet.dart';

/// Katılım daveti kaç saniye sonra kendiliğinden kapanır.
const cfcArenaInviteVisibleSeconds = 60;

/// Bu oturumda daveti kapanmış yarışmalar (kullanıcı kapattı ya da süre doldu).
final cfcArenaDismissedInvitesProvider = StateProvider<Set<String>>(
  (ref) => const {},
);

/// Sesli oda / canlı yayında aktif sezon yarışması — sağ köşede açılır kapanır kutu.
///
/// Eski tasarım ekranın üstünde soldan sağa uzanan pembe bir şeritti; keşfet
/// ve süre alanını kapatıyor, katılmış kullanıcılara bile "Katıl" gösteriyordu.
/// Yeni davranış:
/// * Katılmış kullanıcıya davet **hiç** gösterilmez — yalnızca küçük rozet.
/// * Katılmamış kullanıcıya davet en fazla [cfcArenaInviteVisibleSeconds]
///   saniye görünür, sonra kendiliğinden rozete küçülür.
/// * Rozet sağ kenarda durur (sesli odada Ayarlar/Müzik kolonunun üstünde) ve
///   dokununca katılımcı/puan popup'ı açılır.
class CfcArenaRoomBanner extends ConsumerStatefulWidget {
  const CfcArenaRoomBanner({super.key, required this.surface});

  final CfcArenaSurface surface;

  @override
  ConsumerState<CfcArenaRoomBanner> createState() => _CfcArenaRoomBannerState();
}

class _CfcArenaRoomBannerState extends ConsumerState<CfcArenaRoomBanner> {
  Timer? _autoDismiss;
  String? _timedContestId;
  String? _joiningId;
  var _expanded = false;

  @override
  void dispose() {
    _autoDismiss?.cancel();
    super.dispose();
  }

  void _armAutoDismiss(String contestId) {
    if (_timedContestId == contestId) return;
    _timedContestId = contestId;
    _autoDismiss?.cancel();
    _autoDismiss = Timer(
      const Duration(seconds: cfcArenaInviteVisibleSeconds),
      () => _dismiss(contestId),
    );
  }

  void _dismiss(String contestId) {
    if (!mounted) return;
    final notifier = ref.read(cfcArenaDismissedInvitesProvider.notifier);
    notifier.state = {...notifier.state, contestId};
  }

  Future<void> _join(String contestId) async {
    setState(() => _joiningId = contestId);
    try {
      await ref.read(cfcArenaRepositoryProvider).joinContest(contestId);
      ref.invalidate(cfcArenaContestDetailProvider(contestId));
      ref.invalidate(cfcArenaContestsProvider);
      _dismiss(contestId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sezon yarışmasına katıldınız')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _joiningId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(cfcArenaContestsForSurfaceProvider(widget.surface));
    final contests = async.valueOrNull;
    if (contests == null || contests.isEmpty) return const SizedBox.shrink();

    final primary = contests.first;
    final contestId = cfcContestId(primary);
    if (contestId.isEmpty) return const SizedBox.shrink();

    final name = (primary['name'] ?? 'Sezon yarışması').toString().trim();
    final detail = ref.watch(cfcArenaContestDetailProvider(contestId)).valueOrNull;
    final myId = ref.watch(authControllerProvider).valueOrNull?.id;
    final joined = detail?.hasJoined(myId) ?? false;
    final dismissed =
        ref.watch(cfcArenaDismissedInvitesProvider).contains(contestId);

    // Katılanlar daveti hiç görmez.
    final showInvite = !joined && !dismissed;
    if (showInvite) {
      _armAutoDismiss(contestId);
    } else {
      _autoDismiss?.cancel();
    }

    final participants = detail?.entries.length ??
        cfcContestParticipantCount(primary);
    final remaining = cfcContestRemaining(primary, DateTime.now());
    final myRank = detail?.rankFor(myId);

    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (showInvite)
              _InviteCard(
                title: name,
                participants: participants,
                busy: _joiningId == contestId,
                onJoin: () => _join(contestId),
                onClose: () => _dismiss(contestId),
              )
            else ...[
              _Badge(
                expanded: _expanded,
                joined: joined,
                rank: myRank,
                onTap: () => setState(() => _expanded = !_expanded),
              ),
              if (_expanded)
                _BadgePanel(
                  title: name,
                  participants: participants,
                  remaining: remaining,
                  joined: joined,
                  busy: _joiningId == contestId,
                  onJoin: joined ? null : () => _join(contestId),
                  onOpen: () => showCfcArenaContestSheet(
                    context,
                    ref,
                    contestId: contestId,
                    title: name,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({
    required this.title,
    required this.participants,
    required this.busy,
    required this.onJoin,
    required this.onClose,
  });

  final String title;
  final int participants;
  final bool busy;
  final VoidCallback onJoin;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              InkWell(
                onTap: onClose,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              '$participants katılımcı',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: busy ? null : onJoin,
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              child: busy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Katıl'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.expanded,
    required this.joined,
    required this.rank,
    required this.onTap,
  });

  final bool expanded;
  final bool joined;
  final int? rank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = joined && rank != null ? '#$rank' : 'Yarışma';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏆', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 5),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Icon(
                expanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgePanel extends StatelessWidget {
  const _BadgePanel({
    required this.title,
    required this.participants,
    required this.remaining,
    required this.joined,
    required this.busy,
    required this.onJoin,
    required this.onOpen,
  });

  final String title;
  final int participants;
  final Duration? remaining;
  final bool joined;
  final bool busy;
  final VoidCallback? onJoin;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            title,
            maxLines: 2,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            remaining == null
                ? '👥 $participants'
                : '👥 $participants · ⏱ ${formatCfcRemaining(remaining!)}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!joined && onJoin != null) ...[
                FilledButton(
                  onPressed: busy ? null : onJoin,
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: busy
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Katıl'),
                ),
                const SizedBox(width: 6),
              ],
              TextButton(
                onPressed: onOpen,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                child: const Text('Sıralamayı gör'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
