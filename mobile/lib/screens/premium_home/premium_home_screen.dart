import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../constants/premium_home_layout.dart';
import '../../data/premium_home_dummy_data.dart';
import '../../widgets/premium_home/fal_tarot_section.dart';
import '../../widgets/premium_home/hero_live_carousel.dart';
import '../../widgets/premium_home/premium_cosmic_background.dart';
import '../../widgets/premium_home/premium_home_header.dart';
import '../../widgets/premium_home/quick_actions_section.dart';
import '../../widgets/premium_home/section_title_row.dart';
import '../../widgets/premium_home/stories_tray_section.dart';
import '../../widgets/premium_home/voice_spheres_section.dart';

/// **Uygulamanın ana sayfası** (giriş sonrası `/feed`, alt barda «Ana Sayfa»).
///
/// Tasarım tek kaynak: bu dosya + `lib/widgets/premium_home/*` +
/// `lib/data/premium_home_dummy_data.dart`. Görsel referansla bire bir
/// hizalamak için mockup/export veya Figma ölçüleri gerekir; metin ve
/// bileşen sırası burada sabittir.
class PremiumHomeScreen extends StatelessWidget {
  const PremiumHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + 100;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: const Color(0xFF0D0B14),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: PremiumCosmicBackground(
          child: SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(4.5.w, 1.2.h, 4.5.w, bottom),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      PremiumHomeHeader(
                        displayName: PremiumHomeDummyData.userName,
                      ),
                      SizedBox(height: 1.2.h),
                      StoriesTraySection(
                        items: PremiumHomeDummyData.storyTrayItems,
                      ),
                      SizedBox(height: PremiumHomeLayout.sectionGap.h * 0.45),
                      HeroLiveCarousel(
                        streams: PremiumHomeDummyData.heroStreams,
                      ),
                      SizedBox(height: PremiumHomeLayout.sectionGap.h),
                      SectionTitleRow(
                        title: 'Hızlı İşlemler',
                        trailingLabel: 'Tümünü gör',
                        onTrailing: () {},
                      ),
                      SizedBox(height: 1.4.h),
                      QuickActionsSection(
                        actions: PremiumHomeDummyData.quickActions,
                      ),
                      SizedBox(height: PremiumHomeLayout.sectionGap.h),
                      SectionTitleRow(
                        title: 'Sohbet Odaları',
                        trailingLabel: 'Tüm Odalar',
                        onTrailing: () => context.push('/voice-rooms'),
                      ),
                      SizedBox(height: 1.4.h),
                      VoiceSpheresSection(
                        rooms: PremiumHomeDummyData.voiceRooms,
                      ),
                      SizedBox(height: PremiumHomeLayout.sectionGap.h),
                      SectionTitleRow(
                        title: 'Fal & Tarot',
                        trailingLabel: 'Tüm Falcılar',
                        onTrailing: () {},
                      ),
                      SizedBox(height: 1.4.h),
                      FalTarotSection(offers: PremiumHomeDummyData.tarotOffers),
                      SizedBox(height: 3.h),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
