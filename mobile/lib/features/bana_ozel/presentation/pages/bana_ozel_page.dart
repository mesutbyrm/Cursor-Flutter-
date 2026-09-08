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
import '../../../fortune/presentation/widgets/ultra_premium/ultra_fortune_tokens.dart';
import '../../domain/entities/bana_ozel_entities.dart';
import '../providers/bana_ozel_providers.dart';
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
                        '✨ Bana Özel',
                        style: GoogleFonts.playfairDisplay(
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
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
                loading: () => const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(ApiException.userMessage(e)),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () =>
                              ref.invalidate(banaOzelCatalogProvider),
                          child: const Text('Yenile'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (data) {
                  if (data.items.isEmpty) {
                    return const Expanded(
                      child: Center(child: Text('Henüz içerik yok')),
                    );
                  }
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _tryOpenPendingSlug(data);
                  });
                  final filtered = data.itemsForCategory(
                    _category == 'all' ? null : _category,
                  );
                  return Expanded(
                    child: RefreshIndicator(
                      onRefresh: () =>
                          ref.read(banaOzelCatalogProvider.notifier).refresh(),
                      child: CustomScrollView(
                        slivers: [
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
                                    _TodayTasksStrip(tasks: data.parsedTodayTasks),
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
                                  final affordable = data.canAffordItem(item);
                                  return _ItemCard(
                                    item: item,
                                    opening: opening,
                                    affordable: affordable,
                                    onTap: opening
                                        ? null
                                        : () => _openItem(item, data),
                                  );
                                },
                                childCount: filtered.length,
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
  const _TodayTasksStrip({required this.tasks});

  final List<BanaOzelTodayTask> tasks;

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
                    : () => context.push(task.routePath!),
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

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.opening,
    required this.affordable,
    this.onTap,
  });

  final BanaOzelItemEntity item;
  final bool opening;
  final bool affordable;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: affordable ? 0.08 : 0.04),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.icon, style: const TextStyle(fontSize: 28)),
              const Spacer(),
              Text(
                item.nameTr,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              if (item.descTr != null && item.descTr!.trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  item.descTr!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                item.categoryLabel,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 8),
              if (opening)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Row(
                  children: [
                    Text(
                      '${item.jetonCost}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: affordable
                            ? const Color(0xFFFFD54F)
                            : Colors.white38,
                      ),
                    ),
                    Icon(
                      Icons.monetization_on_rounded,
                      size: 14,
                      color: affordable
                          ? const Color(0xFFFFD54F)
                          : Colors.white24,
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
