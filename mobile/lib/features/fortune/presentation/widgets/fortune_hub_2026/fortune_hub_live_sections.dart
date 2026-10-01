import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/economy/presentation/providers/economy_providers.dart';
import '../../../../../core/images/canlifal_image_urls.dart';
import '../../../../../core/images/canlifal_network_image.dart';
import '../../../../../core/push/push_notification_service.dart';
import '../../../../bana_ozel/presentation/navigation/bana_ozel_navigation.dart';
import '../../../../bana_ozel/presentation/providers/bana_ozel_providers.dart';
import '../../../../home/domain/entities/home_trend_video_entity.dart';
import '../../../../home/presentation/providers/home_providers.dart';
import '../../../../live_psychics/domain/entities/psychic_entity.dart';
import '../../../../profile/presentation/providers/profile_providers.dart';
import '../../../../live_psychics/presentation/navigation/psychic_card_navigation.dart';
import '../../../../live_psychics/presentation/providers/live_psychics_providers.dart';
import '../../../../shorts/presentation/widgets/shorts_hub_strip.dart';
import '../../data/fortune_ready_readings_data.dart';
import '../../providers/fortune_hub_providers.dart';
import 'fortune_hub_kit.dart';

/// Canlı falcılar — `homeDisplayedPsychicsProvider` (gerçek falcı API'si).
class FortuneHubPsychics extends ConsumerWidget {
  const FortuneHubPsychics({super.key});

  static const _cardW = 124.0;
  static const _cardH = 196.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final psychics = ref.watch(homeDisplayedPsychicsProvider);

