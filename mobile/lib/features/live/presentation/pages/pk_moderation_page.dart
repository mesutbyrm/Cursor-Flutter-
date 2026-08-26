import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/util/json_util.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../admin/presentation/providers/staff_access_provider.dart';
import '../providers/pk_room_providers.dart';

/// PK Moderasyon (admin/yönetici) — aktif banlar, ban ekle/kaldır.
class PkModerationPage extends ConsumerWidget {
  const PkModerationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(staffAccessProvider);
    if (!access.isSiteAdmin && !access.canManagePayments) {
      return Scaffold(
        backgroundColor: const Color(0xFF0E0524),
        appBar: AppBar(
          backgroundColor: const Color(0xFF12082A),
          title: const Text('PK Moderasyon'),
        ),
        body: const Center(
          child: Text('Bu alan yalnızca admin/yönetici içindir.',
              style: TextStyle(color: Color(0x99FFFFFF))),
        ),
      );
    }

    final bans = ref.watch(pkBansProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF0E0524),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12082A),
        title: const Text('PK Moderasyon'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFF6E6E),
        onPressed: () => _banDialog(context, ref),
        icon: const Icon(Icons.block_rounded),
        label: const Text('Yasakla'),
      ),
      body: bans.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => DiscoverEmptyState(
          icon: Icons.error_outline_rounded,
          message: ApiException.userMessage(e),
          action: () => ref.invalidate(pkBansProvider),
          actionLabel: 'Tekrar dene',
        ),
        data: (rows) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(pkBansProvider),
          child: rows.isEmpty
              ? ListView(children: const [
                  SizedBox(height: 120),
                  Center(
                      child: Text('Aktif yasak yok.',
                          style: TextStyle(color: Color(0x99FFFFFF)))),
                ])
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                  itemCount: rows.length,
                  itemBuilder: (_, i) => _BanRow(ban: rows[i]),
                ),
        ),
      ),
    );
  }

  static Future<void> _banDialog(BuildContext context, WidgetRef ref) async {
    final userId = TextEditingController();
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1030),
        title: const Text('PK Yasağı',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: userId,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Kullanıcı ID',
                labelStyle: TextStyle(color: Color(0x99FFFFFF)),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reason,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Sebep (opsiyonel)',
                labelStyle: TextStyle(color: Color(0x99FFFFFF)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Vazgeç')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Yasakla')),
        ],
      ),
    );
    if (ok == true && userId.text.trim().isNotEmpty) {
      try {
        await ref.read(pkRoomRemoteProvider).banUser(
              userId: userId.text.trim(),
              reason: reason.text.trim().isEmpty ? null : reason.text.trim(),
            );
        ref.invalidate(pkBansProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ApiException.userMessage(e))),
          );
        }
      }
    }
    userId.dispose();
    reason.dispose();
  }
}

class _BanRow extends ConsumerWidget {
  const _BanRow({required this.ban});
  final Map<String, dynamic> ban;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = (pick(ban, ['userId', 'id']) ?? '').toString();
    final name =
        (pick(ban, ['displayName', 'name', 'username']) ?? userId).toString();
    final reason = pick(ban, ['reason'])?.toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1030),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x33FF6E6E)),
      ),
      child: Row(
        children: [
          const Icon(Icons.block_rounded, color: Color(0xFFFF6E6E), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
                if (reason != null && reason.isNotEmpty)
                  Text(reason,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Color(0x99FFFFFF), fontSize: 12)),
              ],
            ),
          ),
          TextButton(
            onPressed: userId.isEmpty
                ? null
                : () async {
                    try {
                      await ref.read(pkRoomRemoteProvider).unban(userId);
                      ref.invalidate(pkBansProvider);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(ApiException.userMessage(e))),
                        );
                      }
                    }
                  },
            child: const Text('Kaldır'),
          ),
        ],
      ),
    );
  }
}
