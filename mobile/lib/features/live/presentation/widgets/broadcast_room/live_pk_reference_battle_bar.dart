import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../profile/presentation/providers/profile_providers.dart';

/// Referans PK tasarımı — başlık altındaki yayıncı bandı:
/// [sol yayıncı kartı | PK sayacı | sağ yayıncı kartı].
class LivePkReferenceStreamerBand extends StatelessWidget {
  const LivePkReferenceStreamerBand({
    super.key,
    required this.leftCard,
    required this.centerTimer,
    required this.rightCard,
  });

  final Widget leftCard;
  final Widget centerTimer;
  final Widget rightCard;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: leftCard),
          const SizedBox(width: 6),
          centerTimer,
          const SizedBox(width: 6),
          Expanded(child: rightCard),
        ],
      ),
    );
  }
}

/// Referans yayıncı kartı — avatar + isim + 🔥takipçi + "+Takip et".
class LivePkReferenceStreamerCard extends ConsumerStatefulWidget {
  const LivePkReferenceStreamerCard({
    super.key,
    required this.displayName,
    this.avatarUrl,
    this.userId,
    this.isLocal = false,
    this.showFollow = true,
    this.accent = const Color(0xFFFF2D6B),
  });

  final String displayName;
  final String? avatarUrl;
  final String? userId;
  final bool isLocal;
  final bool showFollow;
  final Color accent;

  @override
  ConsumerState<LivePkReferenceStreamerCard> createState() =>
      _LivePkReferenceStreamerCardState();
}

class _LivePkReferenceStreamerCardState
    extends ConsumerState<LivePkReferenceStreamerCard> {
  var _following = false;
  var _followLoading = false;
  var _loaded = false;
  var _verified = false;
  var _followers = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant LivePkReferenceStreamerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _loaded = false;
      _load();
    }
  }

  Future<void> _load() async {
    final id = widget.userId?.trim() ?? '';
    if (id.isEmpty) {
      if (mounted) setState(() => _loaded = true);
      return;
    }
    try {
      final p = await ref.read(profileRepositoryProvider).getUser(id);
      if (mounted) {
        setState(() {
          _following = p.isFollowing;
          _verified = p.isVerified;
          _followers = p.followersCount;
          _loaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _toggleFollow() async {
    final id = widget.userId?.trim() ?? '';
    if (id.isEmpty || _followLoading || _following) return;
    setState(() => _followLoading = true);
    try {
      await ref.read(profileRepositoryProvider).follow(id);
      if (mounted) setState(() => _following = true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Takip edilemedi')),
        );
      }
    } finally {
      if (mounted) setState(() => _followLoading = false);
    }
  }

  static String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    final showFollowBtn = widget.showFollow &&
        !widget.isLocal &&
        (widget.userId?.trim().isNotEmpty ?? false) &&
        _loaded &&
        !_following;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Avatar(url: widget.avatarUrl, name: widget.displayName, ring: widget.accent),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        widget.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (_verified) ...[
                      const SizedBox(width: 2),
                      const Icon(Icons.verified_rounded,
                          color: Color(0xFF448AFF), size: 13),
                    ],
                  ],
                ),
                if (_followers > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 10)),
                      const SizedBox(width: 2),
                      Text(
                        _fmt(_followers),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (showFollowBtn) ...[
            const SizedBox(width: 6),
            Material(
              color: widget.accent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: _followLoading ? null : _toggleFollow,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  child: _followLoading
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          '+ Takip et',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 10.5,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.url, required this.name, required this.ring});

  final String? url;
  final String name;
  final Color ring;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 38,
      height: 38,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ring, width: 2),
      ),
      child: ClipOval(
        child: (url != null && url!.trim().isNotEmpty)
            ? CanlifalNetworkImage(url: url!, fit: BoxFit.cover)
            : ColoredBox(
                color: const Color(0xFF2A2A35),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
      ),
    );
  }
}

/// Referans skor barı — kırmızı/mavi bölünmüş bar + yüzdeler + durum pili.
class LivePkReferenceScoreBar extends StatelessWidget {
  const LivePkReferenceScoreBar({
    super.key,
    required this.leftScore,
    required this.rightScore,
    this.statusText = 'PK devam ediyor!',
    this.showStatus = true,
  });

  final int leftScore;
  final int rightScore;
  final String statusText;
  final bool showStatus;

  static const _pink = Color(0xFFFF2D6B);
  static const _blue = Color(0xFF2E9BFF);

  static String _fmt(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final total = (leftScore + rightScore).clamp(1, 1 << 31);
    final leftPct = (leftScore / total * 100).round().clamp(1, 99);
    final rightPct = 100 - leftPct;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: 32,
              child: Row(
                children: [
                  Expanded(
                    flex: leftPct,
                    child: Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 12),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_pink, Color(0xFFFF5C8A)],
                        ),
                      ),
                      child: Text(
                        _fmt(leftScore),
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: rightPct,
                    child: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 12),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF4FC3F7), _blue],
                        ),
                      ),
                      child: Text(
                        _fmt(rightScore),
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 3),
          Stack(
            alignment: Alignment.center,
            children: [
              Row(
                children: [
                  Text(
                    '$leftPct%',
                    style: const TextStyle(
                      color: _pink,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$rightPct%',
                    style: const TextStyle(
                      color: _blue,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              if (showStatus)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16121F),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.8),
                      width: 1.1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('⚡', style: TextStyle(fontSize: 11)),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
