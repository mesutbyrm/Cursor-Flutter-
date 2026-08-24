import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glow_panel.dart';
import '../providers/referral_providers.dart';

/// Referanslarım — backend listesi.
class ReferralUsersPage extends ConsumerWidget {
  const ReferralUsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(referralUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Referanslarım'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go('/invite-friends'),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(referralUsersProvider);
          await ref.read(referralUsersProvider.future);
        },
        child: users.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(ApiException.userMessage(e))),
          data: (list) {
            if (list.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('Henüz referansın yok')),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final u = list[i];
                final name = u.displayName ?? u.username ?? u.userId;
                return GlowPanel(
                  borderRadius: 16,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Katılım: ${u.joinedAt.split('T').first}',
                        style: TextStyle(
                          color: AppTheme.muted.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Durum: ${u.status}',
                        style: TextStyle(
                          color: AppTheme.muted.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Uygun hacim: ${u.eligibleJetonVolume} Jeton',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Oluşan kazanç: ${u.referralEarnings} Jeton',
                        style: TextStyle(
                          color: AppTheme.accent.withValues(alpha: 0.95),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
