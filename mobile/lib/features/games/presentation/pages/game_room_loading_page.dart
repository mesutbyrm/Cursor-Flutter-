import 'package:flutter/material.dart';

import '../../../../core/ui/premium/premium_skeleton.dart';

/// Oyun odası yüklenirken genel iskelet — okey101 tahtası göstermez.
class GameRoomLoadingPage extends StatelessWidget {
  const GameRoomLoadingPage({
    super.key,
    this.title,
  });

  final String? title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title ?? 'Oyun hazırlanıyor...')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PremiumSkeleton(
              width: double.infinity,
              height: 120,
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            const SizedBox(height: 16),
            const PremiumSkeleton(
              width: double.infinity,
              height: 280,
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            const SizedBox(height: 16),
            const PremiumSkeleton(
              width: double.infinity,
              height: 56,
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            const SizedBox(height: 24),
            Text(
              'Oyun hazırlanıyor...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
