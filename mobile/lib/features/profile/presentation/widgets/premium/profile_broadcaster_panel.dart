import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_design.dart';
import 'profile_glass.dart';

class ProfileBroadcasterPanel extends StatelessWidget {
  const ProfileBroadcasterPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        icon: Icons.history_rounded,
        label: 'Yayın Geçmişi',
        onTap: () => context.push('/live'),
      ),
      (
        icon: Icons.event_rounded,
        label: 'Yayın Planla',
        onTap: () {},
      ),
      (
        icon: Icons.insights_rounded,
        label: 'İstatistikler',
        onTap: () {},
      ),
      (
        icon: Icons.mic_external_on_rounded,
        label: 'Ekipmanım',
        onTap: () {},
      ),
      (
        icon: Icons.tune_rounded,
        label: 'Yayın Ayarları',
        onTap: () {},
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ProfileSectionTitle(title: 'Yayıncı Paneli'),
        Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _BroadcasterTile(
                  icon: items[i].icon,
                  label: items[i].label,
                  onTap: items[i].onTap,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _BroadcasterTile extends StatelessWidget {
  const _BroadcasterTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ProfileGlass(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      borderRadius: 16,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppDesign.accentPurple.withValues(alpha: 0.2),
            ),
            child: Icon(
              icon,
              size: 22,
              color: AppDesign.accentPurple.withValues(alpha: 0.95),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              height: 1.15,
              color: AppDesign.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
