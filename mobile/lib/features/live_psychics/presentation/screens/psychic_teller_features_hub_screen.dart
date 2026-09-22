import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/core/ui/premium_2026/cosmic_galaxy_background.dart';
import 'package:canlifal_social/features/live_psychics/presentation/controllers/psychics_list_controller.dart';
import 'package:canlifal_social/features/live_psychics/presentation/data/psychic_teller_features_catalog.dart';

/// Tüm falcı araçları — Claude + P0/P1 ekranlarının keşif merkezi.
class PsychicTellerFeaturesHubScreen extends ConsumerStatefulWidget {
  const PsychicTellerFeaturesHubScreen({super.key});

  @override
  ConsumerState<PsychicTellerFeaturesHubScreen> createState() =>
      _PsychicTellerFeaturesHubScreenState();
}

class _PsychicTellerFeaturesHubScreenState
    extends ConsumerState<PsychicTellerFeaturesHubScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final approved = ref.watch(approvedPsychicProvider);
    final profile = approved.profile;
    final profileId = profile?.id ?? '';

    final sections = profileId.isNotEmpty
        ? psychicTellerFeaturesCatalog(profileId: profileId)
        : psychicTellerFeaturesCatalog(profileId: 'me');

    final q = _query.trim().toLowerCase();
    final filtered = sections
        .map((section) {
          final items = q.isEmpty
              ? section.items
              : section.items.where((item) {
                  return item.title.toLowerCase().contains(q) ||
                      item.subtitle.toLowerCase().contains(q);
                }).toList();
          if (items.isEmpty) return null;
          return PsychicFeatureCatalogSection(title: section.title, items: items);
        })
        .whereType<PsychicFeatureCatalogSection>()
        .toList();

    final totalCount =
        sections.fold<int>(0, (sum, s) => sum + s.items.length);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0618),
      appBar: AppBar(
        title: const Text('Tüm Falcı Araçları'),
        backgroundColor: Colors.transparent,
      ),
      body: CosmicGalaxyBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _HeroBanner(totalTools: totalCount),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Araç ara…',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final section = filtered[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            section.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...section.items.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _FeatureTile(
                                item: item,
                                onTap: () {
                                  if (profileId.isEmpty &&
                                      item.requiresProfileId) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Profil yüklenene kadar bekleyin veya panele dönün.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  context.push(item.routePath);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.totalTools});

  final int totalTools;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            AppThemeColors.accentPink.withValues(alpha: 0.35),
            AppThemeColors.accentPurple.withValues(alpha: 0.25),
          ],
        ),
        border: Border.all(
          color: AppThemeColors.accentCyan.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.apps_rounded,
                color: AppThemeColors.accentCyan,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$totalTools araç tek listede',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Claude ile eklenen gelişmiş ekranlar ve günlük P0 paneli burada. '
            'Her karta dokunarak ilgili sayfayı açın.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.35,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.item, required this.onTap});

  final PsychicFeatureCatalogItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tierColor = psychicFeatureTierColor(item.tier);
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tierColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: tierColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: tierColor.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            psychicFeatureTierLabel(item.tier),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: tierColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
