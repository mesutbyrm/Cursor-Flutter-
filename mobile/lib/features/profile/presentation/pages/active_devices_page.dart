import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../auth/domain/entities/active_session_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';

/// Oturum açık cihazlar — refresh token tabanlı liste.
class ActiveDevicesPage extends ConsumerWidget {
  const ActiveDevicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(activeSessionsProvider);
    final fmt = DateFormat('d MMM yyyy, HH:mm', 'tr');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: 'Aktif Cihazlar',
          subtitle: 'Hesabınıza bağlı oturumlar',
          body: sessions.when(
            loading: () => const Center(child: DiscoverAccentLoader()),
            error: (e, _) => Center(
              child: Text(ApiException.userMessage(e)),
            ),
            data: (rows) {
              if (rows.isEmpty) {
                return Column(
                  children: [
                    const Expanded(
                      child: Center(child: Text('Kayıtlı oturum bulunamadı')),
                    ),
                    _LogoutAllButton(ref: ref),
                  ],
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                itemCount: rows.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  if (index == rows.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _LogoutAllButton(ref: ref),
                    );
                  }
                  final row = rows[index];
                  return _SessionCard(
                    session: row,
                    lastSeenLabel: fmt.format(row.lastSeenAt.toLocal()),
                    onRevoke: () async {
                      try {
                        await ref
                            .read(authRepositoryProvider)
                            .revokeSession(row.id);
                        ref.invalidate(activeSessionsProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Oturum sonlandırıldı')),
                          );
                        }
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(ApiException.userMessage(e))),
                        );
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LogoutAllButton extends StatelessWidget {
  const _LogoutAllButton({required this.ref});

  final WidgetRef ref;

  Future<void> _confirm(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tüm cihazlardan çıkış'),
        content: const Text(
          'Hesabınızdaki tüm oturumlar sonlandırılır. Bu cihazda da çıkış yapılır.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Onayla'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(authRepositoryProvider).logoutAllDevices();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tüm oturumlar sonlandırıldı')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _confirm(context),
      icon: const Icon(Icons.logout_rounded),
      label: const Text('Tüm cihazlardan çıkış'),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.lastSeenLabel,
    required this.onRevoke,
  });

  final ActiveSessionEntity session;
  final String lastSeenLabel;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.colors.surfaceElevated.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              Icons.smartphone_rounded,
              color: context.colors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.deviceLabel,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '${session.devicePlatform} · $lastSeenLabel',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colors.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onRevoke,
              child: const Text('Çıkar'),
            ),
          ],
        ),
      ),
    );
  }
}
