import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../gifts/presentation/sync/gift_session_controller.dart';
import '../../../../gifts/presentation/sync/gift_session_state.dart';

/// Kompakt iki kolon top destekçi — video alanını kaplamaz.
class LivePkTopSupportersPanel extends ConsumerWidget {
  const LivePkTopSupportersPanel({
    super.key,
    required this.sessionKey,
    required this.leftHostLabel,
    required this.rightHostLabel,
    this.leftHostUserId,
    this.rightHostUserId,
  });

  final String sessionKey;
  final String leftHostLabel;
  final String rightHostLabel;
  final String? leftHostUserId;
  final String? rightHostUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (sessionKey.isEmpty) return const SizedBox.shrink();
    final recent = ref.watch(
      giftSessionProvider(sessionKey).select((s) => s.recentGifts),
    );
    final left = _rank(recent, leftHostLabel, leftHostUserId);
    final right = _rank(recent, rightHostLabel, rightHostUserId);
    if (left.isEmpty && right.isEmpty) return const SizedBox.shrink();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'TOP DESTEKÇİLER',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _column(leftHostLabel, left, const Color(0xFFFF2D7A))),
                const SizedBox(width: 8),
                Expanded(child: _column(rightHostLabel, right, const Color(0xFF448AFF))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _column(String title, List<_Rank> rows, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: accent,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        if (rows.isEmpty)
          Text(
            '—',
            style: TextStyle(color: Colors.white38, fontSize: 10),
          )
        else
          for (var i = 0; i < rows.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '${i + 1}. ${rows[i].name}  ${rows[i].pointsLabel}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
      ],
    );
  }

  static List<_Rank> _rank(
    List<GiftRecentItem> recent,
    String hostLabel,
    String? hostUserId,
  ) {
    final totals = <String, _Rank>{};
    final label = hostLabel.trim().toLowerCase();
    final uid = hostUserId?.trim() ?? '';
    for (final g in recent) {
      if (!_targetsHost(g, label, uid)) continue;
      final key = g.senderId.isNotEmpty ? g.senderId : g.senderName;
      if (key.isEmpty) continue;
      final name = g.senderName.trim().isNotEmpty ? g.senderName.trim() : 'İzleyici';
      final prev = totals[key];
      final add = g.jetonAmount > 0 ? g.jetonAmount : 1;
      totals[key] = _Rank(
        name: name,
        pointsValue: (prev?.pointsValue ?? 0) + add,
      );
    }
    final list = totals.values.toList()
      ..sort((a, b) => b.pointsValue.compareTo(a.pointsValue));
    return list.take(3).toList();
  }

  static bool _targetsHost(GiftRecentItem g, String hostLabel, String hostUserId) {
    final recv = g.receiverName.trim().toLowerCase();
    if (hostLabel.isNotEmpty && recv == hostLabel) return true;
    if (hostLabel.isNotEmpty && recv.contains(hostLabel)) return true;
    if (hostUserId.isNotEmpty && g.receiverName.contains(hostUserId)) return true;
    return false;
  }
}

class _Rank {
  const _Rank({required this.name, required this.pointsValue});

  final String name;
  final int pointsValue;

  String get pointsLabel => _fmt(pointsValue);

  static String _fmt(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
