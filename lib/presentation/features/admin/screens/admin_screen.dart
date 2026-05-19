import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:canlifal_mobile/domain/entities/entities.dart';
import 'package:canlifal_mobile/presentation/providers/providers.dart';
import 'package:canlifal_mobile/presentation/widgets/shared_widgets.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<AdminMetric>> metrics = ref.watch(
      adminMetricsProvider,
    );
    return ResponsiveMaxWidth(
      child: CustomScrollView(
        slivers: <Widget>[
          const SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Admin & Moderasyon',
              subtitle: 'Kullanıcı, yayın, içerik, coin ve şikayet yönetimi',
            ),
          ),
          metrics.when(
            data: (List<AdminMetric> items) => SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverGrid.builder(
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 280,
                  mainAxisExtent: 140,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemBuilder: (BuildContext context, int index) {
                  final AdminMetric metric = items[index];
                  return GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          metric.title,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const Spacer(),
                        Text(
                          metric.value,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          metric.delta,
                          style: const TextStyle(color: Color(0xFF22C55E)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (Object error, StackTrace stackTrace) =>
                SliverToBoxAdapter(child: Text('$error')),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList.list(
              children: const <Widget>[
                _AdminPanel(
                  icon: Icons.people_alt_outlined,
                  title: 'Kullanıcı yönetimi',
                  body:
                      'Seviye, rozet, takipçi güvenliği, engel ve hesap durumları.',
                ),
                SizedBox(height: 12),
                _AdminPanel(
                  icon: Icons.live_tv,
                  title: 'Yayın yönetimi',
                  body:
                      'Canlı yayın kapatma, moderatör atama, çoklu yayın kontrolü.',
                ),
                SizedBox(height: 12),
                _AdminPanel(
                  icon: Icons.report_outlined,
                  title: 'Şikayet ve içerik kontrol',
                  body:
                      'Kuyruk, önceliklendirme, içerik kaldırma ve kullanıcı uyarıları.',
                ),
                SizedBox(height: 12),
                _AdminPanel(
                  icon: Icons.monetization_on_outlined,
                  title: 'Coin yönetimi',
                  body: 'Hediye ekonomisi, paketler, iade ve anomali takibi.',
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 110)),
        ],
      ),
    );
  }
}

class _AdminPanel extends StatelessWidget {
  const _AdminPanel({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(body),
        trailing: FilledButton.tonal(onPressed: () {}, child: const Text('Aç')),
      ),
    );
  }
}
