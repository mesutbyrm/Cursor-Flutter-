import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/admin_site_animation.dart';
import '../providers/admin_site_animation_providers.dart';
import '../providers/staff_access_provider.dart';
import '../widgets/admin_site_animation_entrance_picker.dart';

class AdminSiteAnimationsDefaultsPage extends ConsumerWidget {
  const AdminSiteAnimationsDefaultsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(staffAccessProvider);
    if (!access.canManageSiteAnimations) {
      return Scaffold(
        appBar: AppBar(title: const Text('Üyelik Eşleştirme')),
        body: const Center(child: Text('Yetkisiz')),
      );
    }

    final entranceAsync = ref.watch(adminSiteAnimationDefaultsProvider);
    final exitAsync = ref.watch(adminSiteAnimationExitDefaultsProvider);
    final listAsync = ref.watch(adminSiteAnimationListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0E0524),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12082A),
        title: const Text('Üyelik Eşleştirme'),
      ),
      body: entranceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (entranceDefaults) {
          return exitAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (exitDefaults) {
              final animations = listAsync.valueOrNull ?? const [];
              final tiers = AdminSiteAnimationMembership.values
                  .where((t) => t != AdminSiteAnimationMembership.all)
                  .toList();

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Giriş animasyonları',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Her üyelik seviyesi için varsayılan giriş animasyonunu seçin.',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  for (final tier in tiers)
                    Card(
                      color: const Color(0xFF12082A),
                      margin: const EdgeInsets.only(bottom: 14),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tier.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 10),
                            AdminSiteAnimationEntrancePicker(
                              tier: tier,
                              animations: animations,
                              selectedId: entranceDefaults[tier],
                              onSelected: (id) async {
                                final next =
                                    Map<AdminSiteAnimationMembership, String>.from(
                                  entranceDefaults,
                                );
                                if (id == null) {
                                  next.remove(tier);
                                } else {
                                  next[tier] = id;
                                }
                                await ref
                                    .read(adminSiteAnimationDefaultsProvider.notifier)
                                    .save(next);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  const Text(
                    'Çıkış animasyonları',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Odadan ayrılırken üyelik seviyesine göre varsayılan çıkış efekti.',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  for (final tier in tiers)
                    _TierDefaultTile(
                      tier: tier,
                      animationId: exitDefaults[tier],
                      animations: animations
                          .where((a) =>
                              a.category == AdminSiteAnimationCategory.exit &&
                              a.isActive)
                          .toList(),
                      onChanged: (id) async {
                        final next =
                            Map<AdminSiteAnimationMembership, String>.from(
                          exitDefaults,
                        );
                        if (id == null) {
                          next.remove(tier);
                        } else {
                          next[tier] = id;
                        }
                        await ref
                            .read(adminSiteAnimationExitDefaultsProvider.notifier)
                            .save(next);
                      },
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _TierDefaultTile extends StatelessWidget {
  const _TierDefaultTile({
    required this.tier,
    required this.animationId,
    required this.animations,
    required this.onChanged,
  });

  final AdminSiteAnimationMembership tier;
  final String? animationId;
  final List<AdminSiteAnimation> animations;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF12082A),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tier.label, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              value: animationId,
              decoration: const InputDecoration(labelText: 'Default animation'),
              items: [
                const DropdownMenuItem(value: null, child: Text('— Seçilmedi —')),
                ...animations.map(
                  (a) => DropdownMenuItem(value: a.id, child: Text(a.name)),
                ),
              ],
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
