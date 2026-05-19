import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../models/premium_live_stream.dart';
import '../../theme/premium_live_theme.dart';
import '../../constants/premium_home_layout.dart';
import 'premium_carousel_bar_indicator.dart';

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
            viewportFraction: 0.8,
            enlargeCenterPage: true,
            enlargeFactor: 0.14,
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
          child: PremiumCarouselBarIndicator(
            count: widget.streams.length,
            activeIndex: _active,
          ),
        ),
      ],
    );
  }
}

class _HeroTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.montserrat(
      fontSize: 17.5.sp,
      fontWeight: FontWeight.w800,
      height: 1.22,
      color: Colors.white,
      letterSpacing: -0.35,
    );
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 1.w),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 0,
        runSpacing: 6,
        children: [
          Text('Canlı yayınlara ', style: base),
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (b) =>
                PremiumLiveTheme.heroTitleGradient.createShader(b),
            child: Text(
              'katıl, eğlenceye',
              style: base.copyWith(color: Colors.white),
            ),
          ),
          Text(' ortak ol! ', style: base),
          Text('❤️', style: base.copyWith(fontSize: 19.sp)),
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
    final r = PremiumHomeLayout.cardRadius;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(r + 2),
          onTap: () {},
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(r + 2),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  PremiumLiveTheme.neonPink.withValues(alpha: 0.65),
                  PremiumLiveTheme.neonPurple.withValues(alpha: 0.4),
                  PremiumLiveTheme.primaryViolet.withValues(alpha: 0.35),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: PremiumLiveTheme.neonPink.withValues(alpha: 0.28),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            padding: const EdgeInsets.all(2),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(r),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: stream.heroBackdropColors,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: CachedNetworkImage(
                      imageUrl: stream.imageUrl,
                      fit: BoxFit.cover,
                      fadeInDuration: const Duration(milliseconds: 280),
                      fadeOutDuration: const Duration(milliseconds: 120),
                      placeholder: (_, __) => const SizedBox.shrink(),
                      errorWidget: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.12),
                            Colors.black.withValues(alpha: 0.04),
                            Colors.black.withValues(alpha: 0.88),
                          ],
                          stops: const [0.0, 0.42, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.55),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                      child: Text(
                        'LIVE',
                        style: GoogleFonts.montserrat(
                          fontSize: 9.5.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    left: 12,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                stream.streamerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.montserrat(
                                  fontSize: 17.5.sp,
                                  fontWeight: FontWeight.w800,
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
                          style: GoogleFonts.montserrat(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.78),
                          ),
                        ),
                        SizedBox(height: 0.85.h),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.remove_red_eye_outlined,
                                size: 15.sp, color: Colors.white70),
                            SizedBox(width: 1.w),
                            Text(
                              _formatViewers(stream.viewers),
                              style: GoogleFonts.montserrat(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            _AvatarStack(urls: stream.avatarUrls.take(3).toList()),
                            if (stream.extraAudienceCount > 0) ...[
                              SizedBox(width: 1.6.w),
                              Text(
                                '+${stream.extraAudienceCount}',
                                style: GoogleFonts.montserrat(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                            SizedBox(width: 2.w),
                            _AudioPulse(),
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
    final take = urls.take(3).toList();
    final n = take.length;
    final stackW = n <= 1 ? 28.0 : 18.0 + (n - 1) * 14.0;
    return SizedBox(
      width: stackW,
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
                  child: CachedNetworkImage(
                    imageUrl: take[i],
                    width: 26,
                    height: 26,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => ColoredBox(
                      color: PremiumLiveTheme.cosmicPurple,
                    ),
                    errorWidget: (_, __, ___) => ColoredBox(
                      color: PremiumLiveTheme.cosmicPurple,
                      child: const Icon(Icons.person, size: 14, color: Colors.white54),
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
      padding: EdgeInsets.symmetric(horizontal: 1.4.w, vertical: 0.7.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PremiumLiveTheme.neonPink.withValues(alpha: 0.5)),
      ),
      child: Icon(
        Icons.graphic_eq_rounded,
        color: PremiumLiveTheme.neonPink,
        size: 18.sp,
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
