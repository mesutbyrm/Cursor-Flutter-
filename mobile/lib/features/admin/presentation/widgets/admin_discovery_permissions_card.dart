import 'package:flutter/material.dart';

import '../../../platform_social/presentation/widgets/platform_social_ui_kit.dart';

/// Admin Yetkiler — keşfet görünürlük kartı (§38).
class AdminDiscoveryPermissionsCard extends StatelessWidget {
  const AdminDiscoveryPermissionsCard({
    super.key,
    required this.hiddenFromDiscovery,
    required this.discoveryPriority,
    required this.onHiddenChanged,
    required this.onPriorityDecrease,
    required this.onPriorityIncrease,
    this.canDecreasePriority = true,
  });

  final bool hiddenFromDiscovery;
  final int discoveryPriority;
  final ValueChanged<bool> onHiddenChanged;
  final VoidCallback onPriorityDecrease;
  final VoidCallback onPriorityIncrease;
  final bool canDecreasePriority;

  @override
  Widget build(BuildContext context) {
    return PlatformSocialGlassCard(
      gradient: LinearGradient(
        colors: [
          PlatformSocialPalette.accent.withValues(alpha: 0.12),
          PlatformSocialPalette.card.withValues(alpha: 0.95),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PlatformSocialSectionTitle('Keşfet & sıralama'),
          const SizedBox(height: 4),
          const Text(
            'Tanış keşfet ve öneri sırası — sunucu `discoveryPriority` ile hizalanır.',
            style: TextStyle(
              fontSize: 11,
              color: PlatformSocialPalette.textMuted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Keşfetten gizle'),
            subtitle: const Text('hiddenFromDiscovery'),
            value: hiddenFromDiscovery,
            onChanged: onHiddenChanged,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Keşif önceliği'),
            subtitle: Text('Mevcut: $discoveryPriority'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: canDecreasePriority ? onPriorityDecrease : null,
                ),
                Text(
                  '$discoveryPriority',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: onPriorityIncrease,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
