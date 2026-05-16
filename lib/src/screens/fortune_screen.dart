import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../state.dart';
import '../widgets.dart';

class FortuneScreen extends ConsumerStatefulWidget {
  const FortuneScreen({super.key});

  @override
  ConsumerState<FortuneScreen> createState() => _FortuneScreenState();
}

class _FortuneScreenState extends ConsumerState<FortuneScreen> {
  FortuneCategory? _category;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<FortuneService>> services = ref.watch(
      fortuneServicesProvider,
    );
    return ResponsiveMaxWidth(
      child: CustomScrollView(
        slivers: <Widget>[
          const SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Fal & Tarot',
              subtitle:
                  'Canlı danışmanlar, kategoriler, puanlama ve sıra sistemi',
            ),
          ),
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: <Widget>[
                  ChoiceChip(
                    label: const Text('Tümü'),
                    selected: _category == null,
                    onSelected: (_) => setState(() => _category = null),
                  ),
                  const SizedBox(width: 8),
                  for (final FortuneCategory category in FortuneCategory.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(_categoryLabel(category)),
                        selected: _category == category,
                        onSelected: (_) => setState(() => _category = category),
                      ),
                    ),
                ],
              ),
            ),
          ),
          services.when(
            data: (List<FortuneService> items) {
              final List<FortuneService> filtered = _category == null
                  ? items
                  : items
                        .where(
                          (FortuneService service) =>
                              service.category == _category,
                        )
                        .toList();
              return SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverGrid.builder(
                  itemCount: filtered.length,
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: MediaQuery.sizeOf(context).width > 700
                        ? 360
                        : 480,
                    mainAxisExtent: 278,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemBuilder: (BuildContext context, int index) {
                    return _FortuneCard(service: filtered[index]);
                  },
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (Object error, StackTrace stackTrace) =>
                SliverToBoxAdapter(child: Text('$error')),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 110)),
        ],
      ),
    );
  }

  String _categoryLabel(FortuneCategory category) {
    return switch (category) {
      FortuneCategory.coffee => 'Kahve falı',
      FortuneCategory.tarot => 'Tarot',
      FortuneCategory.astrology => 'Astroloji',
      FortuneCategory.dream => 'Rüya',
      FortuneCategory.numerology => 'Numeroloji',
    };
  }
}

class _FortuneCard extends ConsumerWidget {
  const _FortuneCard({required this.service});

  final FortuneService service;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              GradientAvatar(
                imageUrl: service.advisor.avatarUrl,
                radius: 28,
                isLive: service.isLive,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      service.title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      service.advisor.displayName,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Icon(
                service.isLive ? Icons.sensors : Icons.schedule,
                color: service.isLive ? Colors.redAccent : Colors.amber,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              StatPill(
                icon: Icons.star,
                label: 'puan',
                value: service.rating.toStringAsFixed(1),
              ),
              StatPill(
                icon: Icons.queue,
                label: 'sıra',
                value: '${service.queueCount}',
              ),
              StatPill(
                icon: Icons.monetization_on,
                label: 'coin',
                value: '${service.priceCoins}',
              ),
            ],
          ),
          const Spacer(),
          Text(
            'Canlı danışman sistemi, kullanıcı puanlama ve moderasyon akışı hazır.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white60),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => ref
                      .read(authControllerProvider)
                      .spendCoins(service.priceCoins),
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Sıraya gir'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                onPressed: () {},
                icon: const Icon(Icons.favorite_border),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
