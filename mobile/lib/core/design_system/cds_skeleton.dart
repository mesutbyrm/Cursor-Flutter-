import 'package:flutter/material.dart';

import '../ui/premium/premium_skeleton.dart';
import 'cds_spacing.dart';

/// CDS iskelet yükleme — [PremiumSkeleton] ile hizalı, merkezi API.
abstract final class CdsSkeleton {
  static Widget box({
    required double width,
    required double height,
    BorderRadius? borderRadius,
  }) {
    return PremiumSkeleton(
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }

  static Widget circle({required double size}) {
    return PremiumSkeleton(
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(size / 2),
    );
  }

  static Widget liveCard() => const PremiumLiveCardSkeleton();

  static Widget socialPost() => const PremiumPostSkeleton();

  static Widget profileHeader() => const PremiumProfileSkeleton();

  static Widget feed({int postCount = 3, EdgeInsets? padding}) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: padding ?? const EdgeInsets.symmetric(vertical: CdsSpacing.md),
      itemCount: postCount,
      separatorBuilder: (_, _) => const SizedBox(height: CdsSpacing.sm),
      itemBuilder: (_, _) => socialPost(),
    );
  }

  /// Sohbet / bildirim listesi iskeleti: avatar + iki satır (kaydırmaz).
  static Widget listRows({int count = 7}) {
    return Semantics(
      label: 'Yükleniyor',
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CdsSpacing.lg,
          vertical: CdsSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < count; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: CdsSpacing.lg),
                child: Row(
                  children: [
                    circle(size: 48),
                    const SizedBox(width: CdsSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          box(width: 140.0 + (i % 3) * 30, height: 14),
                          const SizedBox(height: CdsSpacing.sm),
                          box(width: double.infinity, height: 12),
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

  static Widget membershipCatalog() {
    return Padding(
      padding: const EdgeInsets.all(CdsSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          box(width: double.infinity, height: 160, borderRadius: BorderRadius.circular(20)),
          const SizedBox(height: CdsSpacing.lg),
          box(width: 200, height: 20),
          const SizedBox(height: CdsSpacing.md),
          ...List.generate(
            3,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: CdsSpacing.md),
              child: box(width: double.infinity, height: 88, borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }
}
