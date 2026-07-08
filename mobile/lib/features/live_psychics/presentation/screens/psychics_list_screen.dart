import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/ui/premium/live_badge.dart';
import '../../../../core/ui/premium_2026/cosmic_galaxy_background.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../core/ui/premium/premium_skeleton.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/psychic_entity.dart';
import '../controllers/psychics_list_controller.dart';
import '../widgets/psychic_fortune_types.dart';

/// Çevrimiçi falcı listesi — pull to refresh + infinite scroll.
class PsychicsListScreen extends ConsumerWidget {
  const PsychicsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(psychicsListControllerProvider);
    final approved = ref.watch(
      approvedPsychicProvider.select((a) => (a.isApprovedTeller, a.profile)),
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
                height: 88,
                width: double.infinity,
                borderRadius: BorderRadius.all(Radius.circular(16)),
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
              final authed = ref.watch(
                authControllerProvider.select((a) => a.valueOrNull != null),
              );
              if (!authed) {
                return Center(
                  child: Text(
                    'Canlı falcılar için giriş yapın.',
                    style: TextStyle(color: context.colors.onSurfaceMuted),
                  ),
                );
              }
              if (state.items.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(psychicsListControllerProvider.notifier).refresh(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      PsychicsFilterBar(
                        filters: state.filters,
                        favoritesOnly: state.favoritesOnly,
                      ),
                      const SizedBox(height: 48),
                      const Center(child: Text('Bu filtreye uygun falcı yok.')),
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
                    itemCount: state.items.length + (state.isLoadingMore ? 1 : 0) + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      if (i == 0) {
                        return PsychicsFilterBar(
                          filters: state.filters,
                          favoritesOnly: state.favoritesOnly,
                        );
                      }
                      final itemIndex = i - 1;
                      if (itemIndex >= state.items.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return PsychicListTile(psychic: state.items[itemIndex]);
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

class PsychicListTile extends StatelessWidget {
  const PsychicListTile({super.key, required this.psychic});

  final PsychicEntity psychic;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => context.push('/canli-falcilar/${psychic.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Stack(
                children: [
                  psychic.avatarUrl != null && psychic.avatarUrl!.isNotEmpty
                      ? CircleAvatar(
                          radius: 28,
                          backgroundImage:
                              canlifalImageProvider(psychic.avatarUrl!),
                        )
                      : const UserAvatar(radius: 28),
                  if (psychic.isOnline)
                    const Positioned(
                      right: 0,
                      bottom: 0,
                      child: LiveBadge(compact: true),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      psychic.name,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    Text(
                      psychic.displayCategory,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                    if (psychic.rating > 0)
                      Text(
                        '★ ${psychic.rating.toStringAsFixed(1)} · ${psychic.reviewCount} seans',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    psychic.isOnline ? 'Çevrimiçi' : 'Çevrimdışı',
                    style: TextStyle(
                      fontSize: 11,
                      color: psychic.isOnline
                          ? const Color(0xFF00E676)
                          : Colors.white54,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (psychic.pricePerMinute > 0)
                    Text(
                      '${psychic.pricePerMinute} jeton/dk',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFFFD54F),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ],
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
                  onSelected: (on) =>
                      notifier.showFavoritesOnly(on),
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
