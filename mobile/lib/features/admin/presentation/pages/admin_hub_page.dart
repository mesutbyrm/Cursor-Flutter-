import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../providers/admin_providers.dart';
import '../providers/staff_access_provider.dart';

/// Admin / yönetici — site ödeme istekleri ve bildirimler.
class AdminHubPage extends ConsumerStatefulWidget {
  const AdminHubPage({super.key});

  @override
  ConsumerState<AdminHubPage> createState() => _AdminHubPageState();
}

class _AdminHubPageState extends ConsumerState<AdminHubPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _poll = Timer.periodic(const Duration(seconds: 25), (_) {
      if (!mounted) return;
      ref.invalidate(adminPaymentRequestsProvider);
      ref.invalidate(adminPaymentNotificationsProvider);
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _tabs.dispose();
    super.dispose();
  }

  void _refreshAll() {
      ref.invalidate(adminPaymentRequestsProvider);
      ref.invalidate(adminPaymentNotificationsProvider);
      ref.invalidate(adminSitePaymentSettingsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(staffAccessProvider);
    if (!access.canManagePayments) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: DiscoverBackground(
          child: Center(
            child: DiscoverEmptyState(
              icon: Icons.lock_outline_rounded,
              message:
                  'Bu alan yalnızca admin veya yönetici hesapları içindir.',
              actionLabel: 'Geri',
              action: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
      );
    }

    final pending = ref.watch(adminPaymentRequestsProvider);
    final notifs = ref.watch(adminPaymentNotificationsProvider);
    final siteSettings = ref.watch(adminSitePaymentSettingsProvider);
    final pendingCount = ref.watch(adminPendingPaymentsCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DiscoverBackground(
        child: Column(
          children: [
            SizedBox(height: MediaQuery.paddingOf(context).top + 4),
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 12),
              child: Row(
                children: [
                  DiscoverIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Expanded(
                    child: DiscoverTabHeader(
                      title: 'Ödeme istekleri',
                      subtitle: 'canlifal.com · jeton ve CFC talepleri',
                    ),
                  ),
                  DiscoverIconButton(
                    icon: Icons.refresh_rounded,
                    onPressed: _refreshAll,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: TabBar(
                controller: _tabs,
                indicatorColor: AppColors.accentPink,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textMuted,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Bekleyen'),
                        if (pendingCount > 0) ...[
                          const SizedBox(width: 6),
                          _CountChip(count: pendingCount),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Bildirimler'),
                        notifs.maybeWhen(
                          data: (rows) {
                            final unread =
                                rows.where((n) => n['read'] != true).length;
                            if (unread <= 0) return const SizedBox.shrink();
                            return Row(
                              children: [
                                const SizedBox(width: 6),
                                _CountChip(count: unread),
                              ],
                            );
                          },
                          orElse: () => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            siteSettings.when(
              data: (cfg) {
                if (cfg.values.every((v) => v == '—' || v.isEmpty)) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: DiscoverGlassCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Site ödeme bilgileri',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        for (final e in cfg.entries)
                          if (e.value != '—')
                            Text(
                              '${e.key}: ${e.value}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _PendingPaymentsTab(
                    async: pending,
                    onReview: _review,
                    onRefresh: _refreshAll,
                  ),
                  _PaymentNotificationsTab(
                    async: notifs,
                    onRefresh: _refreshAll,
                    onOpenPending: () => _tabs.animateTo(0),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _review(
    BuildContext context,
    String requestId,
    String action,
  ) async {
    try {
      await ref.read(dioProvider).safePatch<dynamic>(
        ApiEndpoints.adminCfcPaymentPatch,
        data: {
          'requestId': requestId,
          'action': action,
          if (action == 'approve') 'reviewNote': 'Onaylandı',
        },
      );
      _refreshAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              action == 'approve' ? 'Talep onaylandı' : 'Talep reddedildi',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    }
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.liveRed,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _PendingPaymentsTab extends StatelessWidget {
  const _PendingPaymentsTab({
    required this.async,
    required this.onReview,
    required this.onRefresh,
  });

  final AsyncValue<List<Map<String, dynamic>>> async;
  final void Function(BuildContext, String, String) onReview;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.accentPink,
      onRefresh: () async => onRefresh(),
      child: async.when(
        loading: () => ListView(
          children: const [
            SizedBox(height: 120),
            Center(child: DiscoverAccentLoader()),
          ],
        ),
        error: (e, _) => ListView(
          children: [
            const SizedBox(height: 80),
            DiscoverEmptyState(
              icon: Icons.shield_outlined,
              message: ApiException.userMessage(e),
              actionLabel: 'Yenile',
              action: onRefresh,
            ),
          ],
        ),
        data: (rows) {
          if (rows.isEmpty) {
            return ListView(
              children: [
                const SizedBox(height: 80),
                const DiscoverEmptyState(
                  icon: Icons.inbox_outlined,
                  message:
                      'Bekleyen ödeme talebi yok.\nYeni talepler burada ve Bildirimler sekmesinde görünür.',
                ),
              ],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemCount: rows.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final r = rows[i];
              final id = r['id']?.toString() ?? '';
              final user = r['user'] is Map
                  ? Map<String, dynamic>.from(r['user'] as Map)
                  : null;
              final name = user?['name']?.toString() ??
                  user?['displayName']?.toString() ??
                  r['senderInfo']?.toString() ??
                  'Kullanıcı';
              final isJeton = (r['requestType'] ?? '').toString() == 'jeton';

              return DiscoverGlassCard(
                padding: const EdgeInsets.all(14),
                borderColor: AppColors.accentPink.withValues(alpha: 0.3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isJeton
                              ? Icons.monetization_on_rounded
                              : Icons.account_balance_wallet_outlined,
                          size: 20,
                          color: AppColors.accentCyan,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.liveRed.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Bekliyor',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.liveRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      paymentRequestSummary(r),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    if (r['notes'] != null && r['notes'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          r['notes'].toString(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: id.isEmpty
                                ? null
                                : () => onReview(context, id, 'reject'),
                            child: const Text('Reddet'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: id.isEmpty
                                ? null
                                : () => onReview(context, id, 'approve'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.accentCyan,
                            ),
                            child: const Text('Onayla'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PaymentNotificationsTab extends StatelessWidget {
  const _PaymentNotificationsTab({
    required this.async,
    required this.onRefresh,
    required this.onOpenPending,
  });

  final AsyncValue<List<Map<String, dynamic>>> async;
  final VoidCallback onRefresh;
  final VoidCallback onOpenPending;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd.MM HH:mm');

    return RefreshIndicator(
      color: AppColors.accentPink,
      onRefresh: () async => onRefresh(),
      child: async.when(
        loading: () => ListView(
          children: const [
            SizedBox(height: 120),
            Center(child: DiscoverAccentLoader()),
          ],
        ),
        error: (e, _) => ListView(
          children: [
            const SizedBox(height: 80),
            DiscoverEmptyState(
              icon: Icons.notifications_off_outlined,
              message: ApiException.userMessage(e),
              actionLabel: 'Yenile',
              action: onRefresh,
            ),
          ],
        ),
        data: (rows) {
          if (rows.isEmpty) {
            return ListView(
              children: [
                const SizedBox(height: 80),
                DiscoverEmptyState(
                  icon: Icons.notifications_none_rounded,
                  message:
                      'Henüz ödeme bildirimi yok.\nKullanıcı talep gönderince burada görünür.',
                  actionLabel: 'Bekleyen talepler',
                  action: onOpenPending,
                ),
              ],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemCount: rows.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final n = rows[i];
              final read = n['read'] == true;
              final created = DateTime.tryParse(
                n['createdAt']?.toString() ?? '',
              );
              final isRequest = isPaymentNotificationType(n['type']?.toString()) &&
                  (n['type']?.toString() ?? '').contains('request');

              return DiscoverGlassCard(
                onTap: isRequest ? onOpenPending : null,
                borderColor: read
                    ? null
                    : AppColors.accentPink.withValues(alpha: 0.4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.payments_rounded,
                      color: read ? AppColors.textMuted : AppColors.accentCyan,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            n['title']?.toString() ?? 'Ödeme bildirimi',
                            style: TextStyle(
                              fontWeight:
                                  read ? FontWeight.w600 : FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            paymentNotificationSummary(n),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (created != null)
                      Text(
                        fmt.format(created.toLocal()),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
