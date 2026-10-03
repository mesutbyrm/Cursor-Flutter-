import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/mock_ui_kit.dart';
import '../providers/account_privacy_providers.dart';

/// Engellenenler — `GET /api/user/block`; engeli kaldırmak aynı uca POST.
class BlockedUsersPage extends ConsumerWidget {
  const BlockedUsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final async = ref.watch(blockedUsersProvider);
    return MockScaffold(
      title: 'Engellenenler',
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ApiException.userMessage(e),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => ref.invalidate(blockedUsersProvider),
                  child: const Text('Tekrar dene'),
                ),
              ],
            ),
          ),
        ),
        data: (rows) {
          if (rows.isEmpty) {
            return Center(
              child: Text(
                'Engellediğin kimse yok.',
                style: TextStyle(color: c.onSurfaceMuted),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(blockedUsersProvider.future),
            child: ListView.separated(
              padding: const EdgeInsetsDirectional.fromSTEB(14, 6, 14, 32),
              itemCount: rows.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _BlockedRow(user: rows[i]),
            ),
          );
        },
      ),
    );
  }
}

class _BlockedRow extends ConsumerStatefulWidget {
  const _BlockedRow({required this.user});

  final BlockedUser user;

  @override
  ConsumerState<_BlockedRow> createState() => _BlockedRowState();
}

class _BlockedRowState extends ConsumerState<_BlockedRow> {
  var _busy = false;

  Future<void> _unblock() async {
    setState(() => _busy = true);
    try {
      await unblockUser(ref, widget.user.userId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final u = widget.user;
    final image = u.image;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: mockCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: mockCardBorder(context)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: c.primary.withValues(alpha: 0.25),
            backgroundImage:
                (image != null && image.isNotEmpty) ? NetworkImage(image) : null,
            child: (image != null && image.isNotEmpty)
                ? null
                : Icon(Icons.person_rounded, color: c.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  u.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: c.onSurface,
                  ),
                ),
                if (u.username != null)
                  Text(
                    '@${u.username}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: c.onSurfaceMuted),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: _busy ? null : _unblock,
            child: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Engeli kaldır'),
          ),
        ],
      ),
    );
  }
}
