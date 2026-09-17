import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../profile/presentation/providers/profile_providers.dart';

/// TikTok tarzı — kamera alt-sol: avatar, ad, takip, PK puanı.
class LivePkPaneProfileFooter extends ConsumerStatefulWidget {
  const LivePkPaneProfileFooter({
    super.key,
    required this.displayName,
    this.avatarUrl,
    this.userId,
    this.pkScore = 0,
    this.isLocal = false,
    this.showFollow = false,
    this.followAccent = const Color(0xFFFF2D7A),
  });

  final String displayName;
  final String? avatarUrl;
  final String? userId;
  final int pkScore;
  final bool isLocal;
  final bool showFollow;
  final Color followAccent;

  @override
  ConsumerState<LivePkPaneProfileFooter> createState() =>
      _LivePkPaneProfileFooterState();
}

class _LivePkPaneProfileFooterState extends ConsumerState<LivePkPaneProfileFooter> {
  var _following = false;
  var _followLoading = false;
  var _verified = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant LivePkPaneProfileFooter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) _load();
  }

  Future<void> _load() async {
    final id = widget.userId?.trim() ?? '';
    if (id.isEmpty) return;
    try {
      final p = await ref.read(profileRepositoryProvider).getUser(id);
      if (mounted) {
        setState(() {
          _following = p.isFollowing;
          _verified = p.isVerified;
        });
      }
    } catch (_) {}
  }

  Future<void> _follow() async {
    final id = widget.userId?.trim() ?? '';
    if (id.isEmpty || _followLoading || _following) return;
    setState(() => _followLoading = true);
    try {
      await ref.read(profileRepositoryProvider).follow(id);
      if (mounted) setState(() => _following = true);
    } catch (_) {}
    if (mounted) setState(() => _followLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.displayName.trim().isNotEmpty
        ? widget.displayName.trim()
        : 'Yayıncı';
    final showFollowBtn = widget.showFollow &&
        !widget.isLocal &&
        (widget.userId?.trim().isNotEmpty ?? false) &&
        !_following;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.78),
            Colors.black.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _avatar(name),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          if (_verified) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified_rounded,
                              color: Color(0xFF448AFF),
                              size: 14,
                            ),
                          ],
                        ],
                      ),
                      if (showFollowBtn)
                        GestureDetector(
                          onTap: _followLoading ? null : _follow,
                          child: Text(
                            _followLoading ? '…' : '+ Takip Et',
                            style: TextStyle(
                              color: widget.followAccent,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        )
                      else if (_following && !widget.isLocal)
                        const Text(
                          'Takipte',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt_rounded, color: Color(0xFFFFD54F), size: 14),
                const SizedBox(width: 4),
                Text(
                  '${_fmtScore(widget.pkScore)} PK',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar(String name) {
    final url = widget.avatarUrl?.trim() ?? '';
    if (url.isNotEmpty) {
      return ClipOval(
        child: SizedBox(
          width: 34,
          height: 34,
          child: CanlifalNetworkImage(url: url, fit: BoxFit.cover),
        ),
      );
    }
    return CircleAvatar(
      radius: 17,
      backgroundColor: const Color(0xFF7C3AED).withValues(alpha: 0.55),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
      ),
    );
  }

  static String _fmtScore(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
