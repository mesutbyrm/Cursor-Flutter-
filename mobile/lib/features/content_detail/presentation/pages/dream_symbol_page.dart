import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../data/content_detail_remote_datasource.dart';
import '../widgets/content_detail_widgets.dart';

/// Rüya sözlüğü sembolü — `GET /api/dream-symbols/{slug}`.
class DreamSymbolPage extends ConsumerWidget {
  const DreamSymbolPage({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dreamSymbolProvider(slug));
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: async.valueOrNull?.name ?? 'Rüya Sözlüğü',
          subtitle: 'Rüyada görmek',
          body: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ContentMessage(
              text: ApiException.userMessage(e),
              onRetry: () => ref.invalidate(dreamSymbolProvider(slug)),
            ),
            data: (s) => ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: [
                Text(
                  s.meaning,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
                if ((s.detailedMeaning ?? '').isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SelectableText(
                    s.detailedMeaning!,
                    style: const TextStyle(height: 1.55, fontSize: 15),
                  ),
                ],
                if (s.related.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'İlgili semboller',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final r in s.related)
                        ActionChip(
                          label: Text(r.name),
                          onPressed: () => context.pushReplacement(
                            '/ruya-sozlugu/${Uri.encodeComponent(r.slug)}',
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
