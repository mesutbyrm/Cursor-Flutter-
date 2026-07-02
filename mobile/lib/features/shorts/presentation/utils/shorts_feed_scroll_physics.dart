import 'package:flutter/material.dart';

/// TikTok/Reels — hızlı snap, tek parmakla akıcı geçiş.
class ShortsPageScrollPhysics extends PageScrollPhysics {
  const ShortsPageScrollPhysics({super.parent});

  @override
  ShortsPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return ShortsPageScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => const SpringDescription(
        mass: 0.18,
        stiffness: 480,
        damping: 34,
      );
}

/// PageView için doğru zincir: Bouncing → PageScroll (snap).
ScrollPhysics get shortsFeedPagePhysics => const BouncingScrollPhysics(
      parent: ShortsPageScrollPhysics(),
      decelerationRate: ScrollDecelerationRate.fast,
    );
