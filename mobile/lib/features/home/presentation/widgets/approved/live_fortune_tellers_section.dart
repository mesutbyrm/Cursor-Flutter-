import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../voice_hub/presentation/utils/open_voice_chat_room_flow.dart';

import '../../../../../core/ui/premium/live_badge.dart';
import '../../../../../core/ui/premium/premium_skeleton.dart';
import '../../../domain/entities/live_fortune_teller_entity.dart';
import '../../providers/home_providers.dart';
import '../../providers/teller_profile_provider.dart';
import '../../theme/home_approved_design.dart';
import 'home_section_title.dart';

/// Canlı Falcılar — sesli oda kartları gibi kare/yatay kartlar.
class LiveFortuneTellersSection extends ConsumerWidget {
  const LiveFortuneTellersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tellers = ref.watch(homeLiveFortuneTellersProvider);

    return tellers.when(
      loading: () => Column(
        children: [
          HomeSectionTitle(
            emoji: '🔮',
            title: 'Canlı Falcılar',
            actionLabel: 'Tümünü Gör >',
            onAction: () => context.push('/canli-falcilar'),
          ),
          SizedBox(
            height: HomeApprovedDesign.tellerCardH,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: HomeApprovedDesign.hPad),
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, __) => const PremiumSkeleton(
                width: HomeApprovedDesign.tellerCardW,
                height: HomeApprovedDesign.tellerCardH,
                borderRadius: BorderRadius.all(
                  Radius.circular(HomeApprovedDesign.cardRadius),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const _QuickActions(),
        ],
      ),
      error: (e, _) => _emptyState(context, message: '$e'),
      data: (items) {
        final online = items.where((t) => t.isOnline).toList();
        final list = online.isNotEmpty ? online : items;
        if (list.isEmpty) return _emptyState(context);
        return _content(context, list.take(12).toList());
      },
    );
  }

  Widget _content(BuildContext context, List<LiveFortuneTellerEntity> list) {
    return Column(
      children: [
        HomeSectionTitle(
          emoji: '🔮',
          title: 'Canlı Falcılar',
          actionLabel: 'Tümünü Gör >',
          onAction: () => context.push('/canli-falcilar'),
        ),
        SizedBox(
          height: HomeApprovedDesign.tellerCardH,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: HomeApprovedDesign.hPad),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _TellerCard(teller: list[i]),
          ),
        ),
        const SizedBox(height: 8),
        const _QuickActions(),
      ],
    );
  }

  static Widget _emptyState(BuildContext context, {String? message}) {
    return Column(
      children: [
        HomeSectionTitle(
          emoji: '🔮',
          title: 'Canlı Falcılar',
          actionLabel: 'Tümünü Gör >',
          onAction: () => context.push('/canli-falcilar'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: HomeApprovedDesign.hPad,
            vertical: 12,
          ),
          child: Text(
            message ?? 'Şu an çevrimiçi falcı yok.',
            style: TextStyle(
              fontSize: 13,
              color: HomeApprovedDesign.textMuted.withValues(alpha: 0.9),
            ),
          ),
        ),
        const _QuickActions(),
      ],
    );
  }
}

class _TellerCard extends StatelessWidget {
  const _TellerCard({required this.teller});

  final LiveFortuneTellerEntity teller;

  @override
  Widget build(BuildContext context) {
    final specialty = teller.displayCategory.trim();
    return GestureDetector(
      onTap: () => context.push('/canli-falcilar/${teller.id}'),
      child: Container(
        width: HomeApprovedDesign.tellerCardW,
        height: HomeApprovedDesign.tellerCardH,
        padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
        decoration: BoxDecoration(
          color: HomeApprovedDesign.surface,
          borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
          border: Border.all(
            color: teller.isOnline
                ? HomeApprovedDesign.purple.withValues(alpha: 0.45)
                : HomeApprovedDesign.border,
          ),
          boxShadow: teller.isOnline ? const [HomeApprovedDesign.liveGlow] : null,
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: teller.avatarUrl != null && teller.avatarUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: teller.avatarUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        )
                      : ColoredBox(
                          color: HomeApprovedDesign.searchFill,
                          child: SizedBox(
                            width: 56,
                            height: 56,
                            child: Center(
                              child: Text(
                                teller.name.isNotEmpty
                                    ? teller.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: HomeApprovedDesign.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
                if (teller.isOnline)
                  const Positioned(
                    top: -4,
                    right: -4,
                    child: LiveBadge(compact: true, label: 'CANLI'),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    teller.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: HomeApprovedDesign.textPrimary,
                    ),
                  ),
                  if (specialty != null && specialty.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      specialty,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: HomeApprovedDesign.textMuted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    teller.isOnline ? 'Çevrimiçi' : 'Çevrimdışı',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: teller.isOnline
                          ? HomeApprovedDesign.green
                          : HomeApprovedDesign.textMuted,
                    ),
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

class _QuickActions extends ConsumerWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approved = ref.watch(approvedTellerProvider);
    final tellerLabel = approved.isApprovedTeller ? 'Falcı Paneli' : 'Falcı Ol';
    final tellerIcon =
        approved.isApprovedTeller ? Icons.dashboard_outlined : Icons.person_add_rounded;
    void openTeller() {
      if (approved.isApprovedTeller) {
        context.push('/canli-falcilar/dashboard');
      } else {
        context.push('/content-hub');
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: HomeApprovedDesign.hPad),
      child: Row(
        children: [
          Expanded(
            child: _Chip(
              icon: Icons.auto_awesome_rounded,
              label: 'Fal & Tarot',
              onTap: () => context.go('/fortune'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _Chip(
              icon: Icons.mic_rounded,
              label: 'Oda Aç',
              onTap: () => showOpenVoiceChatRoomFlow(context, ref),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _Chip(
              icon: tellerIcon,
              label: tellerLabel,
              onTap: openTeller,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HomeApprovedDesign.surface,
      borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
            border: Border.all(color: HomeApprovedDesign.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: HomeApprovedDesign.purple),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: HomeApprovedDesign.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
