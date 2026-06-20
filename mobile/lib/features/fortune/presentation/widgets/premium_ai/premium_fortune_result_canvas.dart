import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../domain/entities/fortune_reading_section.dart';
import '../../../domain/entities/fortune_type_entity.dart';
import '../../data/fortune_type_images.dart';
import '../fortune_type_network_image.dart';
import 'fortune_dynamic_background.dart';
import 'fortune_image_shimmer.dart';
import 'fortune_typewriter_text.dart';

/// Fal metnini dinamik arka plan + glassmorphism + daktilo efekti ile gösterir.
class PremiumFortuneResultCanvas extends StatefulWidget {
  const PremiumFortuneResultCanvas({
    super.key,
    required this.result,
    this.onShare,
    this.scrollController,
    this.readingSectionKey,
  });

  final FortuneReadingResult result;
  final VoidCallback? onShare;
  final ScrollController? scrollController;
  final GlobalKey? readingSectionKey;

  @override
  State<PremiumFortuneResultCanvas> createState() =>
      _PremiumFortuneResultCanvasState();
}

class _PremiumFortuneResultCanvasState extends State<PremiumFortuneResultCanvas> {
  final _visibleSections = <String>{};

  List<FortuneReadingSection> get _sections {
    if (widget.result.sections.isNotEmpty) return widget.result.sections;
    return [
      FortuneReadingSection(
        key: 'detail',
        title: 'Yorumun',
        body: widget.result.detail,
        delaySeconds: 1,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _scheduleReveals();
  }

  @override
  void didUpdateWidget(covariant PremiumFortuneResultCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.result != widget.result) {
      _visibleSections.clear();
      _scheduleReveals();
    }
  }

  void _scheduleReveals() {
    for (final section in _sections) {
      Future<void>.delayed(
        Duration(seconds: section.delaySeconds),
        () {
          if (!mounted) return;
          setState(() => _visibleSections.add(section.key));
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final url = result.imageUrl;
    final heroTag = FortuneTypeImages.heroTagFor(result.type.slug);

    return RepaintBoundary(
      child: FortuneDynamicBackground(
        type: result.type,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url != null)
              Hero(
                tag: heroTag,
                child: Material(
                  type: MaterialType.transparency,
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => FortuneImageShimmer(
                      accent: result.type.accent,
                      emoji: result.type.emoji,
                    ),
                  ),
                ),
              )
            else
              FortuneTypeNetworkImage(
                slug: result.type.slug,
                accent: result.type.accent,
                emoji: result.type.emoji,
                borderRadius: 0,
                heroTag: heroTag,
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    Colors.black.withValues(alpha: 0.72),
                    const Color(0xFF0A0118).withValues(alpha: 0.94),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                        ),
                        Expanded(
                          child: Text(
                            '${result.type.title} — AI Yorumu',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: widget.onShare,
                          icon: const Icon(Icons.ios_share_rounded, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  if (result.visualAnalysis != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: _GlassPanel(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('🔮', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                result.visualAnalysis!,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.88),
                                  fontSize: 12,
                                  height: 1.35,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Expanded(
                    child: ListView(
                      controller: widget.scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        _GlassPanel(
                          child: Column(
                            children: [
                              Text(result.type.emoji, style: const TextStyle(fontSize: 40)),
                              const SizedBox(height: 8),
                              Text(
                                result.summary,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        KeyedSubtree(
                          key: widget.readingSectionKey,
                          child: Column(
                            children: [
                              for (final section in _sections)
                                _AnimatedSectionBlock(
                                  visible: _visibleSections.contains(section.key),
                                  section: section,
                                  accent: result.type.accent,
                                  useTypewriter: true,
                                ),
                            ],
                          ),
                        ),
                        if (result.luckyNumber != null || result.luckyColor != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              if (result.luckyNumber != null)
                                Expanded(
                                  child: _LuckyTile(
                                    label: 'Şanslı sayı',
                                    value: '${result.luckyNumber}',
                                    color: result.type.accent,
                                  ),
                                ),
                              if (result.luckyNumber != null && result.luckyColor != null)
                                const SizedBox(width: 10),
                              if (result.luckyColor != null)
                                Expanded(
                                  child: _LuckyTile(
                                    label: 'Şanslı renk',
                                    value: result.luckyColor!,
                                    color: Colors.cyanAccent,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedSectionBlock extends StatelessWidget {
  const _AnimatedSectionBlock({
    required this.visible,
    required this.section,
    required this.accent,
    this.useTypewriter = false,
  });

  final bool visible;
  final FortuneReadingSection section;
  final Color accent;
  final bool useTypewriter;

  @override
  Widget build(BuildContext context) {
    final bodyStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.9),
      fontSize: 14,
      height: 1.5,
    );

    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, 0.08),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: RepaintBoundary(
            child: _GlassPanel(
              accent: accent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.title,
                    style: TextStyle(
                      color: accent.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (visible && useTypewriter)
                    FortuneTypewriterText(
                      text: section.body,
                      style: bodyStyle,
                      charDuration: const Duration(milliseconds: 14),
                    )
                  else if (visible)
                    Text(section.body, style: bodyStyle),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child, this.accent});

  final Widget child;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: (accent ?? Colors.white).withValues(alpha: 0.22),
            ),
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.12),
                Colors.black.withValues(alpha: 0.35),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _LuckyTile extends StatelessWidget {
  const _LuckyTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        color: color.withValues(alpha: 0.12),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }
}
