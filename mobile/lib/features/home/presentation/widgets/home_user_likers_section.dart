import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/home_user_liker_entity.dart';
import '../providers/home_providers.dart';
import '../theme/home_approved_design.dart';
import 'approved/home_section_title.dart';

/// Profil beğenenler — `GET /api/user/likers`.
class HomeUserLikersSection extends ConsumerWidget {
  const HomeUserLikersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    if (user == null) return const SizedBox.shrink();

    final likers = ref.watch(homeUserLikersProvider);
    return likers.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            HomeSectionTitle(
              emoji: '❤️',
              title: 'Seni Beğenenler',
              actionLabel: 'Profil >',
              onAction: () => context.push('/profile'),
            ),
            SizedBox(
              height: 108,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: HomeApprovedDesign.hPad,
                ),
                itemCount: items.length.clamp(0, 10),
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _LikerChip(liker: items[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LikerChip extends StatelessWidget {
  const _LikerChip({required this.liker});

  final HomeUserLikerEntity liker;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  HomeApprovedDesign.pink.withValues(alpha: 0.9),
                  HomeApprovedDesign.liveRed.withValues(alpha: 0.85),
                ],
              ),
            ),
            child: UserAvatar(url: liker.avatarUrl, radius: 26),
          ),
          const SizedBox(height: 6),
          Text(
            liker.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: HomeApprovedDesign.textPrimary,
            ),
          ),
          if (liker.timeLabel?.trim().isNotEmpty == true)
            Text(
              liker.timeLabel!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9,
                color: HomeApprovedDesign.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}
