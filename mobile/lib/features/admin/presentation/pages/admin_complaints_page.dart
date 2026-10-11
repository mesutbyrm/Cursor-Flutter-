import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../domain/admin_complaint.dart';
import '../providers/admin_complaints_providers.dart';
import '../providers/admin_panel_providers.dart';
import '../providers/staff_access_provider.dart';

/// `GET/PATCH /api/admin/complaints` — PR #40.
class AdminComplaintsPage extends ConsumerStatefulWidget {
  const AdminComplaintsPage({super.key});

  @override
  ConsumerState<AdminComplaintsPage> createState() => _AdminComplaintsPageState();
}

class _AdminComplaintsPageState extends ConsumerState<AdminComplaintsPage> {
  String _status = 'pending';

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(staffAccessProvider);
    if (!access.canViewReports && !access.canModerate) {
      return _locked(context);
    }

    final async = ref.watch(adminComplaintsProvider(_status));
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                    onPressed: () => context.pop(),
                  ),
                  const Expanded(
                    child: DiscoverTabHeader(
                      title: 'Şikâyetler',
                      subtitle: 'Moderasyon — bekleyen raporlar',
                    ),
                  ),
                  DiscoverIconButton(
                    icon: Icons.refresh_rounded,
                    onPressed: () =>
                        ref.invalidate(adminComplaintsProvider(_status)),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  for (final s in const [
                    'pending',
                    'reviewing',
                    'resolved',
                    'dismissed',
                    'all',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(_statusLabel(s)),
                        selected: _status == s,
                        onSelected: (_) => setState(() => _status = s),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: async.when(
                data: (page) {
                  if (page.reports.isEmpty) {
                    return const Center(
                      child: DiscoverEmptyState(
                        icon: Icons.inbox_outlined,
                        message: 'Bu filtrede şikâyet yok.',
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    itemCount: page.reports.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) =>
                        _ComplaintTile(report: page.reports[i], onAction: _act),
                  );
                },
                loading: () =>
                    const Center(child: DiscoverAccentLoader()),
                error: (e, _) => Center(
                  child: DiscoverEmptyState(
                    icon: Icons.error_outline_rounded,
                    message: ApiException.userMessage(e),
                    actionLabel: 'Yenile',
                    action: () =>
                        ref.invalidate(adminComplaintsProvider(_status)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _locked(BuildContext context) {
    return Scaffold(
      body: DiscoverBackground(
        child: Center(
          child: DiscoverEmptyState(
            icon: Icons.lock_outline_rounded,
            message: 'Şikâyet yönetimi için yetkiniz yok.',
            actionLabel: 'Geri',
            action: () => Navigator.of(context).maybePop(),
          ),
        ),
      ),
    );
  }

  String _statusLabel(String s) => switch (s) {
        'pending' => 'Bekleyen',
        'reviewing' => 'İncelemede',
        'resolved' => 'Çözüldü',
        'dismissed' => 'Reddedildi',
        'all' => 'Tümü',
        _ => s,
      };

  Future<void> _act(AdminComplaint r, String action) async {
    try {
      await ref.read(adminRemoteProvider).patchComplaint(
            reportId: r.id,
            action: action,
            reason: 'Mobil admin',
          );
      ref.invalidate(adminComplaintsProvider(_status));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Şikâyet güncellendi ($action).')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    }
  }
}

class _ComplaintTile extends StatelessWidget {
  const _ComplaintTile({required this.report, required this.onAction});

  final AdminComplaint report;
  final void Function(AdminComplaint, String action) onAction;

  @override
  Widget build(BuildContext context) {
    final reported = report.reported?.username ?? report.reported?.name ?? '—';
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              report.reason,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              'Hedef: @$reported · ${report.status}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            if (report.details.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(report.details, style: const TextStyle(fontSize: 13, height: 1.35)),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                if (report.status == 'pending')
                  TextButton(
                    onPressed: () => onAction(report, 'review'),
                    child: const Text('İncele'),
                  ),
                if (report.status == 'pending' || report.status == 'reviewing')
                  TextButton(
                    onPressed: () => onAction(report, 'resolve'),
                    child: const Text('Çöz'),
                  ),
                if (report.status == 'pending' || report.status == 'reviewing')
                  TextButton(
                    onPressed: () => onAction(report, 'dismiss'),
                    child: const Text('Reddet'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
