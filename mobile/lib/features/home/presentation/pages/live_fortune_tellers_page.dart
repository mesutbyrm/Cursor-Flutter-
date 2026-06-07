import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/ui/premium/live_badge.dart';
import '../../../../core/ui/premium_2026/cosmic_galaxy_background.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/entities/live_fortune_teller_entity.dart';
import '../providers/home_providers.dart';
import '../theme/home_palette.dart';

/// canlifal.com `/canli-falcilar` — falcı listesi.
class LiveFortuneTellersPage extends ConsumerWidget {
  const LiveFortuneTellersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tellers = ref.watch(homeLiveFortuneTellersProvider);

    return Scaffold(
      backgroundColor: HomePalette.darkBackground,
      appBar: AppBar(
        title: const Text('Canlı Falcılar'),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: CosmicGalaxyBackground(
        child: SafeArea(
          child: tellers.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                ApiException.userMessage(e),
                textAlign: TextAlign.center,
              ),
            ),
            data: (list) {
              final authed = ref.watch(authControllerProvider).valueOrNull != null;
              if (!authed) {
                return Center(
                  child: Text(
                    'Canlı falcılar için giriş yapın.',
                    style: TextStyle(color: context.colors.onSurfaceMuted),
                  ),
                );
              }
              if (list.isEmpty) {
                return Center(
                  child: Text(
                    'Şu an çevrimiçi falcı yok.',
                    style: TextStyle(color: context.colors.onSurfaceMuted),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(homeLiveFortuneTellersProvider);
                  await ref.read(homeLiveFortuneTellersProvider.future);
                },
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _TellerListTile(teller: list[i]),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TellerListTile extends StatelessWidget {
  const _TellerListTile({required this.teller});

  final LiveFortuneTellerEntity teller;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => context.push('/canli-falcilar/${teller.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Stack(
                children: [
                  teller.avatarUrl != null && teller.avatarUrl!.isNotEmpty
                      ? CircleAvatar(
                          radius: 28,
                          backgroundImage:
                              CachedNetworkImageProvider(teller.avatarUrl!),
                        )
                      : const UserAvatar(radius: 28),
                  if (teller.isOnline)
                    const Positioned(
                      right: 0,
                      bottom: 0,
                      child: LiveBadge(compact: true),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teller.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      teller.displayCategory,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.onSurfaceMuted,
                      ),
                    ),
                    if (teller.rating > 0)
                      Text(
                        '★ ${teller.rating.toStringAsFixed(1)} · ${teller.reviewCount} yorum',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.colors.onSurfaceMuted,
                        ),
                      ),
                  ],
                ),
              ),
              if (teller.pricePerMinute > 0)
                Text(
                  '${teller.pricePerMinute}💎/dk',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