    return FortuneSection(
      header: FortuneSectionHeader(
        title: 'CANLI FALCILAR',
        icon: Icons.blur_circular_rounded,
        iconColor: FortuneUi.violet,
        onAll: () => context.push('/canli-falcilar'),
        allLabel: 'Tümünü Gör',
      ),
      child: psychics.when(
        loading: () =>
            const FortuneRowSkeleton(height: _cardH, itemWidth: _cardW),
        error: (_, _) => FortuneInlineState(
          icon: Icons.cloud_off_rounded,
          message: 'Falcılar yüklenemedi',
          actionLabel: 'Tekrar dene',
          onAction: () => ref.invalidate(homeOnlinePsychicsProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const FortuneInlineState(
              icon: Icons.psychology_outlined,
              message:
                  'Şu anda müsait falcı bulunmuyor. Biraz sonra tekrar deneyin.',
            );
          }
          final preview = list.take(12).toList();
          return SizedBox(
            height: _cardH,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: preview.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _PsychicCard(
                psychic: preview[i],
                width: _cardW,
                onTap: () =>
                    openPsychicCardDestination(context, ref, preview[i]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PsychicCard extends ConsumerWidget {
  const _PsychicCard({
    required this.psychic,
    required this.width,
    required this.onTap,
  });

  final PsychicEntity psychic;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jeton = economyCurrencyLabel(ref, key: 'jeton');
    final url = psychic.avatarUrl?.trim();
    final online = psychic.isOnline;
    final badge = online
        ? ((psychic.presenceLabel?.trim().isNotEmpty ?? false)
              ? psychic.presenceLabel!.trim().toUpperCase()
              : 'MÜSAİT')
        : 'ÇEVRİMDIŞI';
    final badgeColor = online ? FortuneUi.green : FortuneUi.textMuted;

    return SizedBox(
      width: width,
      child: FortunePressable(
        onTap: onTap,
        semanticLabel: psychic.name,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(FortuneUi.radius),
            border: Border.all(color: FortuneUi.lilac.withValues(alpha: 0.4)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(FortuneUi.radius - 1),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (url != null && url.isNotEmpty)
                  CanlifalNetworkImage(
                    url: url,
                    fit: BoxFit.cover,
                    thumbnailWidth: 360,
                    fadeIn: false,
                    errorWidget: _Initial(name: psychic.name),
                  )
                else
                  _Initial(name: psychic.name),
                const FortuneImageScrim(strength: 0.92),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: online ? 0.9 : 0.45),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 9,
                  right: 6,
                  bottom: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        psychic.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (psychic.rating > 0)
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 13,
                              color: FortuneUi.gold,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              psychic.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: FortuneUi.gold,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      Text(
                        psychic.specialtiesLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 10.5,
                        ),
                      ),
                      if (psychic.pricePerMinute > 0)
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '${psychic.pricePerMinute} $jeton/dk',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: FortuneUi.gold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 15,
                              color: FortuneUi.gold,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Initial extends StatelessWidget {
  const _Initial({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final t = name.trim();
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: FortuneUi.purpleGradient),
      child: Center(
        child: Text(
          t.isEmpty ? '?' : t.characters.first.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 38,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

/// Kısa videolar — `homeTrendVideosProvider` (Shorts sistemi).
class FortuneHubShorts extends ConsumerWidget {
  const FortuneHubShorts({super.key});

  static const _w = 112.0;
  static const _h = 168.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videos = ref.watch(homeTrendVideosProvider);

    return FortuneSection(
      header: FortuneSectionHeader(
        title: 'KISA VİDEOLAR',
        icon: Icons.movie_creation_rounded,
        iconColor: FortuneUi.cyan,
        onAll: () => context.push('/shorts/explore'),
        allLabel: 'Tümünü Gör',
      ),
      child: videos.when(
        loading: () => const FortuneRowSkeleton(height: _h, itemWidth: _w),
        error: (_, _) => FortuneInlineState(
          icon: Icons.cloud_off_rounded,
          message: 'Kısa videolar yüklenemedi',
          actionLabel: 'Tekrar dene',
          onAction: () => ref.invalidate(homeTrendVideosProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const FortuneInlineState(
              icon: Icons.movie_outlined,
              message: 'Henüz kısa video yok',
            );
          }
          return SizedBox(
            height: _h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _VideoCard(
                video: items[i],
                width: _w,
                onTap: () => ShortsHubStrip.openVideo(context, ref, items[i]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({
    required this.video,
    required this.width,
    required this.onTap,
  });

  final HomeTrendVideoEntity video;
  final double width;
  final VoidCallback onTap;

  String? get _thumb {
    final raw = video.thumbnailUrl?.trim();
    if (raw != null && raw.isNotEmpty) {
      return CanlifalImageUrls.thumbnail(raw, width: 360);
    }
    final fromVideo = CanlifalImageUrls.thumbFromVideoUrl(video.videoUrl);
    if (fromVideo != null && fromVideo.isNotEmpty) {
      return CanlifalImageUrls.thumbnail(fromVideo, width: 360);
    }
    return null;
  }

  static String _count(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) {
      final k = n / 1000;
      return '${k.toStringAsFixed(k >= 10 ? 0 : 1)}K';
    }
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    final url = _thumb;
    return SizedBox(
      width: width,
      child: FortunePressable(
        onTap: onTap,
        semanticLabel: video.title,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(FortuneUi.radius),
            border: Border.all(color: FortuneUi.lilac.withValues(alpha: 0.35)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(FortuneUi.radius - 1),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (url != null)
                  CanlifalNetworkImage(
                    url: url,
                    fit: BoxFit.cover,
                    thumbnailWidth: 360,
                    fadeIn: false,
                    errorWidget: const _VideoPlaceholder(),
                  )
                else
                  const _VideoPlaceholder(),
                const FortuneImageScrim(strength: 0.7),
                const Center(
                  child: Icon(
                    Icons.play_circle_fill_rounded,
                    size: 34,
                    color: Colors.white70,
                  ),
                ),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.play_arrow_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                      Flexible(
                        child: Text(
                          _count(video.viewCount),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.favorite_rounded,
                        size: 12,
                        color: Color(0xFFFF4FD8),
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          _count(video.likesCount),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoPlaceholder extends StatelessWidget {
  const _VideoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(gradient: FortuneUi.purpleGradient),
    );
  }
}

/// Hazır yorumlar — mevcut hazır yorum içerikleri.
class FortuneHubReadyReadings extends StatelessWidget {
  const FortuneHubReadyReadings({super.key});

  static const _w = 124.0;
  static const _h = 206.0;

  @override
  Widget build(BuildContext context) {
    const items = fortuneReadyReadingItems;
    return FortuneSection(
      header: FortuneSectionHeader(
        title: 'HAZIR YORUMLAR',
        icon: Icons.menu_book_rounded,
        iconColor: FortuneUi.gold,
        onAll: () => context.push('/fortune/ready'),
        allLabel: 'Tümünü Gör',
      ),
      child: SizedBox(
        height: _h,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final item = items[i];
            return SizedBox(
              width: _w,
              child: FortunePressable(
                onTap: () => context.push('/fortune/ready'),
                semanticLabel: item.title,
                child: DecoratedBox(
                  decoration: FortuneUi.glass(strong: true),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(FortuneUi.radius),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 5, child: FortuneCover(slug: item.slug)),
                        Expanded(
                          flex: 4,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title.split(' ').first,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      size: 16,
                                      color: Colors.white70,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Expanded(
                                  child: Text(
                                    item.body,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: FortuneUi.caption.copyWith(
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Bana özel — gerçek `GET /api/bana-ozel` içerikleri.
class FortuneHubBanaOzel extends ConsumerWidget {
  const FortuneHubBanaOzel({super.key});

  static const _w = 118.0;
  static const _h = 132.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(banaOzelCatalogProvider);

    return FortuneSection(
      header: FortuneSectionHeader(
        title: 'BANA ÖZEL',
        icon: Icons.auto_fix_high_rounded,
        iconColor: FortuneUi.gold,
        onAll: () => openBanaOzelCatalog(context),
      ),
      child: catalog.when(
        loading: () => const FortuneRowSkeleton(height: _h, itemWidth: _w),
        error: (_, _) => FortuneInlineState(
          icon: Icons.refresh_rounded,
          message: 'Bana Özel içerikleri yüklenemedi',
          actionLabel: 'Tekrar dene',
          onAction: () => refreshBanaOzelCatalog(ref),
        ),
        data: (data) {
          if (data.items.isEmpty) {
            return FortuneInlineState(
              icon: Icons.auto_awesome_rounded,
              message: 'Size özel yeni içerikler hazırlanıyor.',
              actionLabel: 'Kataloğu aç',
              onAction: () => openBanaOzelCatalog(context),
            );
          }
          final preview = data.items.take(8).toList();
          return SizedBox(
            height: _h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: preview.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final item = preview[i];
                final img = item.imageUrl?.trim();
                return SizedBox(
                  width: _w,
                  child: FortunePressable(
                    onTap: () => openBanaOzelCatalog(context, slug: item.slug),
                    semanticLabel: item.nameTr,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(FortuneUi.radius),
                        border: Border.all(
                          color: FortuneUi.lilac.withValues(alpha: 0.4),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          FortuneUi.radius - 1,
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (img != null && img.isNotEmpty)
                              CanlifalNetworkImage(
                                url: img,
                                fit: BoxFit.cover,
                                thumbnailWidth: 360,
                                fadeIn: false,
                                errorWidget: _BanaIcon(icon: item.icon),
                              )
                            else
                              _BanaIcon(icon: item.icon),
                            const FortuneImageScrim(),
                            Positioned(
                              left: 9,
                              right: 5,
                              bottom: 8,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.nameTr,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                        height: 1.15,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 16,
                                    color: Colors.white70,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _BanaIcon extends StatelessWidget {
  const _BanaIcon({required this.icon});

  final String icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: FortuneUi.purpleGradient),
      child: Center(child: Text(icon, style: const TextStyle(fontSize: 34))),
    );
  }
}

/// Günlük fal hatırlatıcısı anahtarı (gerçek bildirim ayarı).
class FortuneHubReminderTile extends ConsumerWidget {
  const FortuneHubReminderTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeAsync = ref.watch(fortuneHubPreferencesStoreProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FortuneUi.padH,
        FortuneUi.sectionGap,
        FortuneUi.padH,
        0,
      ),
      child: storeAsync.when(
        loading: () => const SizedBox(height: 64),
        error: (_, _) => FortuneInlineState(
          icon: Icons.notifications_none_rounded,
          message: 'Hatırlatıcı ayarı yüklenemedi',
          actionLabel: 'Tekrar dene',
          onAction: () => ref.invalidate(fortuneHubPreferencesStoreProvider),
        ),
        data: (store) => FortuneGlassCard(
          strong: true,
          padding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
          child: Row(
            children: [
              const Icon(
                Icons.notifications_active_rounded,
                color: FortuneUi.gold,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Günlük Fal Hatırlatıcısı',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Her gün falına bakman için bildirim',
                      style: FortuneUi.caption,
                    ),
                  ],
                ),
              ),
              Switch(
                value: store.dailyReminderEnabled,
                activeThumbColor: Colors.white,
                activeTrackColor: FortuneUi.violet,
                onChanged: (v) async {
                  await store.setDailyReminderEnabled(v);
                  await PushNotificationService.instance
                      .setDailyFortuneReminderEnabled(v);
                  ref.invalidate(fortuneHubPreferencesStoreProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          v ? 'Hatırlatıcı açıldı' : 'Hatırlatıcı kapatıldı',
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kapanış bandı: katalog girişi.
class FortuneHubExploreBanner extends StatelessWidget {
  const FortuneHubExploreBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FortuneUi.padH,
        FortuneUi.sectionGap,
        FortuneUi.padH,
        0,
      ),
      child: FortunePressable(
        onTap: () => context.push('/fortune/types'),
        semanticLabel: 'Mistik dünyayı keşfet',
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(FortuneUi.radiusLg),
            border: Border.all(color: FortuneUi.gold.withValues(alpha: 0.35)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(FortuneUi.radiusLg - 1),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 110),
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: FortuneCover(slug: 'gunluk-fal', imageWidth: 720),
                  ),
                  const Positioned.fill(
                    child: FortuneImageScrim(strength: 0.9),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Mistik dünyayı keşfet',
                            textAlign: TextAlign.center,
                            style: FortuneUi.display(
                              19,
                              weight: FontWeight.w700,
                              color: FortuneUi.gold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Fal & Tarot ile yolculuğun başlıyor…',
                            textAlign: TextAlign.center,
                            style: FortuneUi.body.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Günlük görev ilerlemesi — `GET /api/daily-missions` (gerçek görevler).
class FortuneHubDailyMissions extends ConsumerWidget {
  const FortuneHubDailyMissions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(userDailyTasksProvider);

    return FortuneSection(
      header: FortuneSectionHeader(
        title: 'GÜNLÜK GÖREVLER',
        icon: Icons.task_alt_rounded,
        iconColor: FortuneUi.green,
        onAll: () => context.push('/profile/growth'),
      ),
      child: tasks.when(
        loading: () =>
            const FortuneRowSkeleton(height: 72, itemWidth: 300, count: 1),
        error: (_, _) => FortuneInlineState(
          icon: Icons.error_outline_rounded,
          message: 'Günlük görevler yüklenemedi',
          actionLabel: 'Tekrar dene',
          onAction: () => ref.invalidate(userDailyTasksProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const FortuneInlineState(
              icon: Icons.task_alt_rounded,
              message: 'Bugün için görev bulunamadı',
            );
          }
          final done = list.where((t) => t.completed).length;
          final progress = done / list.length;
          return FortuneGlassCard(
            onTap: () => context.push('/profile/growth'),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Bugünkü ilerlemen',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: FortuneUi.title,
                      ),
                    ),
                    Text(
                      '$done / ${list.length}',
                      style: const TextStyle(
                        color: FortuneUi.gold,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    color: FortuneUi.gold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
