import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/home_approved_design.dart';

/// Referans — "Sende Yayıncı Ol!" CTA şeridi.
class HomeBecomeBroadcasterBanner extends StatelessWidget {
  const HomeBecomeBroadcasterBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        HomeApprovedDesign.hPad,
        4,
        HomeApprovedDesign.hPad,
        12,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/falci-ol'),
          borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(HomeApprovedDesign.cardRadius),
              gradient: LinearGradient(
                colors: [
                  HomeApprovedDesign.gold.withValues(alpha: 0.22),
                  HomeApprovedDesign.surface,
                ],
              ),
              border: Border.all(
                color: HomeApprovedDesign.gold.withValues(alpha: 0.45),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.emoji_events_rounded,
                  color: HomeApprovedDesign.gold,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sende Yayıncı Ol!',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: HomeApprovedDesign.textPrimary,
                        ),
                      ),
                      Text(
                        'Canlı yayın aç, topluluk kur',
                        style: TextStyle(
                          fontSize: 11,
                          color: HomeApprovedDesign.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: () => context.push('/falci-ol'),
                  style: FilledButton.styleFrom(
                    backgroundColor: HomeApprovedDesign.gold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                  ),
                  child: const Text(
                    'Hemen Başla',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
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
