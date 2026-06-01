import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../theme/voice_room_tokens.dart';

/// Konuşurken nabız animasyonlu neon halka.
class VoiceNeonAvatar extends StatefulWidget {
  const VoiceNeonAvatar({
    super.key,
    this.url,
    this.size = 72,
    this.speaking = false,
    this.showCrown = false,
    this.roleLabel,
    this.onTap,
  });

  final String? url;
  final double size;
  final bool speaking;
  final bool showCrown;
  final String? roleLabel;
  final VoidCallback? onTap;

  @override
  State<VoiceNeonAvatar> createState() => _VoiceNeonAvatarState();
}

class _VoiceNeonAvatarState extends State<VoiceNeonAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant VoiceNeonAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();
  }

  void _syncPulse() {
    if (widget.speaking) {
      _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const ring = 2.0;
    final inner = widget.size - ring * 2;
    final avatar = GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final glow = widget.speaking ? 6 + _pulse.value * 10 : 4.0;
          return Container(
            width: widget.size,
            height: widget.size,
            padding: const EdgeInsets.all(ring),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: widget.speaking
                  ? VoiceRoomTokens.neonRing
                  : LinearGradient(
                      colors: [
                        VoiceRoomTokens.neonPurple.withValues(alpha: 0.7),
                        VoiceRoomTokens.neonBlue.withValues(alpha: 0.5),
                      ],
                    ),
              boxShadow: widget.speaking
                  ? VoiceRoomTokens.neonGlow(
                      VoiceRoomTokens.neonPink,
                      blur: glow,
                    )
                  : null,
            ),
            child: child,
          );
        },
        child: ClipOval(
          child: SizedBox(
            width: inner,
            height: inner,
            child: widget.url != null && widget.url!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: widget.url!,
                    width: inner,
                    height: inner,
                    fit: BoxFit.cover,
                  )
                : ColoredBox(
                    color: AppColors.bgPurpleGlow,
                    child: Icon(
                      Icons.person_rounded,
                      size: inner * 0.45,
                      color: Colors.white54,
                    ),
                  ),
          ),
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            avatar,
            if (widget.showCrown)
              Positioned(
                top: -6,
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.coinGold,
                  size: widget.size * 0.28,
                ),
              ),
            if (widget.speaking)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.onlineGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mic_rounded, size: 12, color: Colors.white),
                ),
              ),
          ],
        ),
        if (widget.roleLabel != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.roleLabel!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: widget.size > 64 ? 11 : 9,
              fontWeight: FontWeight.w800,
              color: widget.showCrown ? AppColors.coinGold : Colors.white,
            ),
          ),
        ],
      ],
    );
  }
}
