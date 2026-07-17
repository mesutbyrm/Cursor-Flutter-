import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../../../core/widgets/user_avatar.dart';
import '../../../../domain/entities/live_broadcast_session.dart';
import '../../../providers/live_gift_leaderboard_provider.dart';

/// Mockup üst bar — yayıncı bilgisi, takip, rozetler, top hediye atanlar, izleyici.
class LivePremiumTopBar extends StatelessWidget {
  const LivePremiumTopBar({
    super.key,
    required this.session,
    required this.elapsedBadge,
    required this.following,
    required this.followLoading,
    required this.onFollow,
    required this.onClose,
    this.onBack,
    this.onProfileTap,
    this.onViewersTap,
    this.onDiscoverTap,
    this.topGifters = const [],
    this.popularRank,
    this.leagueLabel,
  });

  final LiveBroadcastSession session;
  final Widget elapsedBadge;
  final bool following;
  final bool followLoading;
  final VoidCallback onFollow;
  final VoidCallback onClose;
  final VoidCallback? onBack;
  final VoidCallback? onProfileTap;
  final VoidCallback? onViewersTap;
  final VoidCallback? onDiscoverTap;
  final List<LiveGiftSender> topGifters;
  final int? popularRank;
  final String? leagueLabel;

  @override
  Widget build(BuildContext context) {
    final displayId = _displayId(session);
    final name = session.streamerName ?? 'Yayıncı';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (onBack != null)
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(6, 5, 8, 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.48),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: onProfileTap,
                          child: UserAvatar(url: session.avatarUrl, radius: 18),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'ID: $displayId',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!session.isHost && !following)
                          _FollowChip(loading: followLoading, onTap: onFollow),
                        if (following && !session.isHost)
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Text(
                              'Takipte',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _TopGiftersRow(gifters: topGifters, onTap: onViewersTap),
            const SizedBox(width: 6),
            _ViewerPill(
              count: session.viewerCount,
              onTap: onViewersTap,
            ),
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, size: 22, color: Colors.white),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            if (popularRank != null)
              _BadgeChip(
                emoji: '🔥',
                label: 'Popüler No. $popularRank',
                color: const Color(0xFFFF6B35),
              ),
            if (popularRank != null && (leagueLabel ?? '').isNotEmpty)
              const SizedBox(width: 6),
            if ((leagueLabel ?? '').isNotEmpty)
              _BadgeChip(
                emoji: '💎',
                label: leagueLabel!,
                color: const Color(0xFF7C4DFF),
              ),
            const Spacer(),
            if (onDiscoverTap != null)
              GestureDetector(
                onTap: onDiscoverTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.card_giftcard_rounded,
                          size: 14, color: Color(0xFFFFD54F)),
                      SizedBox(width: 4),
                      Text(
                        'Keşfet >',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(width: 6),
            elapsedBadge,
          ],
        ),
      ],
    );
  }

  static String _displayId(LiveBroadcastSession s) {
    final handle = s.streamerHandle?.trim();
    if (handle != null && handle.isNotEmpty && handle != 'yayinci') {
      return handle;
    }
    final host = s.hostUserId?.trim();
    if (host != null && host.isNotEmpty) {
      if (host.length <= 9) return host;
      final digits = host.replaceAll(RegExp(r'\D'), '');
      if (digits.length >= 6) return digits.substring(digits.length - 7);
      return host.substring(0, 7);
    }
    final sid = s.streamId?.trim();
    if (sid != null && sid.isNotEmpty) {
      return sid.length <= 8 ? sid : sid.substring(sid.length - 7);
    }
    return '—';
  }
}

class LiveElapsedTimePill extends StatefulWidget {
  const LiveElapsedTimePill({super.key});

  @override
  State<LiveElapsedTimePill> createState() => _LiveElapsedTimePillState();
}

class _LiveElapsedTimePillState extends State<LiveElapsedTimePill> {
  late final Timer _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = _elapsed.inHours.toString().padLeft(2, '0');
    final m = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$h:$m:$s',
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 11,
          color: Colors.white70,
        ),
      ),
    );
  }
}

class _FollowChip extends StatelessWidget {
  const _FollowChip({required this.loading, required this.onTap});

  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF9C27FF), Color(0xFF7C4DFF)],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: loading
              ? const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  '+ Takip Et',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                ),
        ),
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({
    required this.emoji,
    required this.label,
    required this.color,
  });

  final String emoji;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$emoji $label',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _ViewerPill extends StatelessWidget {
  const _ViewerPill({required this.count, this.onTap});

  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_rounded, size: 14, color: Colors.white70),
          const SizedBox(width: 3),
          Text(
            _fmt(count),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 11,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return pill;
    return GestureDetector(onTap: onTap, child: pill);
  }

  static String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) {
      final s = n.toString();
      if (n >= 10000) {
        final withDot = StringBuffer();
        for (var i = 0; i < s.length; i++) {
          if (i > 0 && (s.length - i) % 3 == 0) withDot.write('.');
          withDot.write(s[i]);
        }
        return withDot.toString();
      }
      return '${(n / 1000).toStringAsFixed(1)}K';
    }
    return '$n';
  }
}

class _TopGiftersRow extends StatelessWidget {
  const _TopGiftersRow({required this.gifters, this.onTap});

  final List<LiveGiftSender> gifters;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final top = gifters.take(3).toList();
    if (top.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 22.0 + (top.length - 1) * 16.0 + 8,
        height: 36,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < top.length; i++)
              Positioned(
                left: i * 16.0,
                child: _TopGifterAvatar(
                  sender: top[i],
                  rank: i + 1,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TopGifterAvatar extends StatelessWidget {
  const _TopGifterAvatar({required this.sender, required this.rank});

  final LiveGiftSender sender;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final crown = switch (rank) {
      1 => const Color(0xFFFFD700),
      2 => const Color(0xFFC0C0C0),
      _ => const Color(0xFFCD7F32),
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: crown, width: 1.5),
              ),
              child: ClipOval(
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: sender.avatarUrl != null && sender.avatarUrl!.isNotEmpty
                      ? CanlifalNetworkImage(
                          url: sender.avatarUrl!,
                          fit: BoxFit.cover,
                        )
                      : ColoredBox(
                          color: AppThemeColors.accentPurple,
                          child: Center(
                            child: Text(
                              sender.username.isNotEmpty
                                  ? sender.username[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ),
            Positioned(
              top: -6,
              right: -2,
              child: Text(
                '👑',
                style: TextStyle(fontSize: 9, color: crown),
              ),
            ),
          ],
        ),
        Text(
          _shortCoins(sender.totalCoins),
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w900,
            color: crown,
            height: 1.1,
          ),
        ),
      ],
    );
  }

  static String _shortCoins(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
