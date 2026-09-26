import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/live_broadcast_session.dart';
import '../../providers/co_broadcast_provider.dart';
/// Canlı yayın — Daha fazla menüsü (kutucuk grid + kontrol merkezi alt hub).
class LiveBroadcastMoreHubActions {
  const LiveBroadcastMoreHubActions({
    required this.session,
    required this.streamId,
    required this.giftsEnabled,
    required this.pkEnabled,
    required this.pendingFortune,
    required this.showTournament,
    required this.viewerAudioOn,
    required this.onEmoji,
    required this.onGiftPanel,
    required this.onGuestRequest,
    required this.onPkPanel,
    required this.onGames,
    required this.onTournament,
    required this.onBroadcastSettings,
    required this.onBeautyFilter,
    required this.onHostTools,
    required this.onToggleViewerAudio,
    required this.onReport,
    required this.onShare,
    required this.onOpenControlCenter,
  });

  final LiveBroadcastSession session;
  final String? streamId;
  final bool giftsEnabled;
  final bool pkEnabled;
  final int pendingFortune;
  final bool showTournament;
  final bool viewerAudioOn;
  final VoidCallback onEmoji;
  final VoidCallback onGiftPanel;
  final VoidCallback onGuestRequest;
  final VoidCallback onPkPanel;
  final VoidCallback onGames;
  final VoidCallback onTournament;
  final VoidCallback onBroadcastSettings;
  final VoidCallback onBeautyFilter;
  final VoidCallback onHostTools;
  final VoidCallback onToggleViewerAudio;
  final VoidCallback onReport;
  final VoidCallback onShare;
  final Future<void> Function({int initialTab}) onOpenControlCenter;
}

Future<void> showLiveBroadcastMoreHubSheet(
  BuildContext context,
  WidgetRef ref,
  LiveBroadcastMoreHubActions actions,
) {
  final guestPending = ref.read(coBroadcastProvider).joinRequests.length;
  final totalBadge = actions.pendingFortune + guestPending;

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF151522),
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (totalBadge > 0 && actions.session.isHost)
                _PendingStrip(
                  fortuneCount: actions.pendingFortune,
                  guestCount: guestPending,
                  onFortune: () {
                    Navigator.pop(ctx);
                    actions.onOpenControlCenter(initialTab: 0);
                  },
                  onGuest: () {
                    Navigator.pop(ctx);
                    actions.onOpenControlCenter(initialTab: 2);
                  },
                ),
              Text(
                actions.session.isHost ? 'Yayın araçları' : 'Daha fazla',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              _HubGrid(
                children: _buildTiles(ctx, actions, guestPending),
              ),
              if (actions.session.isHost) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showControlCenterHub(ctx, ref, actions);
                  },
                  icon: const Icon(Icons.dashboard_customize_rounded),
                  label: Text(
                    guestPending + actions.pendingFortune > 0
                        ? 'Kontrol merkezi (${guestPending + actions.pendingFortune})'
                        : 'Kontrol merkezi',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFB832FF)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

