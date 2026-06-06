import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/ui/premium/live_badge.dart';
import '../../../../core/ui/premium_2026/cosmic_galaxy_background.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../providers/home_providers.dart';
import '../theme/home_palette.dart';

/// canlifal.com `/canli-falcilar/[tellerId]` — falcı profili.
Future<void> _startLiveSession(
  BuildContext context,
  WidgetRef ref,
  String tellerId,
) async {
  final remote = ref.read(homeRemoteProvider);
  final session = await remote.createFortuneTellerSession(tellerId);
  if (!context.mounted) return;
  if (session == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Oturum başlatılamadı. Oturum açık mı kontrol edin.'),
      ),
    );
    return;
  }
  ref.read(videoWebrtcSignalServiceProvider).start(
        streamId: session.sessionId,
      );
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'Fal oturumu başladı (#${session.sessionId}). Sinyal kanalı açık.',
      ),
    ),
  );
  context.push('/messages');
}

class LiveFortuneTellerDetailPage extends ConsumerWidget {
  const LiveFortuneTellerDetailPage({super.key, required this.tellerId});

  final String tellerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tellerAsync = ref.watch(liveFortuneTellerProvider(tellerId));

    return Scaffold(
      backgroundColor: HomePalette.darkBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Falcı Profili'),
      ),
      body: CosmicGalaxyBackground(
        child: SafeArea(
          child: tellerAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(ApiException.userMessage(e))),
            data: (teller) {
              if (teller == null) {
                return const Center(child: Text('Falcı bulunamadı.'));
              }
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Center(
                    child: Stack(
                      children: [
                        teller.avatarUrl != null &&
                                teller.avatarUrl!.isNotEmpty
                            ? CircleAvatar(
                                radius: 52,
                                backgroundImage: CachedNetworkImageProvider(
                                  teller.avatarUrl!,
                                ),
                              )
                            : const UserAvatar(radius: 52),
                        if (teller.isOnline)
                          const Positioned(
                            right: 4,
                            bottom: 4,
                            child: LiveBadge(),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    teller.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                  if (teller.levelLabel != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        teller.levelLabel!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.colors.onSurfaceMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    teller.displayCategory,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.colors.onSurfaceMuted),
                  ),
                  if (teller.rating > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      '★ ${teller.rating.toStringAsFixed(1)} (${teller.reviewCount} değerlendirme)',
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (teller.bio != null && teller.bio!.trim().isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      teller.bio!,
                      style: TextStyle(
                        height: 1.4,
                        color: context.colors.onSurface.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                  if (teller.specialties.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final s in teller.specialties)
                          Chip(label: Text(s)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: teller.isOnline
                        ? () => _startLiveSession(context, ref, teller.id)
                        : null,
                    icon: const Icon(Icons.videocam_rounded),
                    label: Text(
                      teller.isOnline
                          ? 'Canlı Fal Oturumu Başlat'
                          : 'Şu an çevrimdışı',
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: teller.isOnline
                        ? () => context.push('/messages')
                        : null,
                    icon: const Icon(Icons.chat_rounded),
                    label: const Text('Mesaj Gönder'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/fortune'),
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('Fal & Tarot'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
