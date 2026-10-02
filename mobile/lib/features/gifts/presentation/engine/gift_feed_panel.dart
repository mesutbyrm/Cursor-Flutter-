import 'package:canlifal_social/core/images/canlifal_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/gift_engine_models.dart';
import '../sync/gift_session_controller.dart';

/// Ardışık, aynı gönderen + aynı hediye satırlarını tek satırda toplar
/// («Aslan x1, x2, x3» yerine «Aslan x6»). En yeni satır önde kalır.
List<GiftFeedRow> mergeGiftFeedItems(List<GiftFeedItem> items) {
  final rows = <GiftFeedRow>[];
  for (final item in items) {
    final n = item.combo < 1 ? 1 : item.combo;
    final existing = rows.indexWhere(
      (r) => r.senderName == item.senderName && r.giftName == item.giftName,
    );
    if (existing >= 0) {
      rows[existing] = rows[existing].plus(n);
    } else {
      rows.add(GiftFeedRow.from(item, n));
    }
  }
  return rows;
}

class GiftFeedRow {
  const GiftFeedRow({
    required this.key,
    required this.senderName,
    required this.giftName,
    required this.count,
    this.iconUrl,
    this.giftIcon,
  });

  factory GiftFeedRow.from(GiftFeedItem i, int count) => GiftFeedRow(
        key: '${i.senderName}|${i.giftName}',
        senderName: i.senderName,
        giftName: i.giftName,
        count: count,
        iconUrl: i.iconUrl,
        giftIcon: i.giftIcon,
      );

  final String key;
  final String senderName;
  final String giftName;
  final int count;
  final String? iconUrl;
  final String? giftIcon;

  GiftFeedRow plus(int n) => GiftFeedRow(
        key: key,
        senderName: senderName,
        giftName: giftName,
        count: count + n,
        iconUrl: iconUrl,
        giftIcon: giftIcon,
      );
}

/// Sol tarafta hediye akışı (TikTok/BIGO): avatar + «Ad / Hediye gönderdi» +
/// hediye ikonu + büyük «xN». Birleştirilmiş, en fazla 3 satır.
class GiftFeedPanel extends ConsumerWidget {
  const GiftFeedPanel({
    super.key,
    required this.sessionKey,
    this.maxWidth = 270,
    this.topFraction = 0.40,
  });

  final String sessionKey;
  final double maxWidth;

  /// Akışın ekran yüksekliğine göre üst konumu (PK'da sahnenin altına iner).
  final double topFraction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(
      giftSessionProvider(sessionKey).select((s) => s.feedItems),
    );
    if (items.isEmpty) return const SizedBox.shrink();
    final rows = mergeGiftFeedItems(items).take(3).toList();

    return Positioned(
      left: 12,
      top: MediaQuery.sizeOf(context).height * topFraction,
      width: maxWidth,
      child: IgnorePointer(
        child: RepaintBoundary(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [for (final r in rows) _FeedRow(row: r)],
          ),
        ),
      ),
    );
  }
}

class _FeedRow extends StatelessWidget {
  const _FeedRow({required this.row});

  final GiftFeedRow row;

  @override
  Widget build(BuildContext context) {
    final icon = row.giftIcon?.trim();
    final iconUrl = row.iconUrl;
    final initial = row.senderName.trim().isNotEmpty
        ? row.senderName.trim()[0].toUpperCase()
        : '?';

    return Container(
      key: ValueKey(row.key),
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(5, 5, 10, 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: [
            Colors.black.withValues(alpha: 0.5),
            Colors.black.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: const Color(0xFF7C3AED),
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  row.senderName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${row.giftName} gönderdi',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          if (icon != null && icon.isNotEmpty)
            Text(icon, style: const TextStyle(fontSize: 28))
          else if (iconUrl != null && iconUrl.isNotEmpty)
            CanlifalNetworkImage(
              url: iconUrl,
              width: 34,
              height: 34,
              fit: BoxFit.contain,
            ),
          const SizedBox(width: 6),
          // Sayı her arttığında kısa «pop» animasyonu.
          TweenAnimationBuilder<double>(
            key: ValueKey('${row.key}|${row.count}'),
            tween: Tween(begin: 1.5, end: 1),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (r) => const LinearGradient(
                colors: [Color(0xFFFFE082), Color(0xFFFF7043)],
              ).createShader(r),
              child: Text(
                'x${row.count}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    )
        .animate(key: ValueKey('in-${row.key}'))
        .fadeIn(duration: 200.ms)
        .slideX(begin: -0.25, end: 0, duration: 260.ms, curve: Curves.easeOutCubic);
  }
}
