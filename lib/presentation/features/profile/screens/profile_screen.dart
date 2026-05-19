import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:canlifal_mobile/domain/entities/entities.dart';
import 'package:canlifal_mobile/presentation/providers/providers.dart';
import 'package:canlifal_mobile/presentation/widgets/shared_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppUser? user = ref.watch(authControllerProvider).user;
    if (user == null) {
      return const Center(child: Text('Profil için giriş yapmanız gerekiyor.'));
    }
    return ResponsiveMaxWidth(
      child: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(child: _ProfileHeader(user: user)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  StatPill(
                    icon: Icons.people,
                    label: 'takipçi',
                    value: compactNumber(user.followers),
                  ),
                  StatPill(
                    icon: Icons.person_add,
                    label: 'takip',
                    value: compactNumber(user.following),
                  ),
                  StatPill(
                    icon: Icons.bolt,
                    label: 'seviye',
                    value: '${user.level}',
                  ),
                  StatPill(
                    icon: Icons.monetization_on,
                    label: 'coin',
                    value: compactNumber(user.coins),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SectionHeader(
                      title: 'FanClub & Premium',
                      subtitle:
                          'Özel içerikler, rozetler, kapalı yayınlar ve coin bonusları',
                    ),
                    Wrap(
                      spacing: 10,
                      children: <Widget>[
                        FilledButton.icon(
                          onPressed: () => ref
                              .read(authControllerProvider)
                              .activatePremium(),
                          icon: const Icon(Icons.workspace_premium),
                          label: const Text('VIP yükselt'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.group),
                          label: const Text('FanClub yönet'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Profil gönderileri',
              subtitle: 'Paylaşım, beğeni, yorum ve kaydet sistemi',
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: GlassCard(
                child: Text(
                  'Profil gönderileri Canlifal kullanıcı API’sinden döndüğünde burada listelenir.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 110)),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              height: 210,
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: <Widget>[
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: user.coverUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Colors.transparent,
                          Colors.black.withValues(alpha: .84),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    bottom: -40,
                    child: GradientAvatar(
                      imageUrl: user.avatarUrl,
                      radius: 48,
                      isLive: user.isOnline,
                    ),
                  ),
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.edit),
                      label: const Text('Profili düzenle'),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          user.displayName,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      Chip(label: Text(tierLabel(user.tier))),
                    ],
                  ),
                  Text(
                    '@${user.username}',
                    style: const TextStyle(color: Colors.white60),
                  ),
                  const SizedBox(height: 12),
                  Text(user.bio),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    children: <Widget>[
                      for (final BadgeKind badge in user.badges)
                        Chip(
                          avatar: const Icon(Icons.verified, size: 16),
                          label: Text(badgeLabel(badge)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
