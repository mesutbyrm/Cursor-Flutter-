import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../theme/voice_room_tokens.dart';

/// TikTok Live tarzı üst bar — oda, takip, jeton, sıralama.
class VoiceLiveHeader2026 extends StatelessWidget {
  const VoiceLiveHeader2026({
    super.key,
    required this.room,
    required this.onlineCount,
    required this.coinBalance,
    required this.onBack,
    required this.onExit,
    this.onFollow,
    this.onShare,
    this.onAudience,
    this.onMore,
    this.hostAvatarUrl,
    this.following = false,
  });

  final VoiceRoomEntity room;
  final int onlineCount;
  final int coinBalance;
  final VoidCallback onBack;
  final VoidCallback onExit;
  final VoidCallback? onFollow;
  final VoidCallback? onShare;
  final VoidCallback? onAudience;
  final VoidCallback? onMore;
  final String? hostAvatarUrl;
  final bool following;

  @override
  Widget build(BuildContext context) {
    final shortId = room.apiRoomKey.length > 8
        ? room.apiRoomKey.substring(0, 8)
        : room.apiRoomKey;
    final onlineLabel = _formatCount(onlineCount);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              ),
              Expanded(child: _roomGlass(shortId, onlineLabel)),
              _coinPill(),
              IconButton(
                onPressed: onMore ?? onShare,
                icon: const Icon(Icons.more_horiz_rounded, color: Colors.white),
              ),
              IconButton(
                onPressed: onExit,
                icon: const Icon(
                  Icons.power_settings_new_rounded,
                  color: AppColors.liveRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _badge('🔥 Popüler No. 1', VoiceRoomTokens.followGradient),
              const SizedBox(width: 8),
              _badge('👑 Saatlik Sıralama', VoiceRoomTokens.goldRing),
              const Spacer(),
              GestureDetector(
                onTap: onAudience,
                child: _badge('👥 $onlineLabel', const LinearGradient(
                  colors: [Color(0xFF5B7CFF), Color(0xFF9B4DFF)],
                )),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _roomGlass(String shortId, String onlineLabel) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(VoiceRoomTokens.radiusCard),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: VoiceRoomTokens.glassCard(radius: VoiceRoomTokens.radiusCard),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white12,
                backgroundImage: hostAvatarUrl != null && hostAvatarUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(hostAvatarUrl!)
                    : null,
                child: hostAvatarUrl == null || hostAvatarUrl!.isEmpty
                    ? Text(room.icon ?? '🎤', style: const TextStyle(fontSize: 18))
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (b) =>
                          VoiceRoomTokens.titleGradient.createShader(b),
                      child: Text(
                        room.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                          ClipboardData(text: room.apiRoomKey),
                        );
                      },
                      child: Text(
                        'ID: $shortId · $onlineLabel çevrimiçi',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: onlineCount > 0
                              ? AppColors.onlineGreen
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (onFollow != null) ...[
                const SizedBox(width: 6),
                _followButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _followButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onFollow,
        borderRadius: BorderRadius.circular(VoiceRoomTokens.radiusPill),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            gradient: following ? null : VoiceRoomTokens.followGradient,
            color: following ? Colors.white12 : null,
            borderRadius: BorderRadius.circular(VoiceRoomTokens.radiusPill),
            boxShadow: following ? null : VoiceRoomTokens.neonGlow(VoiceRoomTokens.neonPink, blur: 12),
          ),
          child: Text(
            following ? 'Takipte' : 'Takip Et',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }

  Widget _coinPill() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.diamondBlue.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('💎', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            _formatCount(coinBalance),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 11,
              color: AppColors.diamondBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Gradient gradient) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: VoiceRoomTokens.neonGlow(VoiceRoomTokens.neonPurple, blur: 8),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
      ),
    );
  }

  static String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
