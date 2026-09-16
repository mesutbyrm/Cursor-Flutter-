import 'package:flutter/material.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

/// Yayıncı bilgisi — video üstü gradient chip.
class LivePkStreamerChip extends StatelessWidget {
  const LivePkStreamerChip({
    super.key,
    required this.displayName,
    this.avatarUrl,
    this.micOn = true,
    this.cameraOn = true,
    this.isLocal = false,
    this.alignment = Alignment.topLeft,
  });

  final String displayName;
  final String? avatarUrl;
  final bool micOn;
  final bool cameraOn;
  final bool isLocal;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final left = alignment == Alignment.topLeft;
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
              _Avatar(url: avatarUrl, name: displayName),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * 0.28,
                ),
                child: Text(
                  isLocal ? 'Sen · $displayName' : displayName,
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
                micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                size: 14,
                color: micOn ? Colors.white : Colors.redAccent,
              ),
              const SizedBox(width: 4),
              Icon(
                cameraOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                size: 14,
                color: cameraOn ? Colors.white : Colors.redAccent,
              ),
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
