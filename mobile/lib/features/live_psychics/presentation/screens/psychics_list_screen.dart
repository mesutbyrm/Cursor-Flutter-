import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/ui/premium/premium_skeleton.dart';
import '../../../../core/ui/premium_2026/cosmic_galaxy_background.dart';
import '../navigation/psychic_card_navigation.dart';
import '../widgets/psychic_premium_card.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../controllers/psychics_list_controller.dart';
import '../widgets/psychic_fortune_types.dart';
import '../widgets/psychic_recent_sessions_panel.dart';
import '../../../shorts/presentation/widgets/shorts_hub_strip.dart';

/// Çevrimiçi falcı listesi — pull to refresh + infinite scroll.
class PsychicsListScreen extends ConsumerWidget {
  const PsychicsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(psychicsListControllerProvider);
    final approved = ref.watch(
      approvedPsychicProvider.select((a) => (a.isApprovedTeller, a.profile)),
    );
    final authed = ref.watch(
      authControllerProvider.select((a) => a.valueOrNull != null),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0D0618),
      appBar: AppBar(
        title: const Text('Canlı Falcılar'),
        backgroundColor: Colors.transparent,
        actions: [
          if (approved.$1)
            TextButton.icon(
                      onPressed: () => context.push('/canli-falcilar/dashboard'),
              icon: const Icon(Icons.dashboard_outlined, color: Colors.white),
              label: const Text('Falcı Paneli'),
            )
          else if (ref.watch(
                authControllerProvider.select((a) => a.valueOrNull != null),
              ))
            TextButton.icon(
              onPressed: () => context.push('/falci-ol'),
              icon: const Icon(Icons.workspace_premium_rounded, color: Colors.white),
              label: Text(
                approved.$2 != null && !approved.$2!.isApproved
                    ? 'Başvuru'
                    : 'Falcı Ol',
              ),
            ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: CosmicGalaxyBackground(
        animate: false,
        child: SafeArea(
          child: listAsync.when(
            loading: () => ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: 6,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, _) => const PremiumSkeleton(
                height: 96,
                width: double.infinity,
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
            ),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(ApiException.userMessage(e), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () =>
                        ref.read(psychicsListControllerProvider.notifier).refresh(),
                    child: const Text('Tekrar dene'),
                  ),
                ],
              ),
            ),
            data: (state) {
              if (state.items.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(psychicsListControllerProvider.notifier).refresh(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      const ShortsHubStrip(
                        title: 'Kısa Videolar',
                        emoji: '🎬',
                        padding: EdgeInsets.zero,
                      ),
                      PsychicsFilterBar(
                        filters: state.filters,
                        favoritesOnly: state.favoritesOnly,
                      ),
                      const SizedBox(height: 48),
                      const Center(child: Text('Bu filtreye uygun falcı yok.')),
                      if (authed) ...[
                        const SizedBox(height: 24),
                        const PsychicRecentSessionsPanel(
                          title: 'Son Oturumlarım',
                          mode: PsychicRecentSessionsMode.client,
                        ),
                      ],
                    ],
                  ),
                );
              }
              return NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
                    ref.read(psychicsListControllerProvider.notifier).loadMore();
                  }
                  return false;
                },
                child: RefreshIndicator(
                  onRefresh: () =>
                      ref.read(psychicsListControllerProvider.notifier).refresh(),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: state.items.length +
                        (state.isLoadingMore ? 1 : 0) +
                        2 +
                        (authed ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      if (i == 0) {
                        return const ShortsHubStrip(
                          title: 'Kısa Videolar',
                          emoji: '🎬',
                          padding: EdgeInsets.zero,
                        );
                      }
                      if (i == 1) {
                        return PsychicsFilterBar(
                          filters: state.filters,
                          favoritesOnly: state.favoritesOnly,
                        );
                      }
                      final itemIndex = i - 2;
                      if (itemIndex >= state.items.length) {
                        if (state.isLoadingMore &&
                            itemIndex == state.items.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (authed) {
                          return const PsychicRecentSessionsPanel(
                            title: 'Son Oturumlarım',
                            mode: PsychicRecentSessionsMode.client,
                          );
                        }
                        return const SizedBox.shrink();
                      }
                      final psychic = state.items[itemIndex];
                      return PsychicPremiumListTile(
                        name: psychic.name,
                        avatarUrl: psychic.avatarUrl,
                        isOnline: psychic.isOnline,
                        rating: psychic.rating,
                        reviewCount: psychic.reviewCount,
                        categoryLabel: psychic.specialtiesLabel,
                        pricePerMinute: psychic.pricePerMinute,
                        showLiveBadge:
                            psychic.hasLiveBroadcast && psychic.isOnline,
                        onTap: () => openPsychicCardDestination(
                          context,
                          ref,
                          psychic,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class PsychicsFilterBar extends ConsumerWidget {
  const PsychicsFilterBar({
    super.key,
    required this.filters,
    this.favoritesOnly = false,
  });

  final PsychicsListFilters filters;
  final bool favoritesOnly;

  static const _sortOptions = [
    ('rating', 'Puan'),
    ('price', 'Fiyat'),
    ('sessions', 'Seans'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(psychicsListControllerProvider.notifier);
    final authed = ref.watch(
      authControllerProvider.select((a) => a.valueOrNull != null),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: const Text('Favorilerim'),
                  avatar: const Icon(Icons.favorite_rounded, size: 16),
                  selected: favoritesOnly,
                  onSelected: (on) {
                    if (on && !authed) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Favoriler için giriş yapın'),
                        ),
                      );
                      return;
                    }
                    notifier.showFavoritesOnly(on);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Sıralama',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _sortOptions.map((opt) {
              final selected = filters.sort == opt.$1;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(opt.$2),
                  selected: selected,
                  onSelected: (_) => notifier.applyFilters(
                    filters.copyWith(sort: opt.$1),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Uzmanlık',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: const Text('Tümü'),
                  selected: filters.specialty == null,
                  onSelected: (_) => notifier.applyFilters(
                    filters.copyWith(clearSpecialty: true),
                  ),
                ),
              ),
              ...psychicFortuneTypes.map((type) {
                final selected = filters.specialty == type.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(type.label),
                    selected: selected,
                    onSelected: (_) => notifier.applyFilters(
                      filters.copyWith(specialty: type.key),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
