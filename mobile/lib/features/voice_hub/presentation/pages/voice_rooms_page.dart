import 'package:flutter/material.dart';

import '../widgets/voice_rooms_ui/voice_rooms_ui.dart';

/// Sesli Odalar ana ekranı — Premium 2026 UI (hardcoded, API yok).
class VoiceRoomsPage extends StatefulWidget {
  const VoiceRoomsPage({super.key});

  @override
  State<VoiceRoomsPage> createState() => _VoiceRoomsPageState();
}

class _VoiceRoomsPageState extends State<VoiceRoomsPage> {
  int _categoryIndex = 0;
  int _nearbyTab = 0;
  VoiceRoomsNavItem _nav = VoiceRoomsNavItem.voice;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 720;

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: VoiceRoomsUiTokens.bgAmoled,
        splashFactory: InkRipple.splashFactory,
      ),
      child: Scaffold(
        backgroundColor: VoiceRoomsUiTokens.bgAmoled,
        extendBody: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const _AmbientBackground(),
            SafeArea(
              bottom: false,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  const SliverToBoxAdapter(child: VoiceRoomsAppBar()),
                  SliverToBoxAdapter(
                    child: CategorySelector(
                      selectedIndex: _categoryIndex,
                      onSelected: (i) => setState(() => _categoryIndex = i),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  const SliverToBoxAdapter(child: FeaturedBanner()),
                  const SliverToBoxAdapter(child: PopularRoomsCarousel()),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: wide ? _WideContent(nearbyTab: _nearbyTab, onTabChanged: _setNearbyTab) : _NarrowContent(nearbyTab: _nearbyTab, onTabChanged: _setNearbyTab),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 140)),
                ],
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MiniMusicPlayer(),
            ),
          ],
        ),
        bottomNavigationBar: VoiceRoomsBottomNav(
          active: _nav,
          onChanged: (item) => setState(() => _nav = item),
        ),
      ),
    );
  }

  void _setNearbyTab(int i) => setState(() => _nearbyTab = i);
}

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const ColoredBox(color: VoiceRoomsUiTokens.bgAmoled),
        Positioned(
          top: -100,
          right: -60,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: VoiceRoomsUiTokens.purpleGlow.withValues(alpha: 0.22),
                  blurRadius: 120,
                  spreadRadius: 30,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 280,
          left: -80,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: VoiceRoomsUiTokens.magenta.withValues(alpha: 0.12),
                  blurRadius: 100,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 120,
          right: -40,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: VoiceRoomsUiTokens.blue.withValues(alpha: 0.10),
                  blurRadius: 90,
                  spreadRadius: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WideContent extends StatelessWidget {
  const _WideContent({
    required this.nearbyTab,
    required this.onTabChanged,
  });

  final int nearbyTab;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: VoiceRoomsUiTokens.padScreenH),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: NearbyRoomsList(
              selectedTab: nearbyTab,
              onTabChanged: onTabChanged,
            ),
          ),
          const SizedBox(width: VoiceRoomsUiTokens.gapLg),
          Expanded(
            flex: 3,
            child: Column(
              children: [
                const MyRoomCard(),
                const SizedBox(height: VoiceRoomsUiTokens.gapMd),
                const TrendingTopicsCard(),
                const SizedBox(height: VoiceRoomsUiTokens.gapMd),
                const ActiveSpeakersCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NarrowContent extends StatelessWidget {
  const _NarrowContent({
    required this.nearbyTab,
    required this.onTabChanged,
  });

  final int nearbyTab;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        NearbyRoomsList(
          selectedTab: nearbyTab,
          onTabChanged: onTabChanged,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            VoiceRoomsUiTokens.padScreenH,
            VoiceRoomsUiTokens.gapLg,
            VoiceRoomsUiTokens.padScreenH,
            0,
          ),
          child: Column(
            children: const [
              MyRoomCard(),
              SizedBox(height: VoiceRoomsUiTokens.gapMd),
              TrendingTopicsCard(),
              SizedBox(height: VoiceRoomsUiTokens.gapMd),
              ActiveSpeakersCard(),
            ],
          ),
        ),
      ],
    );
  }
}
