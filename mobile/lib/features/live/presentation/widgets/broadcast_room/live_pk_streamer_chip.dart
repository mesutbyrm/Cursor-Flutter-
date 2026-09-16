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
  });

  final String displayName;
  final String? avatarUrl;
  final bool micOn;
  final bool cameraOn;
  final bool isLocal;
  final Alignment alignment;
  final String? userId;
  final bool showFollow;

  @override
  ConsumerState<LivePkStreamerChip> createState() => _LivePkStreamerChipState();
}

class _LivePkStreamerChipState extends ConsumerState<LivePkStreamerChip> {
  var _following = false;
  var _followLoading = false;
  var _loadedFollow = false;

  @override
  void initState() {
    super.initState();
    _loadFollow();
  }

  @override
  void didUpdateWidget(covariant LivePkStreamerChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _loadedFollow = false;
      _loadFollow();
    }
  }

  Future<void> _loadFollow() async {
    if (!widget.showFollow || widget.isLocal) return;
    final id = widget.userId?.trim() ?? '';
    if (id.isEmpty) return;
    try {
      final profile = await ref.read(profileRepositoryProvider).getUser(id);
      if (mounted) {
        setState(() {
          _following = profile.isFollowing;
          _loadedFollow = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadedFollow = true);
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
        _loadedFollow &&
        !_following;

    return Positioned(
      top: 8,
      left: left ? 8 : null,
      right: left ? null : 8,
      child: DecoratedBox(
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
                  maxWidth: MediaQuery.sizeOf(context).width * 0.22,
                ),
                child: Text(
                  widget.isLocal ? 'Sen · ${widget.displayName}' : widget.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
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
                              'Takip',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
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
