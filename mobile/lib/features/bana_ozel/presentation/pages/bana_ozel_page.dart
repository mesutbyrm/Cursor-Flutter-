import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/economy/domain/economy_payment_models.dart';
import '../../../../core/economy/presentation/providers/economy_providers.dart';
import '../../../../core/economy/presentation/widgets/currency_amount_label.dart';
import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../fortune/data/services/rewarded_ad_service.dart';
import '../../../fortune/presentation/widgets/ultra_premium/ultra_fortune_cosmic_background.dart';
import '../../../fortune/presentation/widgets/ultra_premium/ultra_fortune_cover_backdrop.dart';
import '../../../fortune/presentation/widgets/ultra_premium/ultra_fortune_liquid_surface.dart';
import '../../../fortune/presentation/widgets/ultra_premium/ultra_fortune_state_panel.dart';
import '../../../fortune/presentation/widgets/ultra_premium/ultra_fortune_tokens.dart';
import '../../../fortune/presentation/data/fortune_type_images.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/bana_ozel_preferences_store.dart';
import '../../domain/entities/bana_ozel_entities.dart';
import '../data/bana_ozel_display_resolver.dart';
import '../providers/bana_ozel_preferences_providers.dart';
import '../providers/bana_ozel_providers.dart';
import '../widgets/bana_ozel_premium_card.dart';
import '../../../shorts/presentation/widgets/shorts_hub_strip.dart';

/// Bana Özel kataloğu — `GET /api/bana-ozel` + `POST /api/bana-ozel/open`.
class BanaOzelPage extends ConsumerStatefulWidget {
  const BanaOzelPage({super.key, this.initialSlug});

  /// Önizleme kartından gelen derin bağlantı (`?slug=`).
  final String? initialSlug;

  @override
  ConsumerState<BanaOzelPage> createState() => _BanaOzelPageState();
}

class _BanaOzelPageState extends ConsumerState<BanaOzelPage> {
  String _category = 'all';
  String? _openingSlug;
  String? _pendingSlug;
  bool _pendingSlugAttempted = false;

  @override
  void initState() {
    super.initState();
    final slug = widget.initialSlug?.trim();
    if (slug != null && slug.isNotEmpty) {
      _pendingSlug = slug;
    }
  }

