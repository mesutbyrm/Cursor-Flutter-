import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../voice_hub/presentation/utils/open_voice_chat_room_flow.dart';

import '../../../../../core/ui/premium/live_badge.dart';
import '../../../../../core/ui/premium/premium_skeleton.dart';
import '../../../domain/entities/live_fortune_teller_entity.dart';
import '../../providers/home_providers.dart';
import '../../theme/home_approved_design.dart';
import 'home_section_title.dart';

/// Canlı Falcılar — yuvarlak avatarlar + hızlı aksiyonlar.
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
            height: HomeApprovedDesign.storySize + 28,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: HomeApprovedDesign.hPad),
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => const PremiumSkeleton(
                width: HomeApprovedDesign.storySize,
                height: HomeApprovedDesign.storySize,
                borderRadius: BorderRadius.all(Radius.circular(99)),
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
          height: HomeApprovedDesign.storySize + 28,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: HomeApprovedDesign.hPad),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _TellerOrb(teller: list[i]),
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

class _TellerOrb extends StatelessWidget {
  const _TellerOrb({required this.teller});

  final LiveFortuneTellerEntity teller;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/canli-falcilar/${teller.id}'),
      child: SizedBox(
        width: HomeApprovedDesign.storySize + 4,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                if (teller.isOnline)
                  Positioned(
                    top: -2,
                    child: const LiveBadge(compact: true, label: 'CANLI'),
                  ),
                Container(
                  width: HomeApprovedDesign.storySize + 4,
                  height: HomeApprovedDesign.storySize + 4,
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: teller.isOnline
                        ? HomeApprovedDesign.storyRingGradient
                        : null,
                    border: teller.isOnline
                        ? null
                        : Border.all(color: HomeApprovedDesign.border, width: 2),
                  ),
                  child: ClipOval(
                    child: teller.avatarUrl != null
                        ? CachedNetworkImage(
                            imageUrl: teller.avatarUrl!,
                            fit: BoxFit.cover,
                            width: HomeApprovedDesign.storySize,
                            height: HomeApprovedDesign.storySize,
                          )
                        : ColoredBox(
                            color: HomeApprovedDesign.surface,
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
              ],
            ),
            const SizedBox(height: 6),
            Text(
              teller.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: HomeApprovedDesign.textSecondary,
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
              icon: Icons.person_add_rounded,
              label: 'Falcı Ol',
              onTap: () => context.push('/content-hub'),
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
