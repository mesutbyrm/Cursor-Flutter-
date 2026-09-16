import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../profile/presentation/providers/profile_providers.dart';

/// Yayıncı bilgisi — video üstü gradient chip (+ isteğe bağlı takip).
class LivePkStreamerChip extends ConsumerStatefulWidget {
  const LivePkStreamerChip({
    super.key,
    required this.displayName,
    this.avatarUrl,
    this.micOn = true,
    this.cameraOn = true,
    this.isLocal = false,
    this.alignment = Alignment.topLeft,
    this.userId,
    this.showFollow = false,
    this.leagueLabel,
  });

  final String displayName;
  final String? avatarUrl;
  final bool micOn;
  final bool cameraOn;
  final bool isLocal;
  final Alignment alignment;
  final String? userId;
  final bool showFollow;
  final String? leagueLabel;

  @override
  ConsumerState<LivePkStreamerChip> createState() => _LivePkStreamerChipState();
}

class _LivePkStreamerChipState extends ConsumerState<LivePkStreamerChip> {
  var _following = false;
  var _followLoading = false;
  var _loadedProfile = false;
  var _verified = false;
  var _followersCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void didUpdateWidget(covariant LivePkStreamerChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _loadedProfile = false;
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    final id = widget.userId?.trim() ?? '';
    if (id.isEmpty || widget.isLocal) {
      if (mounted) setState(() => _loadedProfile = true);
      return;
    }
    try {
      final profile = await ref.read(profileRepositoryProvider).getUser(id);
      if (mounted) {
        setState(() {
          _following = profile.isFollowing;
          _verified = profile.isVerified;
          _followersCount = profile.followersCount;
          _loadedProfile = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadedProfile = true);
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

  @override
  Widget build(BuildContext context) {
    final left = widget.alignment == Alignment.topLeft;
    final showFollowBtn = widget.showFollow &&
        !widget.isLocal &&
        (widget.userId?.trim().isNotEmpty ?? false) &&
        _loadedProfile &&
        !_following;

    return Positioned(
      top: 8,
      left: left ? 8 : null,
      right: left ? null : 8,
      child: Column(
        crossAxisAlignment:
            left ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Colors.black.withValues(alpha: 0.72),
              Colors.black.withValues(alpha: 0.2),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Avatar(url: widget.avatarUrl, name: widget.displayName),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * 0.2,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        widget.isLocal
                            ? 'Sen · ${widget.displayName}'
                            : widget.displayName,
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
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.verified_rounded,
                        color: Color(0xFF448AFF),
                        size: 14,
                      ),
                    ],
                  ],
                ),
              ),
              if (_followersCount > 0) ...[
                const SizedBox(width: 6),
                const Icon(Icons.local_fire_department_rounded,
                    color: Color(0xFFFF7043), size: 14),
                Text(
                  _fmtCount(_followersCount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ],
              const SizedBox(width: 6),
              Icon(
                widget.micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                size: 14,
                color: widget.micOn ? Colors.white : Colors.redAccent,
              ),
              const SizedBox(width: 4),
              Icon(
                widget.cameraOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                size: 14,
                color: widget.cameraOn ? Colors.white : Colors.redAccent,
              ),
              if (showFollowBtn) ...[
                const SizedBox(width: 6),
                Material(
                  color: const Color(0xFFFF2D7A),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: _followLoading ? null : _toggleFollow,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: _followLoading
                          ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              '+ Takip et',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
          if (widget.leagueLabel != null &&
              widget.leagueLabel!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: _LeagueBadge(label: widget.leagueLabel!.trim()),
            ),
        ],
      ),
    );
  }

  static String _fmtCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _LeagueBadge extends StatelessWidget {
  const _LeagueBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD54F), Color(0xFFFFA000)],
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.diamond_rounded, size: 10, color: Color(0xFF3E2723)),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF3E2723),
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.url, required this.name});

  final String? url;
  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    if (url != null && url!.trim().isNotEmpty) {
      return ClipOval(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CanlifalNetworkImage(url: url!, fit: BoxFit.cover),
        ),
      );
    }
    return CircleAvatar(
      radius: 14,
      backgroundColor: const Color(0xFFB832FF).withValues(alpha: 0.5),
      child: Text(initial, style: const TextStyle(fontSize: 11, color: Colors.white)),
    );
  }
}
