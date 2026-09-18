import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/util/json_util.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../../platform_social/presentation/widgets/platform_social_ui_kit.dart';
import '../providers/social_discovery_providers.dart';
import '../utils/discovery_hashtag_navigation.dart';

/// Hashtag ve takımlar — Tanış Kaynaş yan menü.
class TanisKaynasExtrasPage extends ConsumerStatefulWidget {
  const TanisKaynasExtrasPage({super.key});

  @override
  ConsumerState<TanisKaynasExtrasPage> createState() =>
      _TanisKaynasExtrasPageState();
}

class _TanisKaynasExtrasPageState extends ConsumerState<TanisKaynasExtrasPage> {
  final _hashtagQuery = TextEditingController();

  @override
  void dispose() {
    _hashtagQuery.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(socialTrendingHashtagsProvider);
    ref.invalidate(socialTeamsListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final hashtags = ref.watch(socialTrendingHashtagsProvider);
    final teams = ref.watch(socialTeamsListProvider);

    return Scaffold(
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: 'Hashtag & Takım',
          subtitle: 'Trend etiketler ve topluluk takımları',
          body: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                TextField(
                  controller: _hashtagQuery,
                  decoration: InputDecoration(
                    labelText: 'Hashtag ara',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () async {
                        final q = _hashtagQuery.text.trim();
                        if (q.isEmpty) return;
                        try {
                          await ref
                              .read(socialDiscoveryRemoteProvider)
                              .searchHashtags(q: q);
                        } catch (_) {}
                        // `build` parametresi State.context'i gölgeliyor;
                        // koruma o BuildContext üzerinden olmalı.
                        if (!context.mounted) return;
                        applyDiscoveryInterestFilter(
                          context,
                          ref,
                          interest: q,
                          snackMessage: 'Keşif filtresi: $q',
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const PlatformSocialSectionTitle('Trend hashtag'),
                hashtags.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Text(ApiException.userMessage(e)),
                  data: (map) {
                    final list = pick(map, ['hashtags', 'items', 'trending']);
                    if (list is! List || list.isEmpty) {
                      return const Text('Trend verisi yok');
                    }
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final h in list)
                          if (h is Map)
                            ActionChip(
                              label: Text(
                                '#${pick(Map<String, dynamic>.from(h), ['name', 'tag']) ?? ''}',
                              ),
                              onPressed: () {
                                final name =
                                    pick(Map<String, dynamic>.from(h), [
                                  'name',
                                  'tag',
                                ])?.toString();
                                if (name == null || name.isEmpty) return;
                                applyDiscoveryInterestFilter(
                                  context,
                                  ref,
                                  interest: name,
                                  snackMessage:
                                      'Keşif filtresi: $name',
                                );
                              },
                            ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                const PlatformSocialSectionTitle('Takımlar'),
                teams.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text(ApiException.userMessage(e)),
                  data: (map) {
                    final list = pick(map, ['teams', 'items', 'data']);
                    if (list is! List || list.isEmpty) {
                      return const Text('Takım listesi boş');
                    }
                    return Column(
                      children: [
                        for (final t in list)
                          if (t is Map)
                            PlatformSocialListRow(
                              title: (pick(Map<String, dynamic>.from(t), [
                                        'name',
                                        'title',
                                      ]) ??
                                      'Takım')
                                  .toString(),
                              subtitle: pick(Map<String, dynamic>.from(t), ['id'])
                                      ?.toString() ??
                                  '',
                              leading: const Icon(
                                Icons.groups_rounded,
                                color: PlatformSocialPalette.accent,
                              ),
                              onTap: () {
                                final id =
                                    pick(Map<String, dynamic>.from(t), ['id'])
                                        ?.toString();
                                if (id != null && id.isNotEmpty) {
                                  context.push('/teams/$id');
                                }
                              },
                            ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
