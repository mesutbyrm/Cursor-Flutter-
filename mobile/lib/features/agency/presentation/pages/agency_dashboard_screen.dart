import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';
import 'package:canlifal_social/core/performance/list_perf.dart';

import '../../../../core/economy/presentation/providers/economy_providers.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../domain/entities/agency_entity.dart';
import '../providers/agency_presence_provider.dart';
import '../providers/agency_providers.dart';
import '../../../platform_social/presentation/widgets/platform_social_ui_kit.dart';
import '../widgets/agency_jeton_transfer_sheet.dart';

/// Onaylı ajans kontrol paneli — üyeler, kazançlar, görevler.
class AgencyDashboardScreen extends ConsumerWidget {
  const AgencyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approved = ref.watch(approvedAgencyProvider);
    final dash = ref.watch(agencyDashboardProvider);
    final walletAsync = ref.watch(agencyWalletProvider);
    final presenceAsync = ref.watch(agencyPresenceProvider);
    final agency = dash.agency ?? approved.agency;
    final jetonLabel = economyCurrencyLabel(ref, key: 'jeton');

    if (approved.loading || dash.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (agency == null || !agency.isUsable) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ajans Panel')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              agency == null
                  ? 'Ajans profili bulunamadı. Başvurunuz onaylandıktan sonra panel açılır.'
                  : 'Başvuru durumu: ${agency.applicationStatus ?? "bilinmiyor"}. Onay bekleniyor.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.onSurfaceMuted),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: PlatformSocialPalette.bgTop,
      appBar: AppBar(
        title: const Text('Ajans Panel'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Üye talepleri',
            onPressed: () => context.push('/ajans/talepler'),
            icon: const Icon(Icons.inbox_outlined),
          ),
          IconButton(
            onPressed: () => ref.read(agencyDashboardProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: PlatformSocialBackground(
        child: RefreshIndicator(
        onRefresh: () => ref.read(agencyDashboardProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _AgencyHeader(agency: agency),
            const SizedBox(height: 12),
            PlatformSocialGlassCard(
              onTap: () => context.push('/ajans/talepler'),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: const Row(
                children: [
                  Icon(Icons.inbox_rounded, color: PlatformSocialPalette.accent),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Üye talepleri',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Çıkış ve başvuruları incele',
                          style: TextStyle(
                            fontSize: 11,
                            color: PlatformSocialPalette.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: Colors.white38),
                ],
              ),
            ),
            const SizedBox(height: 16),
            walletAsync.when(
              data: (w) {
                if (w == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PlatformSocialGlassCard(
                  padding: const EdgeInsets.all(14),
                  gradient: LinearGradient(
                    colors: [
                      PlatformSocialPalette.gold.withValues(alpha: 0.12),
                      PlatformSocialPalette.card.withValues(alpha: 0.95),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: PlatformSocialPalette.gold,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Ajans jeton kredisi: ${w.jetonBalance.toStringAsFixed(0)} '
                          '$jetonLabel${w.isLocked ? ' (kilitli)' : ''}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            _StatGrid(
              memberCount: agency.memberCount > 0
                  ? agency.memberCount
                  : dash.members.length,
              totalEarnings: agency.totalEarnings,
              pendingEarnings: agency.pendingEarnings,
              taskCount: dash.tasks.where((t) => !t.completed).length,
              jetonLabel: jetonLabel,
            ),
            if (dash.lastApiLog != null) ...[
              const SizedBox(height: 8),
              Text(
                dash.lastApiLog!,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 11,
                ),
              ),
            ],
            const SizedBox(height: 20),
            const PlatformSocialSectionTitle('Canlı durum'),
            presenceAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return _emptyHint('Canlı durum API yok veya üye yok.');
                }
                return Column(
                  children: items.take(8).map((m) {
                    final label = (m['label'] ?? m['status'] ?? '').toString();
                    final name = (m['name'] ?? m['username'] ?? 'Üye').toString();
                    return PlatformSocialListRow(
                      title: name,
                      trailing: PlatformSocialStatusPill(
                        label: label.isEmpty ? '—' : label,
                        tone: label.toLowerCase().contains('canlı')
                            ? PlatformSocialPillTone.success
                            : PlatformSocialPillTone.neutral,
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(8),
                child: LinearProgressIndicator(),
              ),
              error: (_, __) => _emptyHint('Durum yüklenemedi.'),
            ),
            const SizedBox(height: 16),
            PlatformSocialSectionTitle('Üyeler (${dash.members.length})'),
            if (dash.members.isEmpty)
              _emptyHint('Henüz üye yok.')
            else
              ...dash.members.take(10).map(
                (m) => _MemberTile(
                  m,
                  jetonLabel: jetonLabel,
                  walletBalance: walletAsync.valueOrNull?.jetonBalance ?? 0,
                  onTransfer: () => ref.invalidate(agencyWalletProvider),
                ),
              ),
            const SizedBox(height: 20),
            const PlatformSocialSectionTitle('Son Kazançlar'),
            if (dash.earnings.isEmpty)
              _emptyHint('Kazanç kaydı yok.')
            else
              ...dash.earnings.take(8).map((e) => _EarningTile(e, jetonLabel: jetonLabel)),
            const SizedBox(height: 20),
            const PlatformSocialSectionTitle('Görevler'),
            if (dash.tasks.isEmpty)
              _emptyHint('Aktif görev yok.')
            else
              ...dash.tasks.map((t) => _TaskTile(t, jetonLabel: jetonLabel)),
          ],
        ),
      ),
      ),
    );
  }
}

class _AgencyHeader extends StatelessWidget {
  const _AgencyHeader({required this.agency});

  final AgencyEntity agency;

  @override
  Widget build(BuildContext context) {
    return PlatformSocialGlassCard(
      gradient: PlatformSocialPalette.heroGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFF2196F3),
                backgroundImage:
                    agency.logoUrl != null ? canlifalImageProvider(agency.logoUrl!) : null,
                child: agency.logoUrl == null
                    ? const Icon(Icons.business, color: Colors.white, size: 28)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agency.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (agency.description != null &&
                        agency.description!.trim().isNotEmpty)
                      Text(
                        agency.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (agency.inviteCode != null && agency.inviteCode!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Davet kodu: ${agency.inviteCode}',
                    style: const TextStyle(
                      color: Color(0xFFFFD54F),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: agency.inviteCode!),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Davet kodu kopyalandı')),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, color: Colors.white70),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({
    required this.memberCount,
    required this.totalEarnings,
    required this.pendingEarnings,
    required this.taskCount,
    required this.jetonLabel,
  });

  final int memberCount;
  final int totalEarnings;
  final int pendingEarnings;
  final int taskCount;
  final String jetonLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const crossAxisCount = 2;
        const spacing = 10.0;
        const aspect = 2.2;
        const itemCount = 4;
        final gridHeight = ListPerf.nestedGridHeight(
          itemCount: itemCount,
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: aspect,
          crossAxisExtent: constraints.maxWidth,
        );
        return SizedBox(
          height: gridHeight,
          child: GridView.count(
            crossAxisCount: crossAxisCount,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: aspect,
            children: [
              _statCard('Üye', '$memberCount'),
              _statCard('Toplam Kazanç', '$totalEarnings $jetonLabel'),
              _statCard('Bekleyen', '$pendingEarnings $jetonLabel'),
              _statCard('Açık Görev', '$taskCount'),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(String label, String value) {
    return PlatformSocialStatTile(label: label, value: value);
  }
}

Widget _emptyHint(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(text, style: const TextStyle(color: Colors.white54)),
  );
}

class _MemberTile extends ConsumerWidget {
  const _MemberTile(
    this.member, {
    required this.jetonLabel,
    required this.walletBalance,
    required this.onTransfer,
  });

  final AgencyMemberEntity member;
  final String jetonLabel;
  final double walletBalance;
  final VoidCallback onTransfer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PlatformSocialListRow(
      title: member.name,
      subtitle: '${member.role ?? "Üye"} · ${member.earnings} $jetonLabel',
      leading: CircleAvatar(
        backgroundImage:
            member.avatarUrl != null ? canlifalImageProvider(member.avatarUrl!) : null,
        child: member.avatarUrl == null
            ? Text(member.name.isNotEmpty ? member.name[0] : '?')
            : null,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (walletBalance > 0)
            TextButton(
              onPressed: () => AgencyJetonTransferSheet.show(
                context,
                ref: ref,
                memberUserId: member.id,
                memberLabel: member.name,
                agencyBalance: walletBalance,
                onSuccess: onTransfer,
              ),
              child: const Text('Jeton'),
            ),
          Icon(
            Icons.circle,
            size: 10,
            color: member.isOnline
                ? PlatformSocialPalette.success
                : Colors.grey,
          ),
        ],
      ),
    );
  }
}

class _EarningTile extends StatelessWidget {
  const _EarningTile(this.earning, {required this.jetonLabel});

  final AgencyEarningEntity earning;
  final String jetonLabel;

  @override
  Widget build(BuildContext context) {
    return PlatformSocialListRow(
      title: '+${earning.amount} $jetonLabel',
      subtitle: [
        if (earning.memberName != null) earning.memberName,
        if (earning.source != null) earning.source,
      ].whereType<String>().join(' · '),
      leading: const Icon(
        Icons.trending_up_rounded,
        color: PlatformSocialPalette.success,
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile(this.task, {required this.jetonLabel});

  final AgencyTaskEntity task;
  final String jetonLabel;

  @override
  Widget build(BuildContext context) {
    return PlatformSocialListRow(
      title: task.title,
      subtitle:
          '${task.reward} $jetonLabel${task.description != null ? " · ${task.description}" : ""}',
      leading: Icon(
        task.completed ? Icons.check_circle : Icons.radio_button_unchecked,
        color: task.completed
            ? PlatformSocialPalette.success
            : PlatformSocialPalette.textMuted,
      ),
    );
  }
}
