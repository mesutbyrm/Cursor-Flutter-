import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_design.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/profile_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final coins = ref.watch(coinBalanceProvider);

    Future<void> refresh() async {
      await ref.read(authControllerProvider.notifier).refreshMe();
      ref.invalidate(coinBalanceProvider);
    }

    return DiscoverTabScrollPage(
      title: 'Profil',
      subtitle: 'Hesabın, coinlerin ve istatistiklerin',
      onRefresh: refresh,
      actions: [
        DiscoverIconButton(
          icon: Icons.notifications_none_rounded,
          tooltip: 'Bildirimler',
          onPressed: () => context.push('/notifications'),
        ),
        DiscoverIconButton(
          icon: Icons.logout_rounded,
          tooltip: 'Çıkış',
          onPressed: () =>
              ref.read(authControllerProvider.notifier).logout(),
        ),
      ],
      slivers: [
        auth.when(
          loading: () => const SliverFillRemaining(
            child: DiscoverAccentLoader(),
          ),
          error: (e, _) => SliverFillRemaining(
            child: DiscoverEmptyState(
              icon: Icons.error_outline_rounded,
              message: ApiException.userMessage(e),
            ),
          ),
          data: (user) {
            if (user == null) {
              return const SliverFillRemaining(
                child: DiscoverEmptyState(
                  icon: Icons.person_off_outlined,
                  message: 'Oturum bulunamadı',
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  DiscoverGlassCard(
                    borderColor:
                        AppDesign.accentPurple.withValues(alpha: 0.4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppDesign.heroGradient,
                          ),
                          child: UserAvatar(url: user.avatarUrl, radius: 36),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.display,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                '@${user.username}',
                                style: const TextStyle(
                                  color: AppDesign.textMuted,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  DiscoverGlassCard(
                    borderColor:
                        AppDesign.accentCyan.withValues(alpha: 0.35),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: AppDesign.coinCapsuleGradient,
                          ),
                          child: const Icon(
                            Icons.monetization_on_rounded,
                            color: Color(0xFFFFD54F),
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Coin bakiyesi',
                                style: TextStyle(
                                  color: AppDesign.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                              coins.when(
                                data: (c) => Text(
                                  '$c coin',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                loading: () => const Text('...'),
                                error: (e, _) => Text(
                                  ApiException.userMessage(e),
                                  style: const TextStyle(
                                    color: AppDesign.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => ref.invalidate(coinBalanceProvider),
                          child: const Text('Yenile'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  DiscoverGlassCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _Stat(
                          label: 'Takipçi',
                          value: '${user.followersCount}',
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                        _Stat(
                          label: 'Takip',
                          value: '${user.followingCount}',
                        ),
                      ],
                    ),
                  ),
                  if (user.bio != null && user.bio!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    DiscoverGlassCard(
                      child: Text(
                        user.bio!,
                        style: const TextStyle(
                          color: AppDesign.textSecondary,
                          height: 1.45,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => context.push('/user/${user.id}'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      backgroundColor: AppDesign.accentPink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Profilimi herkese aç',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ]),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppDesign.textMuted,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
