import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_design.dart';
import 'discover_section_header.dart';

class DiscoverQuickActions extends StatelessWidget {
  const DiscoverQuickActions({super.key});

  static const _otherActions = <_QuickAction>[
    _QuickAction(
      icon: Icons.graphic_eq_rounded,
      label: 'Sesli Odaya\nGir',
      gradient: [Color(0xFF6B21FF), Color(0xFF3B0764)],
    ),
    _QuickAction(
      icon: Icons.group_rounded,
      label: 'Arkadaşlarını\nDavet Et',
      gradient: [Color(0xFFFFB347), Color(0xFFFF8C00)],
    ),
    _QuickAction(
      icon: Icons.card_giftcard_rounded,
      label: 'Hediye\nYolla',
      gradient: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
    ),
    _QuickAction(
      icon: Icons.diamond_rounded,
      label: 'Jeton\nYükle',
      gradient: [Color(0xFF2DD4BF), Color(0xFF0891B2)],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DiscoverSectionHeader(
          title: 'Hızlı İşlemler',
          actionLabel: 'Tümünü gör',
          onAction: () => context.go('/live'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LiveBroadcastStartButton(
                  onTap: () => context.push('/live/prep'),
                ),
                const SizedBox(width: 6),
                ...List.generate(_otherActions.length, (i) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: i == 0 ? 0 : 4,
                        right: i == _otherActions.length - 1 ? 0 : 4,
                      ),
                      child: _QuickActionTile(
                        action: _otherActions[i],
                        onTap: () => _handleOtherTap(context, i),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  void _handleOtherTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.push('/voice-rooms');
      case 1:
        context.push('/invite-friends');
      case 2:
        context.go('/live');
      case 3:
        context.push('/jeton-store');
    }
  }
}

/// Tam yuvarlak canlı yayın başlat — nabız glow + kamera ikonu.
class _LiveBroadcastStartButton extends StatelessWidget {
  const _LiveBroadcastStartButton({required this.onTap});

  final VoidCallback onTap;

  static const _size = 64.0;
  static const _gradient = [Color(0xFFFF4EC8), Color(0xFFD52DFF)];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: onTap,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: _size + 14,
                  height: _size + 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _gradient.first.withValues(alpha: 0.55),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(0.92, 0.92),
                      end: const Offset(1.12, 1.12),
                      duration: 1400.ms,
                      curve: Curves.easeInOut,
                    )
                    .fade(begin: 0.35, end: 0.85, duration: 1400.ms),
                Container(
                  width: _size,
                  height: _size,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _gradient,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x66FF4EC8),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.videocam_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.06, 1.06),
                      duration: 1200.ms,
                      curve: Curves.easeInOut,
                    ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Canlı Yayın\nBaşlat',
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              color: AppDesign.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.gradient,
  });

  final IconData icon;
  final String label;
  final List<Color> gradient;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.action,
    required this.onTap,
  });

  final _QuickAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.82,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: action.gradient,
              ),
              boxShadow: [
                BoxShadow(
                  color: action.gradient.first.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(action.icon, color: Colors.white, size: 22),
                  const SizedBox(height: 6),
                  Text(
                    action.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
