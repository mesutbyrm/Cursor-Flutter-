import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../voice_hub/presentation/utils/open_voice_chat_room_flow.dart';
import '../../theme/home_approved_design.dart';

/// Ana sayfa hızlı erişim — sesli oda, fal, jeton, odalar.
class HomeQuickActions extends ConsumerWidget {
  const HomeQuickActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        HomeApprovedDesign.hPad,
        4,
        HomeApprovedDesign.hPad,
        12,
      ),
      child: Row(
        children: [
          Expanded(
            child: _ActionChip(
              icon: Icons.mic_rounded,
              label: 'Sesli Oda',
              colors: const [Color(0xFF7C3AED), Color(0xFFDB2777)],
              onTap: () => context.push('/voice-rooms'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionChip(
              icon: Icons.auto_awesome_rounded,
              label: 'Fal',
              colors: const [Color(0xFF2563EB), Color(0xFF7C3AED)],
              onTap: () => context.push('/fortune'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionChip(
              icon: Icons.auto_awesome_rounded,
              label: 'Fal & Tarot',
              colors: const [Color(0xFF2563EB), Color(0xFF7C3AED)],
              onTap: () => context.go('/fortune'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionChip(
              icon: Icons.add_circle_outline_rounded,
              label: 'Oda Aç',
              colors: const [Color(0xFF059669), Color(0xFF10B981)],
              onTap: () => showOpenVoiceChatRoomFlow(context, ref),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.colors,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(colors: colors),
            boxShadow: [
              BoxShadow(
                color: colors.first.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
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
