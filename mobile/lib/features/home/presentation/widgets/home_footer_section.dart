import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/navigation/native_site_routes.dart';
import '../../../../core/widgets/canlifal_logo.dart';
import '../../../platform/data/models/platform_popup.dart';
import '../../domain/entities/home_blog_post_entity.dart';
import '../../domain/home_site_catalog.dart';
import '../providers/home_providers.dart';
import '../theme/home_approved_design.dart';
import 'approved/home_section_title.dart';

/// Alt bölüm — duyurular, sosyal medya, kapanış alıntısı (referans ekran 4).
class HomeFooterSection extends ConsumerWidget {
  const HomeFooterSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final popups = ref.watch(homePopupsProvider);
    final blog = ref.watch(homeBlogRecentProvider);
    final rows = _buildAnnouncementRows(popups, blog);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (rows.isNotEmpty) ...[
          const HomeSectionTitle(
            emoji: '📣',
            title: 'Duyurular',
          ),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: HomeApprovedDesign.hPad,
                vertical: 4,
              ),
              child: row,
            ),
          const SizedBox(height: 20),
        ],
        const _SocialMediaRow(),
        const SizedBox(height: 24),
        const _ClosingQuote(),
        const SizedBox(height: 8),
      ],
    );
  }

  List<_AnnouncementRow> _buildAnnouncementRows(
    AsyncValue<List<PlatformPopup>> popups,
    AsyncValue<List<HomeBlogPostEntity>> blog,
  ) {
    final rows = <_AnnouncementRow>[];

    final popupItems = popups.valueOrNull;
    if (popupItems != null && popupItems.isNotEmpty) {
      for (final p in popupItems.take(3)) {
        rows.add(
          _AnnouncementRow(
            icon: _iconForPopup(p),
            title: p.title,
            onTap: (context) {
              final url = p.actionUrl?.trim();
              if (url != null && url.isNotEmpty) {
                openNativeSitePath(context, url);
              }
            },
          ),
        );
      }
      return rows;
    }

    final posts = blog.valueOrNull;
    if (posts != null && posts.isNotEmpty) {
      for (final post in posts.take(3)) {
        rows.add(
          _AnnouncementRow(
            icon: Icons.article_outlined,
            title: post.title,
            onTap: (context) => openNativeSitePath(context, post.route),
          ),
        );
      }
    }

    return rows;
  }

  static IconData _iconForPopup(PlatformPopup p) {
    final t = (p.type ?? '').toLowerCase();
    if (t.contains('maint') || t.contains('bakim')) {
      return Icons.settings_rounded;
    }
    if (t.contains('gift') || t.contains('event')) {
      return Icons.card_giftcard_rounded;
    }
    return Icons.campaign_rounded;
  }
}

class _AnnouncementRow extends StatelessWidget {
  const _AnnouncementRow({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final void Function(BuildContext context) onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HomeApprovedDesign.surface,
      borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
      child: InkWell(
        onTap: () => onTap(context),
        borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
            border: Border.all(color: HomeApprovedDesign.border),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: HomeApprovedDesign.purple),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: HomeApprovedDesign.textPrimary,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: HomeApprovedDesign.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialMediaRow extends StatelessWidget {
  const _SocialMediaRow();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const HomeSectionTitle(
          emoji: '🌐',
          title: 'Sosyal Medyada Biz',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: HomeApprovedDesign.hPad),
          child: Text(
            'Topluluğumuza katıl, güncellemeleri kaçırma.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: HomeApprovedDesign.textSecondary.withValues(alpha: 0.95),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: HomeApprovedDesign.hPad),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final ch in HomeSiteCatalog.socialChannels)
                _SocialIconButton(channel: ch),
            ],
          ),
        ),
      ],
    );
  }
}

class _SocialIconButton extends StatelessWidget {
  const _SocialIconButton({required this.channel});

  final HomeSocialChannel channel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HomeApprovedDesign.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () async {
          final uri = Uri.tryParse(channel.url);
          if (uri == null) return;
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: HomeApprovedDesign.border),
            gradient: LinearGradient(
              colors: [
                HomeApprovedDesign.purple.withValues(alpha: 0.25),
                HomeApprovedDesign.pink.withValues(alpha: 0.12),
              ],
            ),
          ),
          child: Icon(
            channel.icon,
            color: HomeApprovedDesign.textPrimary,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _ClosingQuote extends StatelessWidget {
  const _ClosingQuote();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: HomeApprovedDesign.hPad),
      child: Column(
        children: [
          Text(
            '"Falın da, sohbetin de, dostluğun da burada…"',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
              color: HomeApprovedDesign.purple.withValues(alpha: 0.95),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: CanlifalWordmark(fontSize: 20, compact: true),
          ),
        ],
      ),
    );
  }
}
