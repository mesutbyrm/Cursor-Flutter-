import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/shell_app_bar_widgets.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../shell/presentation/widgets/branch_quick_actions.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/profile_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final coins = ref.watch(coinBalanceProvider);

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 48,
        leading: const ShellFeedLeading(),
        title: const Text('Profil'),
        actions: [
          const ShellNotificationsButton(),
          const ShellCoinBalanceAction(),
          IconButton(
            tooltip: 'Çıkış',
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: auth.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(ApiException.userMessage(e))),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Oturum yok'));
          }
          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(authControllerProvider.notifier).refreshMe();
              ref.invalidate(coinBalanceProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    UserAvatar(url: user.avatarUrl, radius: 40),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.display,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '@${user.username}',
                            style: const TextStyle(color: AppTheme.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const ProfileBranchQuickActions(),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2A1838), Color(0xFF14141C)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.monetization_on_rounded,
                          color: Color(0xFFFFD54F), size: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Coin bakiyesi',
                              style: TextStyle(color: AppTheme.muted),
                            ),
                            coins.when(
                              data: (c) => Text(
                                '$c coin',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              loading: () => const Text('...'),
                              error: (e, _) => Text(
                                ApiException.userMessage(e),
                                style: const TextStyle(color: AppTheme.muted),
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
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => context.push('/jeton-store'),
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  label: const Text('Jeton yükle / satın al'),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _Stat(label: 'Takipçi', value: '${user.followersCount}'),
                    _Stat(label: 'Takip', value: '${user.followingCount}'),
                  ],
                ),
                if (user.bio != null && user.bio!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    user.bio!,
                    style: const TextStyle(
                      color: AppTheme.onBackground,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                FilledButton.tonal(
                  onPressed: () => context.push('/user/${user.id}'),
                  child: const Text('Profilimi herkese aç'),
                ),
              ],
            ),
          );
        },
      ),
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
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        Text(label, style: const TextStyle(color: AppTheme.muted)),
      ],
    );
  }
}
