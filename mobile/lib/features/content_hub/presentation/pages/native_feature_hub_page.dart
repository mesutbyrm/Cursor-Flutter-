import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/native_site_routes.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/discover_tab_layout.dart';

enum NativeFeatureHubKind {
  games,
  dreams,
  blog,
  celebrities,
  fanClub,
  adRewards,
}

class NativeFeatureHubPage extends StatelessWidget {
  const NativeFeatureHubPage({super.key, required this.kind});

  final NativeFeatureHubKind kind;

  @override
  Widget build(BuildContext context) {
    final spec = _spec(kind);
    return DiscoverSubPage(
      title: spec.title,
      subtitle: spec.subtitle,
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
        children: [
          _HeroCard(spec: spec),
          const SizedBox(height: 16),
          for (final section in spec.sections) ...[
            Text(
              section.title,
              style: TextStyle(
                color: context.colors.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            for (final item in section.items) ...[
              _HubActionTile(item: item),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  static _HubSpec _spec(NativeFeatureHubKind kind) {
    return switch (kind) {
      NativeFeatureHubKind.games => _HubSpec(
          title: 'Oyunlar',
          subtitle: 'Çok oyunculu oyun, mini oyun ve turnuva merkezi',
          icon: Icons.sports_esports_rounded,
          summary:
              'Canlifal.com oyun sistemi için native giriş: oyun lobisi, otomatik eşleşme, skorlar ve turnuvalar mevcut API sözleşmeleriyle aşamalı bağlanır.',
          sections: [
            _HubSection(
              'Hızlı giriş',
              [
                _HubItem('Oyun listesi', 'Ana sayfadaki canlı oyun/etkinlik API listesini aç.', Icons.grid_view_rounded, '/feed'),
                _HubItem('Görevler & oyun XP', 'Günlük görev ve XP ilerlemesini gör.', Icons.emoji_events_rounded, '/profile/growth'),
                _HubItem('Turnuvalar', 'Haftalık turnuvalar ve rekabet akışı.', Icons.workspace_premium_rounded, '/games-hub'),
              ],
            ),
            _HubSection(
              'Web parite kapsamı',
              [
                _HubItem('Çok oyunculu oyunlar', 'XOX, Tombala, Tavla, Okey, Pişti, Connect4 ve diğer oda tabanlı oyunlar.', Icons.groups_rounded, '/games-hub'),
                _HubItem('Mini oyunlar', '2048, Anagram, Sudoku, Slot, Quiz ve skor kaydetme akışı.', Icons.extension_rounded, '/games-hub'),
              ],
            ),
          ],
        ),
      NativeFeatureHubKind.dreams => _HubSpec(
          title: 'Rüya Merkezi',
          subtitle: 'Rüya yorumu, sözlük, yarışma ve trendler',
          icon: Icons.nights_stay_rounded,
          summary:
              'Web’deki rüya günlüğü ve sözlük sistemi için native merkez. Rüya yorumu mevcut fal akışına bağlanır; sözlük/trend uçları için API sabitleri hazırdır.',
          sections: [
            _HubSection('Rüya aksiyonları', [
              _HubItem('Rüya yorumu al', 'Mevcut fal ekranında rüyanı yorumlat.', Icons.auto_awesome_rounded, '/fortune/ruya-tabiri'),
              _HubItem('Rüya sözlüğü', 'Sembol ve anlam listesi için native liste fazına hazır.', Icons.auto_stories_rounded, '/dreams-hub'),
              _HubItem('Rüya trendleri', 'Popüler rüyalar ve haftalık raporlar.', Icons.trending_up_rounded, '/dreams-hub'),
            ]),
          ],
        ),
      NativeFeatureHubKind.blog => _HubSpec(
          title: 'Blog & Rehberler',
          subtitle: 'Blog, burç ve SEO içerikleri',
          icon: Icons.menu_book_rounded,
          summary:
              'Canlifal.com blog API uçları mobilde tanımlandı. Native liste/detay ekranı için giriş noktası ve kategori ayrımı hazır.',
          sections: [
            _HubSection('İçerik', [
              _HubItem('Son yazılar', 'Blog/recent sözleşmesiyle native liste fazına hazır.', Icons.article_rounded, '/blog-hub'),
              _HubItem('Burç blogları', 'Burç ve astroloji yazıları.', Icons.star_rounded, '/blog-hub'),
              _HubItem('Fal rehberleri', 'Fal deneyimini destekleyen içerikler.', Icons.psychology_rounded, '/fortune'),
            ]),
          ],
        ),
      NativeFeatureHubKind.celebrities => _HubSpec(
          title: 'Ünlüler',
          subtitle: 'Ünlü profilleri, takip ve paylaşımlar',
          icon: Icons.star_rounded,
          summary:
              'Ünlü profili, takip ve paylaşım API sözleşmeleri mobilde tanımlandı. Native fan akışı bu merkezden büyütülür.',
          sections: [
            _HubSection('Keşfet', [
              _HubItem('Ünlü listesi', 'Ünlü profilleri ve takip akışı.', Icons.person_search_rounded, '/celebrities-hub'),
              _HubItem('Sosyal akış', 'Ünlü ve topluluk paylaşımlarını sosyal akışta takip et.', Icons.dynamic_feed_rounded, '/social'),
            ]),
          ],
        ),
      NativeFeatureHubKind.fanClub => _HubSpec(
          title: 'Fan Club',
          subtitle: 'Kulüp üyelikleri, paylaşımlar ve anketler',
          icon: Icons.favorite_rounded,
          summary:
              'Fan kulübü web sistemi için native giriş. Kulübe katılma, post ve anket endpointleri tanımlandı; ana sayfa fan kartları buraya bağlandı.',
          sections: [
            _HubSection('Kulüp aksiyonları', [
              _HubItem('Fan kulüpleri', 'Kulüp listesi ve üyelik akışı için merkez.', Icons.groups_rounded, '/fan-club-hub'),
              _HubItem('Davet et', 'Arkadaşlarını kulüplere davet et.', Icons.ios_share_rounded, '/invite-friends'),
              _HubItem('Sosyal paylaşım', 'Kulüp postlarını sosyal deneyime bağla.', Icons.post_add_rounded, '/social'),
            ]),
          ],
        ),
      NativeFeatureHubKind.adRewards => _HubSpec(
          title: 'Reklamla Kredi',
          subtitle: 'Reklam izleyerek ödül kazan',
          icon: Icons.play_circle_fill_rounded,
          summary:
              'Web’deki watch-ad-credit akışı için mobil endpoint ve büyüme merkezi girişi eklendi. Gerçek reklam SDK’sı bağlanınca aynı POST akışı kullanılacak.',
          sections: [
            _HubSection('Ödül', [
              _HubItem('Görevler & Rozetler', 'Reklam ödülünü büyüme görevleriyle birlikte gör.', Icons.emoji_events_rounded, '/profile/growth'),
              _HubItem('Jeton mağazası', 'Ödül sonrası bakiyeni ve paketleri kontrol et.', Icons.toll_rounded, '/jeton-store'),
            ]),
          ],
        ),
    };
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.spec});

  final _HubSpec spec;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: context.colors.brandGradient,
      ),
      child: Row(
        children: [
          Icon(spec.icon, color: Colors.white, size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              spec.summary,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HubActionTile extends StatelessWidget {
  const _HubActionTile({required this.item});

  final _HubItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(item.icon, color: context.colors.primary),
        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(item.subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {
          final route = item.route;
          if (route == '/feed' || route == '/social' || route == '/live') {
            context.go(route);
            return;
          }
          if (route.startsWith('/')) {
            context.push(route);
            return;
          }
          openNativeSitePath(context, route);
        },
      ),
    );
  }
}

class _HubSpec {
  const _HubSpec({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.summary,
    required this.sections,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String summary;
  final List<_HubSection> sections;
}

class _HubSection {
  const _HubSection(this.title, this.items);

  final String title;
  final List<_HubItem> items;
}

class _HubItem {
  const _HubItem(this.title, this.subtitle, this.icon, this.route);

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
}
