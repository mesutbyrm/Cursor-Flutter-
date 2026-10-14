import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/saved_accounts_store.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../providers/auth_providers.dart';

/// Profil başlığındaki `@kullanıcı_adı ▾` — dokununca hesap değiştirici açılır.
class AccountSwitcherUsername extends StatelessWidget {
  const AccountSwitcherUsername({
    super.key,
    required this.username,
    required this.style,
  });

  final String username;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Hesap değiştir',
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => showAccountSwitcherSheet(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  '@$username',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: (style.fontSize ?? 16) + 6,
                color: style.color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showAccountSwitcherSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const _AccountSwitcherSheet(),
  );
}

class _AccountSwitcherSheet extends ConsumerWidget {
  const _AccountSwitcherSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(savedAccountsListProvider);
    final active = ref.watch(authControllerProvider).valueOrNull;
    final busy = ref.watch(authUserActionBusyProvider);

    final list = accounts.valueOrNull ?? const <SavedAccountEntry>[];
    // Aktif hesap henüz listeye yazılmadıysa (ör. eski sürümden gelen oturum)
    // yine de en üstte gösterilir ve sayılır.
    final activeSaved = active != null && list.any((e) => e.userId == active.id);
    final total = list.length + (active != null && !activeSaved ? 1 : 0);
    final canAdd = total < maxSavedAccounts;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Text(
                'Hesaplar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
            if (busy) const LinearProgressIndicator(minHeight: 2),
            if (active != null && !activeSaved)
              _AccountTile(
                label: active.display.trim().isNotEmpty
                    ? active.display.trim()
                    : active.username,
                username: active.username,
                avatarUrl: active.avatarUrl,
                active: true,
              ),
            for (final entry in list)
              _AccountTile(
                label: entry.label,
                username: entry.username,
                avatarUrl: entry.avatarUrl,
                active: entry.userId == active?.id,
                onTap: busy || entry.userId == active?.id
                    ? null
                    : () => _switchTo(context, ref, entry),
              ),
            const Divider(height: 16),
            ListTile(
              enabled: canAdd && !busy,
              leading: const CircleAvatar(
                child: Icon(Icons.person_add_alt_1_rounded),
              ),
              title: const Text('Hesap ekle'),
              subtitle: Text(
                canAdd
                    ? 'Mevcut hesabınız açık kalır'
                    : 'En fazla $maxSavedAccounts hesap eklenebilir',
              ),
              onTap: () => _closeAndPush(context, '/auth/add-account'),
            ),
            ListTile(
              leading: const Icon(Icons.manage_accounts_rounded),
              title: const Text('Hesapları yönet'),
              onTap: () => _closeAndPush(context, '/settings/accounts'),
            ),
          ],
        ),
      ),
    );
  }

  /// Sheet kapanınca kendi context'i geçersizleşir; router önceden alınır.
  void _closeAndPush(BuildContext context, String location) {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.push(location);
  }

  Future<void> _switchTo(
    BuildContext context,
    WidgetRef ref,
    SavedAccountEntry entry,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .switchToSavedAccount(entry.userId);
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text('${entry.label} hesabına geçildi')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    }
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.label,
    required this.active,
    this.username,
    this.avatarUrl,
    this.onTap,
  });

  final String label;
  final String? username;
  final String? avatarUrl;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: UserAvatar(url: avatarUrl, radius: 20),
      title: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: username == null || username!.isEmpty
          ? null
          : Text('@$username', maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: active
          ? Icon(
              Icons.check_circle_rounded,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
    );
  }
}
