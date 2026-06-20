import 'package:flutter/material.dart';

import '../../../domain/entities/fortune_type_entity.dart';

/// Fal sonucu aksiyon hiyerarşisi — Yorum → Paylaş → Sosyalde Paylaş.
class FortuneResultActionPanel extends StatelessWidget {
  const FortuneResultActionPanel({
    super.key,
    required this.result,
    required this.onScrollToReading,
    required this.onShare,
    required this.onShareToSocial,
    required this.onBrowseMore,
    this.socialSharing = false,
    this.socialShared = false,
  });

  final FortuneReadingResult result;
  final VoidCallback onScrollToReading;
  final VoidCallback onShare;
  final VoidCallback onShareToSocial;
  final VoidCallback onBrowseMore;
  final bool socialSharing;
  final bool socialShared;

  @override
  Widget build(BuildContext context) {
    final accent = result.type.accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _SectionLabel('Yorum'),
        OutlinedButton.icon(
          onPressed: onScrollToReading,
          icon: const Icon(Icons.auto_stories_rounded, color: Colors.white70),
          label: const Text('Yorumu Oku', style: TextStyle(color: Colors.white)),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(46),
            side: BorderSide(color: accent.withValues(alpha: 0.5)),
          ),
        ),
        const SizedBox(height: 12),
        _SectionLabel('Fal Sonucu'),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: accent.withValues(alpha: 0.12),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: Text(
            result.summary,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, height: 1.4, fontSize: 13),
          ),
        ),
        const SizedBox(height: 12),
        _SectionLabel('Paylaş'),
        OutlinedButton.icon(
          onPressed: onShare,
          icon: const Icon(Icons.ios_share_rounded),
          label: const Text('Paylaş'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(46),
          ),
        ),
        const SizedBox(height: 10),
        _SectionLabel('SOSYALDE PAYLAŞ'),
        FilledButton.icon(
          onPressed: socialSharing ? null : onShareToSocial,
          icon: socialSharing
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                )
              : Icon(socialShared ? Icons.check_rounded : Icons.public_rounded),
          label: Text(
            socialShared ? 'Sosyal akışta paylaşıldı' : 'SOSYALDE PAYLAŞ',
          ),
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 12),
        _SectionLabel('Diğer'),
        FilledButton(
          onPressed: onBrowseMore,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.12),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(46),
          ),
          child: const Text('Diğer fallara göz at'),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.55),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
