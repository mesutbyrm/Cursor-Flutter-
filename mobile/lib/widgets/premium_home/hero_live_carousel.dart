import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../models/premium_live_stream.dart';
import '../../theme/premium_live_theme.dart';
import '../../constants/premium_home_layout.dart';

class HeroLiveCarousel extends StatefulWidget {
  const HeroLiveCarousel({super.key, required this.streams});

  final List<PremiumLiveStream> streams;

  @override
  State<HeroLiveCarousel> createState() => _HeroLiveCarouselState();
}

class _HeroLiveCarouselState extends State<HeroLiveCarousel> {
  int _active = 0;

  @override
  Widget build(BuildContext context) {
    final h = (42.h).clamp(260.0, 380.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeroTitle()
            .animate()
            .fadeIn(duration: 500.ms)
            .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
        SizedBox(height: 1.6.h),
        CarouselSlider.builder(
          itemCount: widget.streams.length,
          options: CarouselOptions(
            height: h,
            viewportFraction: 0.78,
            enlargeCenterPage: true,
            enlargeFactor: 0.16,
            padEnds: true,
            clipBehavior: Clip.none,
            onPageChanged: (i, _) => setState(() => _active = i),
          ),
          itemBuilder: (context, index, _) {
            final s = widget.streams[index];
            return _HeroLiveCard(stream: s, index: index);
          },
        ),
        SizedBox(height: 1.4.h),
        Center(
          child: AnimatedSmoothIndicator(
            activeIndex: _active,
            count: widget.streams.length,
            effect: ExpandingDotsEffect(
              dotHeight: 6,
              dotWidth: 6,
              expansionFactor: 3.2,
              spacing: 6,
              activeDotColor: PremiumLiveTheme.neonPink,
              dotColor: Colors.white.withValues(alpha: 0.22),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.plusJakartaSans(
      fontSize: 17.5.sp,
      fontWeight: FontWeight.w800,
      height: 1.25,
      color: Colors.white,
      letterSpacing: -0.3,
    );
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 1.w),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('Canlı yayınlara ', style: base),
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (b) =>
                PremiumLiveTheme.heroTitleGradient.createShader(b),
            child: Text(
              'katıl, eğlenceye ',
              style: base.copyWith(color: Colors.white),
            ),
          ),
          Text('ortak ol!', style: base),
        ],
      ),
    );
  }
}

class _HeroLiveCard extends StatelessWidget {
  const _HeroLiveCard({required this.stream, required this.index});

  final PremiumLiveStream stream;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(PremiumHomeLayout.cardRadius),
          onTap: () {},
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(PremiumHomeLayout.cardRadius),
              boxShadow: [
                BoxShadow(
                  color: PremiumLiveTheme.neonPink.withValues(alpha: 0.22),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(PremiumHomeLayout.cardRadius),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    stream.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: PremiumLiveTheme.deepPurple,
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded /
                                    progress.expectedTotalBytes!
                                : null,
                            color: PremiumLiveTheme.neonPink,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF2D1B69), Color(0xFF0D0618)],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.live_tv_rounded,
                          size: 48, color: PremiumLiveTheme.neonPink),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.15),
                            Colors.black.withValues(alpha: 0.05),
                            Colors.black.withValues(alpha: 0.82),
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.45),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Text(
                        'LIVE',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 88,
                    child: _AudioPulse()
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          duration: 900.ms,
                          begin: const Offset(1, 1),
                          end: const Offset(1.08, 1.08),
                        ),
                  ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                stream.streamerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 17.sp,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (stream.verified)
                              Icon(Icons.verified_rounded,
                                  color: PremiumLiveTheme.neonPurple, size: 20.sp),
                          ],
                        ),
                        SizedBox(height: 0.4.h),
                        Text(
                          stream.categoryLabel,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.78),
                          ),
                        ),
                        SizedBox(height: 0.8.h),
                        Row(
                          children: [
                            Icon(Icons.remove_red_eye_outlined,
                                size: 15.sp, color: Colors.white70),
                            SizedBox(width: 1.w),
                            Text(
                              _formatViewers(stream.viewers),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            _AvatarStack(urls: stream.avatarUrls),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate(delay: (index * 90).ms)
        .fadeIn(duration: 450.ms)
        .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic);
  }

  static String _formatViewers(int n) {
    return NumberFormat.decimalPattern('tr_TR').format(n);
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    final take = urls.take(4).toList();
    return SizedBox(
      width: 18.0 + (take.length.clamp(0, 4) - 1) * 14.0,
      height: 28,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < take.length; i++)
            Positioned(
              left: i * 14.0,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.network(
                    take[i],
                    width: 26,
                    height: 26,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => ColoredBox(
                      color: PremiumLiveTheme.cosmicPurple,
                      child: Icon(Icons.person, size: 14, color: Colors.white54),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AudioPulse extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PremiumLiveTheme.neonPink.withValues(alpha: 0.5)),
      ),
      child: Icon(
        Icons.graphic_eq_rounded,
        color: PremiumLiveTheme.neonPink,
        size: 22.sp,
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          duration: 700.ms,
          begin: const Offset(1, 1),
          end: const Offset(1.12, 1.12),
          curve: Curves.easeInOut,
        );
  }
}
