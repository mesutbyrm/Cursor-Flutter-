import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../gifts/presentation/sync/gift_session_controller.dart';
import '../../../../gifts/presentation/sync/gift_session_state.dart';

/// Video pane altı — son destekçiler (gerçek hediye oturumu).
class LivePkPaneGifterStrip extends ConsumerWidget {
  const LivePkPaneGifterStrip({
    super.key,
    required this.sessionKey,
    required this.hostLabel,
    this.hostUserId,
    this.alignLeft = true,
  });

  final String sessionKey;
  final String hostLabel;
  final String? hostUserId;
  final bool alignLeft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (sessionKey.isEmpty) return const SizedBox.shrink();
    final recent = ref.watch(
      giftSessionProvider(sessionKey).select((s) => s.recentGifts),
    );
    final names = _topSenderNames(recent, hostLabel, hostUserId);
    if (names.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < names.length; i++)
          Padding(
            padding: EdgeInsets.only(right: i < names.length - 1 ? 4 : 0),
            child: _RankBubble(rank: i + 1, name: names[i]),
          ),
      ],
    );
  }

  static List<String> _topSenderNames(
    List<GiftRecentItem> recent,
    String hostLabel,
    String? hostUserId,
  ) {
    final label = hostLabel.trim().toLowerCase();
    final uid = hostUserId?.trim() ?? '';
    final seen = <String>{};
    final out = <String>[];
    for (final g in recent) {
      if (!_targetsHost(g, label, uid)) continue;
      final key = g.senderId.isNotEmpty ? g.senderId : g.senderName;
      if (key.isEmpty || !seen.add(key)) continue;
      out.add(g.senderName.trim().isNotEmpty ? g.senderName.trim() : 'İzleyici');
      if (out.length >= 3) break;
    }
    return out;
  }

  static bool _targetsHost(GiftRecentItem g, String hostLabel, String hostUserId) {
    final recv = g.receiverName.trim().toLowerCase();
    if (hostLabel.isNotEmpty && recv == hostLabel) return true;
    if (hostLabel.isNotEmpty && recv.contains(hostLabel)) return true;
    if (hostUserId.isNotEmpty && g.receiverName.contains(hostUserId)) return true;
    return false;
  }
}

class _RankBubble extends StatelessWidget {
  const _RankBubble({required this.rank, required this.name});

  final int rank;
  final String name;

  @override
  Widget build(BuildContext context) {
    Color ring = Colors.white54;
    if (rank == 1) ring = const Color(0xFFFFD54F);
    if (rank == 2) ring = const Color(0xFFE0E0E0);
    if (rank == 3) ring = const Color(0xFFCD7F32);

    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.55),
            border: Border.all(color: ring, width: 1.5),
          ),
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Positioned(
          right: -3,
          bottom: -2,
          child: Container(
            width: 12,
            height: 12,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ring,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$rank',
              style: const TextStyle(
                fontSize: 7,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
