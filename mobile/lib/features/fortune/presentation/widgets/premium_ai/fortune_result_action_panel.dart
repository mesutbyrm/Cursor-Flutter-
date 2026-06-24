import 'package:flutter/material.dart';

import '../../../domain/entities/fortune_type_entity.dart';

/// Fal sonucu alt aksiyonlar — paylaş ve keşfet.
class FortuneResultActionPanel extends StatelessWidget {
  const FortuneResultActionPanel({
    super.key,
    required this.result,
    required this.onShare,
    required this.onBrowseMore,
    this.socialSharing = false,
    this.socialShared = false,
    this.onShareToSocial,
  });

  final FortuneReadingResult result;
  final VoidCallback onShare;
  final VoidCallback onBrowseMore;
  final VoidCallback? onShareToSocial;
  final bool socialSharing;
  final bool socialShared;

  @override
  Widget build(BuildContext context) {
    final accent = result.type.accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Fal Sonucu',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: onShare,
          icon: const Icon(Icons.ios_share_rounded),
          label: const Text('Paylaş'),
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        if (onShareToSocial != null) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: socialSharing ? null : onShareToSocial,
            icon: Icon(socialShared ? Icons.check_rounded : Icons.public_rounded),
            label: Text(
              socialShared ? 'Sosyal akışta paylaşıldı' : 'Sosyal Bölümde Paylaş',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(46),
              side: BorderSide(color: accent.withValues(alpha: 0.45)),
            ),
          ),
        ],
        const SizedBox(height: 10),
        TextButton(
          onPressed: onBrowseMore,
          child: const Text('Diğer fallara göz at'),
        ),
      ],
    );
  }
}