List<Widget> _buildTiles(
  BuildContext ctx,
  LiveBroadcastMoreHubActions a,
  int guestPending,
) {
  void popThen(VoidCallback fn) {
    Navigator.pop(ctx);
    fn();
  }

  Future<void> popThenAsync(FutureOr<void> Function() fn) async {
    Navigator.pop(ctx);
    await fn();
  }

  final s = a.session;
  final streamId = a.streamId;
  final tiles = <Widget>[
    _HubTile(
      icon: Icons.emoji_emotions_outlined,
      label: 'Emoji',
      color: const Color(0xFFFFD54F),
      onTap: () => popThen(a.onEmoji),
    ),
  ];

  if (!s.isHost && a.giftsEnabled && streamId != null) {
    tiles.add(
      _HubTile(
        icon: Icons.card_giftcard_rounded,
        label: 'Hediye',
        color: const Color(0xFFFF2D7A),
        onTap: () => popThen(a.onGiftPanel),
      ),
    );
  }

  if (!s.isHost && streamId != null && streamId.isNotEmpty) {
    tiles.add(
      _HubTile(
        icon: Icons.people_alt_rounded,
        label: 'Misafir ol',
        color: const Color(0xFF22C55E),
        onTap: () => popThen(a.onGuestRequest),
      ),
    );
  }

  if (s.isHost && streamId != null) {
    tiles.add(
      _HubTile(
        icon: Icons.people_alt_rounded,
        label: 'Konuk',
        color: const Color(0xFF22C55E),
        badge: guestPending,
        onTap: () => popThenAsync(
          () => a.onOpenControlCenter(initialTab: 2),
        ),
      ),
    );
  }

  if (s.isHost && a.pkEnabled) {
    tiles.add(
      _HubTile(
        icon: Icons.sports_mma_rounded,
        label: 'PK',
        color: const Color(0xFF7C4DFF),
        onTap: () => popThenAsync(a.onPkPanel),
      ),
    );
  }

  tiles.add(
    _HubTile(
      icon: Icons.sports_esports_rounded,
      label: 'Oyunlar',
      color: const Color(0xFF38BDF8),
      onTap: () => popThenAsync(a.onGames),
    ),
  );

  if (a.showTournament) {
    tiles.add(
      _HubTile(
        icon: Icons.emoji_events_rounded,
        label: 'Turnuva',
        color: const Color(0xFFFFB300),
        onTap: () => popThenAsync(a.onTournament),
      ),
    );
  }

  if (s.isHost) {
    tiles.addAll([
      _HubTile(
        icon: Icons.auto_awesome_rounded,
        label: 'Fal',
        color: const Color(0xFF9C27FF),
        badge: a.pendingFortune,
        onTap: () => popThenAsync(
          () => a.onOpenControlCenter(initialTab: 0),
        ),
      ),
      _HubTile(
        icon: Icons.settings_rounded,
        label: 'Ayarlar',
        color: Colors.white70,
        onTap: () => popThen(a.onBroadcastSettings),
      ),
      _HubTile(
        icon: Icons.face_retouching_natural_rounded,
        label: 'Güzellik',
        color: const Color(0xFFE91E63),
        onTap: () => popThen(a.onBeautyFilter),
      ),
      _HubTile(
        icon: Icons.tune_rounded,
        label: 'Araçlar',
        color: const Color(0xFF94A3B8),
        onTap: () => popThenAsync(a.onHostTools),
      ),
    ]);
  } else {
    tiles.addAll([
      _HubTile(
        icon: a.viewerAudioOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
        label: a.viewerAudioOn ? 'Ses açık' : 'Ses kapalı',
        color: const Color(0xFF64748B),
        onTap: () => popThen(a.onToggleViewerAudio),
      ),
      if (streamId != null && streamId.isNotEmpty)
        _HubTile(
          icon: Icons.flag_outlined,
          label: 'Bildir',
          color: const Color(0xFFEF4444),
          onTap: () => popThen(a.onReport),
        ),
    ]);
  }

  tiles.add(
    _HubTile(
      icon: Icons.share_rounded,
      label: 'Paylaş',
      color: const Color(0xFF60A5FA),
      onTap: () => popThenAsync(a.onShare),
    ),
  );

  return tiles;
}

Future<void> _showControlCenterHub(
  BuildContext context,
  WidgetRef ref,
  LiveBroadcastMoreHubActions actions,
) async {
  final streamId = actions.streamId?.trim();
  if (streamId == null || streamId.isEmpty) return;

  final guestPending = ref.read(coBroadcastProvider).joinRequests.length;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF151522),
    showDragHandle: true,
    builder: (ctx) {
      final tabs = [
        (Icons.auto_awesome_rounded, 'Fal', actions.pendingFortune, 0),
        (Icons.card_giftcard_rounded, 'Hediye', 0, 1),
        (Icons.people_alt_rounded, 'Konuk', guestPending, 2),
        (Icons.shield_rounded, 'Mod', 0, 3),
        (Icons.celebration_rounded, 'Etkinlik', 0, 4),
        (Icons.insights_rounded, 'İstatistik', 0, 5),
      ];
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Kontrol merkezi',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            _HubGrid(
              children: tabs
                  .map(
                    (t) => _HubTile(
                      icon: t.$1,
                      label: t.$2,
                      color: const Color(0xFFB832FF),
                      badge: t.$3,
                      onTap: () {
                        Navigator.pop(ctx);
                        actions.onOpenControlCenter(initialTab: t.$4);
                      },
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      );
    },
  );
}

class _PendingStrip extends StatelessWidget {
  const _PendingStrip({
    required this.fortuneCount,
    required this.guestCount,
    required this.onFortune,
    required this.onGuest,
  });

  final int fortuneCount;
  final int guestCount;
  final VoidCallback onFortune;
  final VoidCallback onGuest;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFB832FF).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB832FF).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Bekleyen istekler',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          if (guestCount > 0)
            _PendingRow(
              label: 'Konuk isteği',
              count: guestCount,
              onTap: onGuest,
            ),
          if (fortuneCount > 0)
            _PendingRow(
              label: 'Fal isteği',
              count: fortuneCount,
              onTap: onFortune,
            ),
        ],
      ),
    );
  }
}

class _PendingRow extends StatelessWidget {
  const _PendingRow({
    required this.label,
    required this.count,
    required this.onTap,
  });

  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF2D7A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Colors.white54),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HubGrid extends StatelessWidget {
  const _HubGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: children,
    );
  }
}

class _HubTile extends StatelessWidget {
  const _HubTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.black.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.55)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: color, size: 26),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (badge > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF2D7A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  badge > 99 ? '99+' : '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
