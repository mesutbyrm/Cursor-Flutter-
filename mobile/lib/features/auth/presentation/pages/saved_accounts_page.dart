import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/saved_accounts_store.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/mock_ui_kit.dart';
import '../providers/auth_providers.dart';

/// Kayıtlı hesaplar (en fazla 10) — oturumlar arası geçiş.
class SavedAccountsPage extends ConsumerWidget {
  const SavedAccountsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(savedAccountsListProvider);
    final activeId = ref.watch(authControllerProvider).valueOrNull?.id;

    return MockScaffold(
      title: 'Kayıtlı hesaplar',
      body: accounts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(ApiException.userMessage(e))),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Henüz kayıtlı hesap yok. Giriş yaptığınız hesaplar burada '
                  'listelenir (en fazla $maxSavedAccounts).',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              if (i == list.length) {
                return OutlinedButton.icon(
                  onPressed: () => context.push('/auth/login'),
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Başka hesap ekle'),
                );
              }
              final entry = list[i];
              final active = entry.userId == activeId;
              return MockListRow(
                icon: Icons.account_circle_rounded,
                color: active ? Colors.green : Colors.blueGrey,
                title: entry.label,
                subtitle: active ? 'Aktif oturum' : entry.userId,
                value: active ? '✓' : null,
                onTap: active
                    ? null
                    : () async {
                        try {
                          await ref
                              .read(authControllerProvider.notifier)
                              .switchToSavedAccount(entry.userId);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${entry.label} hesabına geçildi')),
                            );
                            context.go('/feed');
                          }
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(ApiException.userMessage(e))),
                          );
                        }
                      },
                trailing: active
                    ? null
                    : IconButton(
                        tooltip: 'Kaldır',
                        icon: const Icon(Icons.delete_outline_rounded),
                        onPressed: () async {
                          await ref
                              .read(savedAccountsStoreProvider)
                              .remove(entry.userId);
                          ref.invalidate(savedAccountsListProvider);
                        },
                      ),
              );
            },
          );
        },
      ),
    );
  }
}