  Future<void> _openItem(BanaOzelItemEntity item, BanaOzelCatalogEntity data) async {
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İçerik açmak için giriş yapın')),
      );
      setState(() => _pendingSlugAttempted = false);
      context.push('/auth/login');
      return;
    }

    final cost = item.jetonCost;
    final canPayDirectly = data.canAffordItem(item);

    if (!canPayDirectly) {
      final insufficient = await _tryOpenAndCatchInsufficient(item);
      if (insufficient != null && insufficient.canWatchAd) {
        final watched = await _confirmAndWatchAd(item, insufficient);
        if (watched) return;
      }
      if (!mounted) return;
      if (insufficient != null && !insufficient.canWatchAd) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(insufficient.message),
            action: SnackBarAction(
              label: economyJetonBuyActionLabel(ref),
              onPressed: () => context.push('/jeton-store'),
            ),
          ),
        );
      }
      return;
    }

    final jetonLabel = economyCurrencyLabel(ref, key: 'jeton');
    final cfcLabel = economyCurrencyLabel(ref, key: 'cfc');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${item.icon} ${item.nameTr}'),
        content: Text(
          '$cost birim harcanacak ($cfcLabel veya $jetonLabel).\nDevam etmek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Aç'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      if (confirmed != true) {
        setState(() => _pendingSlugAttempted = false);
      }
      return;
    }

    await _performOpen(item);
  }

  Future<BanaOzelInsufficientPayment?> _tryOpenAndCatchInsufficient(
    BanaOzelItemEntity item,
  ) async {
    setState(() => _openingSlug = item.slug);
    try {
      await ref.read(banaOzelRepositoryProvider).openItem(item: item);
      return null;
    } on BanaOzelInsufficientPayment catch (e) {
      return e;
    } catch (_) {
      return null;
    } finally {
      if (mounted) setState(() => _openingSlug = null);
    }
  }

  Future<bool> _confirmAndWatchAd(
    BanaOzelItemEntity item,
    BanaOzelInsufficientPayment insufficient,
  ) async {
    final adHint = insufficient.adUnlimited
        ? 'Reklam izleyerek ücretsiz açabilirsiniz.'
        : 'Kalan reklam hakkı: ${insufficient.adRemaining}';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${item.icon} ${item.nameTr}'),
        content: Text('${insufficient.message}\n\n$adHint'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reklam izle'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      setState(() => _pendingSlugAttempted = false);
      return false;
    }

    final rewarded = await RewardedAdService.instance.show();
    if (!rewarded) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reklam tamamlanamadı. Tekrar deneyin.')),
      );
      setState(() => _pendingSlugAttempted = false);
      return false;
    }

    await _performOpen(item, useAd: true);
    return true;
  }

  Future<void> _performOpen(BanaOzelItemEntity item, {bool useAd = false}) async {
    setState(() => _openingSlug = item.slug);
    try {
      final result = await ref
          .read(banaOzelRepositoryProvider)
          .openItem(item: item, useAd: useAd);
      ref.read(banaOzelCatalogProvider.notifier).applyOpenResult(result);
      if (!mounted) return;
      if (!result.hasContent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İçerik oluşturulamadı')),
        );
        setState(() => _pendingSlugAttempted = false);
        return;
      }
      setState(() {
        _pendingSlug = null;
        _pendingSlugAttempted = false;
      });
      try {
        final store = await ref.read(banaOzelPreferencesStoreProvider.future);
        await store.recordOpen(slug: item.slug, title: item.nameTr);
        ref.invalidate(banaOzelPreferencesStoreProvider);
      } catch (_) {}
      await context.push('/fortune/bana-ozel/result', extra: result);
    } on BanaOzelInsufficientPayment catch (e) {
      if (!mounted) return;
      setState(() => _pendingSlugAttempted = false);
      if (e.canWatchAd && !useAd) {
        await _confirmAndWatchAd(item, e);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _pendingSlugAttempted = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _openingSlug = null);
    }
  }

  void _tryOpenPendingSlug(BanaOzelCatalogEntity data) {
    final slug = _pendingSlug;
    if (slug == null || _openingSlug != null || _pendingSlugAttempted || !mounted) {
      return;
    }
    final item = data.itemBySlug(slug);
    if (item == null) {
      setState(() => _pendingSlug = null);
      return;
    }
    setState(() => _pendingSlugAttempted = true);
    _openItem(item, data);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (prev, next) {
      if (prev?.valueOrNull?.id != next.valueOrNull?.id &&
          _pendingSlug != null &&
          mounted) {
        setState(() => _pendingSlugAttempted = false);
      }
    });
    final catalog = ref.watch(banaOzelCatalogProvider);
    final jetonLabel = economyCurrencyLabel(ref, key: 'jeton');
    final searchQuery = ref.watch(banaOzelSearchQueryProvider);
    final sortMode = ref.watch(banaOzelSortModeProvider);
    final prefs = ref.watch(banaOzelPreferencesStoreProvider).valueOrNull;
    final favorites = prefs?.favoriteSlugs ?? const <String>{};
    final openHistory = prefs?.openHistory ?? const <BanaOzelOpenHistoryEntry>[];
    final dailyTasks = ref.watch(userDailyTasksProvider);

    return Scaffold(
      backgroundColor: UltraFortuneTokens.deepNight,
      body: UltraFortuneCosmicBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go('/fortune'),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Expanded(
                      child: Text(
                        'Bana Özel',
                        style: GoogleFonts.playfairDisplay(
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    catalog.maybeWhen(
                      data: (c) => _BalanceBadges(
                        jetonBalance: c.jetonBalance,
                        cfcBalance: c.cfcBalance,
                      ),
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              catalog.when(
                loading: () => Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.92,
                    ),
                    itemCount: 6,
                    itemBuilder: (_, _) => const BanaOzelPremiumCardSkeleton(
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),
                error: (e, _) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: UltraFortuneStatePanel(
                      icon: Icons.refresh_rounded,
                      message: ApiException.userMessage(e),
                      actionLabel: 'Yenile',
                      onAction: () => ref.invalidate(banaOzelCatalogProvider),
                    ),
                  ),
                ),
                data: (data) {
                  if (data.items.isEmpty) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: UltraFortuneStatePanel(
                          icon: Icons.auto_awesome_rounded,
                          message: 'Henüz içerik yok. Fal evrenini keşfetmeye başla.',
                          actionLabel: 'Fal & Tarot',
                          onAction: () => context.go('/fortune'),
                        ),
                      ),
                    );
                  }
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _tryOpenPendingSlug(data);
                  });
                  final filtered = filterAndSortBanaOzelItems(
                    items: data.itemsForCategory(
                      _category == 'all' ? null : _category,
                    ),
                    searchQuery: searchQuery,
                    sortMode: sortMode,
                    favoriteSlugs: favorites,
                  );
                  final freeItems =
                      data.items.where((i) => i.jetonCost <= 0).take(4).toList();
                  final showAdBanner = data.parsedTodayTasks
                      .contains(BanaOzelTodayTask.watchAd);
                  return Expanded(
                    child: RefreshIndicator(
                      onRefresh: () =>
                          ref.read(banaOzelCatalogProvider.notifier).refresh(),
                      child: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(child: _CatalogHeroBanner()),
                          if (showAdBanner)
                            SliverToBoxAdapter(
                              child: _WatchAdPromoBanner(
                                onTap: () => context.push('/profile/growth'),
                              ),
                            ),
                          if (freeItems.isNotEmpty)
                            SliverToBoxAdapter(
                              child: _FreeContentBand(
                                items: freeItems,
                                onOpen: (item) => _openItem(item, data),
                              ),
                            ),
                          if (openHistory.isNotEmpty)
                            SliverToBoxAdapter(
                              child: _OpenHistoryStrip(
                                entries: openHistory.take(5).toList(),
                                onTap: (slug) {
                                  final item = data.itemBySlug(slug);
                                  if (item != null) _openItem(item, data);
                                },
                              ),
                            ),
                          SliverToBoxAdapter(
                            child: _BanaOzelSearchSortBar(
                              sortMode: sortMode,
                              onSortChanged: (mode) => ref
                                  .read(banaOzelSortModeProvider.notifier)
                                  .state = mode,
                            ),
                          ),
                          dailyTasks.when(
                            loading: () => const SliverToBoxAdapter(
                              child: SizedBox.shrink(),
                            ),
                            error: (_, _) => const SliverToBoxAdapter(
                              child: SizedBox.shrink(),
                            ),
                            data: (tasks) {
                              if (tasks.isEmpty) {
                                return const SliverToBoxAdapter(
                                  child: SizedBox.shrink(),
                                );
                              }
                              final done =
                                  tasks.where((t) => t.completed).length;
                              return SliverToBoxAdapter(
                                child: _DailyTaskProgressBar(
                                  done: done,
                                  total: tasks.length,
                                  onTap: () => context.push('/profile/growth'),
                                ),
                              );
                            },
                          ),
                          const SliverToBoxAdapter(
                            child: ShortsHubStrip(
                              title: 'Kısa Videolar',
                              emoji: '🎬',
                              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Kişisel fal ve tarot içerikleri — $jetonLabel ile açın.',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.72),
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                  if (data.streak.currentStreak > 0 ||
                                      data.streak.totalFortunes > 0) ...[
                                    const SizedBox(height: 8),
                                    _StreakSummary(streak: data.streak),
                                  ],
                                  if (data.todayTasks.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    _TodayTasksStrip(
                                      tasks: data.parsedTodayTasks,
                                      onTaskTap: (task) {
                                        final route = task.routePath;
                                        if (route == null) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '${task.labelTr} görevine yönlendiriliyorsun',
                                            ),
                                          ),
                                        );
                                        context.push(route);
                                      },
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  _CategoryChips(
                                    categories: data.categories,
                                    selected: _category,
                                    onSelected: (v) =>
                                        setState(() => _category = v),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                            sliver: SliverGrid(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 0.92,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, i) {
                                  final item = filtered[i];
                                  final opening = _openingSlug == item.slug;
                                  return LayoutBuilder(
                                    builder: (context, constraints) {
                                      final w = constraints.maxWidth;
                                      final h = constraints.maxHeight;
                                      return Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          BanaOzelPremiumCard(
                                            item: item,
                                            width: w,
                                            height: h,
                                            affordable: data.canAffordItem(item),
                                            isFavorite:
                                                favorites.contains(item.slug),
                                            onFavoriteToggle: () async {
                                              final store = await ref.read(
                                                banaOzelPreferencesStoreProvider
                                                    .future,
                                              );
                                              await store.toggleFavorite(
                                                item.slug,
                                              );
                                              ref.invalidate(
                                                banaOzelPreferencesStoreProvider,
                                              );
                                            },
                                            onTap: opening
                                                ? () {}
                                                : () => _openItem(item, data),
                                          ),
                                          if (opening)
                                            Positioned.fill(
                                              child: DecoratedBox(
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.45),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    BanaOzelPremiumCard.radius,
                                                  ),
                                                ),
                                                child: const Center(
                                                  child: SizedBox(
                                                    width: 28,
                                                    height: 28,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2.5,
                                                      color: Color(0xFFFFD54F),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                childCount: filtered.length,
                              ),
                            ),
                          ),
                          if (filtered.isEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: UltraFortuneStatePanel(
                                  icon: Icons.search_off_rounded,
                                  message: searchQuery.trim().isEmpty
                                      ? 'Bu kategoride içerik yok.'
                                      : '“${searchQuery.trim()}” için sonuç yok.',
                                  actionLabel: searchQuery.trim().isEmpty
                                      ? 'Tümü'
                                      : 'Temizle',
                                  onAction: () {
                                    if (searchQuery.trim().isEmpty) {
                                      setState(() => _category = 'all');
                                    } else {
                                      ref
                                          .read(
                                            banaOzelSearchQueryProvider.notifier,
                                          )
                                          .state = '';
                                    }
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CatalogHeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const slug = 'melek-kartlari';
    final accent = FortuneTypeImages.glowColor(slug);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 96,
          child: Stack(
            fit: StackFit.expand,
            children: [
              UltraFortuneCoverBackdrop(
                slug: slug,
                accent: accent,
                opacity: 0.42,
                imageWidth: 900,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Sana özel mistik içerikler',
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tarot, astroloji ve spiritüel yorumlar — vitrininden seç.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceBadges extends ConsumerWidget {
  const _BalanceBadges({
    required this.jetonBalance,
    required this.cfcBalance,
  });

  final int jetonBalance;
  final int cfcBalance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CurrencyAmountLabel(
          amount: cfcBalance,
          currencyKey: 'cfc',
          compact: true,
          showName: false,
        ),
        const SizedBox(width: 8),
        CurrencyAmountLabel(
          amount: jetonBalance,
          currencyKey: 'jeton',
          compact: true,
          showName: false,
        ),
      ],
    );
  }
}

class _StreakSummary extends StatelessWidget {
  const _StreakSummary({required this.streak});

  final BanaOzelStreakEntity streak;

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFFFD54F);
    final parts = <String>[];
    if (streak.currentStreak > 0) {
      parts.add('🔥 ${streak.currentStreak} günlük seri');
      if (streak.currentStreak >= 7) {
        parts.add('haftalık rozet');
      } else if (streak.currentStreak >= 3) {
        parts.add('3+ gün bonusu');
      }
    }
    if (streak.totalFortunes > 0) {
      parts.add('${streak.totalFortunes} fal');
    }
    if (streak.longestStreak > streak.currentStreak) {
      parts.add('en uzun ${streak.longestStreak} gün');
    }
    return Text(
      parts.join(' · '),
      style: TextStyle(
        color: gold.withValues(alpha: 0.9),
        fontWeight: FontWeight.w800,
        fontSize: 12,
      ),
    );
  }
}

class _TodayTasksStrip extends StatelessWidget {
  const _TodayTasksStrip({
    required this.tasks,
    this.onTaskTap,
  });

  final List<BanaOzelTodayTask> tasks;
  final ValueChanged<BanaOzelTodayTask>? onTaskTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bugünkü görevler',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final task in tasks)
              ActionChip(
                visualDensity: VisualDensity.compact,
                label: Text(
                  task.labelTr,
                  style: const TextStyle(fontSize: 11),
                ),
                avatar: Icon(
                  task.routePath != null
                      ? Icons.arrow_outward_rounded
                      : Icons.check_circle_outline,
                  size: 16,
                ),
                onPressed: task.routePath == null
                    ? null
                    : () => onTaskTap?.call(task),
              ),
          ],
        ),
      ],
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  static const _labels = {
    'all': 'Tümü',
    'fortune': 'Fal',
    'tarot': 'Tarot',
    'astrology': 'Astroloji',
    'spiritual': 'Spiritüel',
  };

  @override
  Widget build(BuildContext context) {
    final chips = ['all', ...categories];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final c in chips) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: selected == c,
                label: Text(_labels[c] ?? c),
                onSelected: (_) => onSelected(c),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BanaOzelSearchSortBar extends ConsumerWidget {
  const _BanaOzelSearchSortBar({
    required this.sortMode,
    required this.onSortChanged,
  });

  final BanaOzelSortMode sortMode;
  final ValueChanged<BanaOzelSortMode> onSortChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(banaOzelSearchQueryProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          SearchBar(
            hintText: 'İçerik ara…',
            leading: const Icon(Icons.search_rounded, color: Colors.white70),
            trailing: query.isNotEmpty
                ? [
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => ref
                          .read(banaOzelSearchQueryProvider.notifier)
                          .state = '',
                    ),
                  ]
                : null,
            onChanged: (v) =>
                ref.read(banaOzelSearchQueryProvider.notifier).state = v,
            backgroundColor: Colors.white.withValues(alpha: 0.06),
            elevation: WidgetStateProperty.all(0),
            textStyle: WidgetStateProperty.all(
              const TextStyle(color: Colors.white),
            ),
            hintStyle: WidgetStateProperty.all(
              TextStyle(color: Colors.white.withValues(alpha: 0.45)),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final mode in BanaOzelSortMode.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: sortMode == mode,
                      label: Text(_sortLabel(mode)),
                      onSelected: (_) => onSortChanged(mode),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _sortLabel(BanaOzelSortMode mode) => switch (mode) {
        BanaOzelSortMode.catalog => 'Katalog',
        BanaOzelSortMode.name => 'İsim',
        BanaOzelSortMode.priceLow => 'Ucuz',
        BanaOzelSortMode.priceHigh => 'Pahalı',
      };
}

class _WatchAdPromoBanner extends StatelessWidget {
  const _WatchAdPromoBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: UltraFortuneLiquidSurface(
        onTap: onTap,
        goldAccent: true,
        borderRadius: BorderRadius.circular(16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.play_circle_fill_rounded, color: Color(0xFFFFD54F)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Reklam izle — jeton kazan ve içerik aç',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}

class _FreeContentBand extends StatelessWidget {
  const _FreeContentBand({
    required this.items,
    required this.onOpen,
  });

  final List<BanaOzelItemEntity> items;
  final ValueChanged<BanaOzelItemEntity> onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ücretsiz içerikler',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final item = items[i];
                return ActionChip(
                  label: Text('${item.icon} ${item.nameTr}'),
                  onPressed: () => onOpen(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OpenHistoryStrip extends StatelessWidget {
  const _OpenHistoryStrip({
    required this.entries,
    required this.onTap,
  });

  final List<BanaOzelOpenHistoryEntry> entries;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Son açılanlar',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final e = entries[i];
                return ActionChip(
                  label: Text(e.title, style: const TextStyle(fontSize: 11)),
                  onPressed: () => onTap(e.slug),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyTaskProgressBar extends StatelessWidget {
  const _DailyTaskProgressBar({
    required this.done,
    required this.total,
    required this.onTap,
  });

  final int done;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : done / total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: UltraFortuneLiquidSurface(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Günlük görev ilerlemesi',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  '$done / $total',
                  style: const TextStyle(
                    color: Color(0xFFFFD54F),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: Colors.white.withValues(alpha: 0.12),
                color: const Color(0xFFFFD54F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
