import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/util/json_util.dart';
import '../pages/admin_panel_page.dart';
import '../providers/admin_panel_providers.dart';

class AdminStatsListSheet {
  AdminStatsListSheet._();

  static Future<void> show(
    BuildContext context, {
    required WidgetRef ref,
    required AdminStatsKind kind,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AdminStatsListBody(ref: ref, kind: kind),
    );
  }
}

class _AdminStatsListBody extends ConsumerWidget {
  const _AdminStatsListBody({required this.ref, required this.kind});

  final WidgetRef ref;
  final AdminStatsKind kind;

  String get _title => switch (kind) {
        AdminStatsKind.todayMembers => 'Bugün üye olanlar',
        AdminStatsKind.todayJetonBuyers => 'Bugün jeton alanlar',
        AdminStatsKind.roomOpeners => 'Oda açanlar / sohbete katılanlar',
        AdminStatsKind.broadcasters => 'Yayın yapanlar',
        AdminStatsKind.topEarners => 'En çok kazanan',
        AdminStatsKind.topGiftSenders => 'En çok hediye atanlar',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _load(ref),
      builder: (context, snap) {
        final rows = snap.data ?? const [];
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: context.colors.onSurface,
                    ),
                  ),
                ),
                if (snap.connectionState == ConnectionState.waiting)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (snap.hasError)
                  Expanded(
                    child: Center(
                      child: Text(
                        ApiException.userMessage(snap.error ?? 'Hata'),
                      ),
                    ),
                  )
                else if (rows.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        'Kayıt bulunamadı.',
                        style: TextStyle(color: context.colors.onSurfaceMuted),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: rows.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final r = rows[i];
                        final name = r['userName'] ??
                            r['name'] ??
                            r['username'] ??
                            r['displayName'] ??
                            '—';
                        final detail = r['detail'] ??
                            r['count']?.toString() ??
                            r['amount']?.toString() ??
                            '';
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppThemeColors.accentPurple
                                .withValues(alpha: 0.3),
                            child: Text('${i + 1}'),
                          ),
                          title: Text(
                            name.toString(),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: detail.toString().isNotEmpty
                              ? Text(detail.toString())
                              : null,
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _load(WidgetRef ref) async {
    final remote = ref.read(adminRemoteProvider);
    const timeout = Duration(seconds: 8);
    final today = DateTime.now();

    bool isToday(String? iso) {
      if (iso == null || iso.isEmpty) return false;
      final dt = DateTime.tryParse(iso);
      if (dt == null) return false;
      final local = dt.toLocal();
      return local.year == today.year &&
          local.month == today.month &&
          local.day == today.day;
    }

    switch (kind) {
      case AdminStatsKind.topEarners:
      case AdminStatsKind.topGiftSenders:
        final boards = await remote.fetchLeaderboards(period: 'today').timeout(
          timeout,
          onTimeout: () => throw ApiException('timeout', statusCode: 408),
        );
        final key = kind == AdminStatsKind.topEarners
            ? 'topEarners'
            : 'topGiftSenders';
        final list = boards[key];
        if (list is List) {
          return list.map((e) => asJsonMap(e)).toList();
        }
        return const [];

      case AdminStatsKind.todayMembers:
      case AdminStatsKind.todayJetonBuyers:
      case AdminStatsKind.roomOpeners:
      case AdminStatsKind.broadcasters:
        final activities = await remote.fetchActivities(limit: 80).timeout(
          timeout,
          onTimeout: () => throw ApiException('timeout', statusCode: 408),
        );
        return activities.where((a) {
          if (!isToday(a['createdAt']?.toString())) return false;
          final type = (a['activityType'] ?? '').toString();
          return switch (kind) {
            AdminStatsKind.todayMembers =>
              type == 'signup' || type == 'register',
            AdminStatsKind.todayJetonBuyers =>
              type.contains('jeton') || type.contains('payment'),
            AdminStatsKind.roomOpeners =>
              type.contains('room') || type == 'chat_join',
            AdminStatsKind.broadcasters =>
              type == 'stream_started' || type.contains('broadcast'),
            AdminStatsKind.topEarners || AdminStatsKind.topGiftSenders => false,
          };
        }).toList();
    }
  }
}
