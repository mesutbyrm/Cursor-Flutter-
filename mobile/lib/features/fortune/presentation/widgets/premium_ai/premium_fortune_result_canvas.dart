import 'dart:ui';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../domain/entities/fortune_reading_section.dart';
import '../../../domain/entities/fortune_type_entity.dart';
import '../../services/fortune_reading_headlines.dart';
import '../premium_2026/cinematic_fortune_hero.dart';
import 'fortune_dynamic_background.dart';

/// Fal sonucu — sinematik hero, başlık kartı, glass bölümler, animasyonlar.
class PremiumFortuneResultCanvas extends StatefulWidget {
  const PremiumFortuneResultCanvas({
    super.key,
    required this.result,
    this.onShare,
    this.scrollController,
    this.readingSectionKey,
    this.appBarTitle = 'Fal Sonucu',
    this.showTopBar = true,
    this.header,
    this.footer,
  });

  final FortuneReadingResult result;
  final VoidCallback? onShare;
  final ScrollController? scrollController;
  final GlobalKey? readingSectionKey;
  final String appBarTitle;
  final bool showTopBar;
  final Widget? header;
  final Widget? footer;

  @override
  State<PremiumFortuneResultCanvas> createState() =>
      _PremiumFortuneResultCanvasState();
}

class _PremiumFortuneResultCanvasState extends State<PremiumFortuneResultCanvas> {
  final _visibleSections = <String>{};
  double _scrollOffset = 0;

  List<FortuneReadingSection> get _sections {
    if (widget.result.sections.isNotEmpty) return widget.result.sections;
    return [
      FortuneReadingSection(
        key: FortuneSectionKeys.general,
        title: FortuneSectionKeys.titles[FortuneSectionKeys.general]!,
        body: widget.result.detail,
        delaySeconds: 1,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    widget.scrollController?.addListener(_onScroll);
    _scheduleReveals();
  }

  @override
  void didUpdateWidget(covariant PremiumFortuneResultCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController?.removeListener(_onScroll);
      widget.scrollController?.addListener(_onScroll);
    }
    if (oldWidget.result != widget.result) {
      _visibleSections.clear();
      _scheduleReveals();
    }
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final offset = widget.scrollController?.offset ?? 0;
    if ((offset - _scrollOffset).abs() > 1) {
      setState(() => _scrollOffset = offset);
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
    final headline = FortuneReadingHeadlines.headlineFor(result);
    final energyTag = FortuneReadingHeadlines.energyTagFor(result);
    final glow = result.type.accent;

    return RepaintBoundary(
      child: FortuneDynamicBackground(
        type: result.type,
        child: Column(
          children: [
            if (widget.showTopBar)
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          widget.appBarTitle,
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
              ),
            Expanded(
              child: ListView(
                controller: widget.scrollController,
                padding: EdgeInsets.zero,
                children: [
                  if (widget.header != null) widget.header!,
                  CinematicFortuneHero(
                    type: result.type,
                    height: widget.header != null ? 220 : 320,
                    scrollOffset: _scrollOffset,
                    showTitle: widget.header == null,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.header == null)
                          _HeadlineCard(
                            headline: headline,
                            summary: result.summary,
                            energyTag: energyTag,
                            accent: glow,
                          ).animate().fadeIn(duration: 500.ms).slideY(
                                begin: 0.06,
                                end: 0,
                                curve: Curves.easeOutCubic,
                              )
                        else ...[
                          Text(
                            'Yapay Zeka Yorumu',
                            style: TextStyle(
                              color: glow.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (result.visualAnalysis != null) ...[
                          const SizedBox(height: 12),
                          _GlassPanel(
                            accent: glow,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.visibility_rounded,
                                  color: glow.withValues(alpha: 0.9),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
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
                          ).animate().fadeIn(delay: 200.ms),
                        ],
                        const SizedBox(height: 16),
                        KeyedSubtree(
                          key: widget.readingSectionKey,
                          child: Column(
                            children: [
                              for (final section in _sections)
                                _AnimatedSectionBlock(
                                  visible: _visibleSections.contains(section.key),
                                  section: section,
                                  accent: glow,
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
                                    color: glow,
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
                        if (widget.footer != null) widget.footer!,
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

class _HeadlineCard extends StatelessWidget {
  const _HeadlineCard({
    required this.headline,
    required this.summary,
    required this.energyTag,
    required this.accent,
  });

  final String headline;
  final String summary;
  final String energyTag;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      accent: accent,
      glowPulse: true,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: accent.withValues(alpha: 0.2),
              border: Border.all(color: accent.withValues(alpha: 0.45)),
            ),
            child: Text(
              energyTag,
              style: TextStyle(
                color: accent.withValues(alpha: 0.95),
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.6,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            headline,
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 26,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            summary,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedSectionBlock extends StatelessWidget {
  const _AnimatedSectionBlock({
    required this.visible,
    required this.section,
    required this.accent,
  });

  final bool visible;
  final FortuneReadingSection section;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final label = FortuneReadingHeadlines.sectionLabel(section.key);
    final icon = FortuneReadingHeadlines.sectionIcon(section.key);
    final bodyStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.9),
      fontSize: 14,
      height: 1.55,
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
                  Row(
                    children: [
                      Icon(icon, color: accent.withValues(alpha: 0.95), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: TextStyle(
                          color: accent.withValues(alpha: 0.95),
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (visible && section.key == FortuneSectionKeys.general)
                    AnimatedTextKit(
                      animatedTexts: [
                        TypewriterAnimatedText(
                          section.body,
                          textStyle: bodyStyle,
                          speed: const Duration(milliseconds: 12),
                        ),
                      ],
                      totalRepeatCount: 1,
                      displayFullTextOnTap: true,
                    )
                  else if (visible)
                    Text(section.body, style: bodyStyle),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate(target: visible ? 1 : 0).shimmer(
          duration: 1800.ms,
          color: accent.withValues(alpha: 0.08),
        );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    required this.child,
    this.accent,
    this.glowPulse = false,
  });

  final Widget child;
  final Color? accent;
  final bool glowPulse;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? Colors.white;

    Widget panel = ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.22)),
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.12),
                Colors.black.withValues(alpha: 0.35),
              ],
            ),
            boxShadow: glowPulse
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: child,
        ),
      ),
    );

    if (glowPulse) {
      panel = panel
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .boxShadow(
            end: BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 24,
              spreadRadius: 2,
            ),
            duration: 2200.ms,
          );
    }

    return panel;
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
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
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
