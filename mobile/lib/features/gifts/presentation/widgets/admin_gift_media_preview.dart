import 'package:flutter/material.dart';

import '../../domain/gift_media_spec.dart';
import '../../domain/gift_media_type.dart';
import 'gift_media_widget.dart';

/// Admin hediye editörü — görsel / video / ses önizlemesi.
class AdminGiftMediaPreview extends StatelessWidget {
  const AdminGiftMediaPreview({
    super.key,
    required this.url,
    this.size = 56,
    this.isAudio = false,
    this.animationType,
    this.thumbnailUrl,
    this.mediaWidth,
    this.mediaHeight,
  });

  final String? url;
  final double size;
  final bool isAudio;
  final String? animationType;
  final String? thumbnailUrl;
  final int? mediaWidth;
  final int? mediaHeight;

  @override
  Widget build(BuildContext context) {
    final mediaUrl = url;
    if (mediaUrl == null || mediaUrl.isEmpty) {
      return Icon(
        isAudio ? Icons.audiotrack_rounded : Icons.perm_media_rounded,
        color: const Color(0xFFB388FF),
      );
    }

    if (isAudio) {
      return const Icon(Icons.audiotrack_rounded, color: Color(0xFF66E36F));
    }

    final type = GiftMediaType.resolve(
      mediaType: animationType,
      assetType: animationType,
      url: mediaUrl,
    );

    return GiftMediaWidget(
      spec: GiftMediaSpec(
        mediaUrl: mediaUrl,
        thumbnailUrl: thumbnailUrl,
        mediaType: type,
        mediaWidth: mediaWidth,
        mediaHeight: mediaHeight,
      ),
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
