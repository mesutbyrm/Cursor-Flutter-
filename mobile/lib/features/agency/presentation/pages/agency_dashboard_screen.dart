import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';
import 'package:canlifal_social/core/performance/list_perf.dart';

import '../../../../core/economy/presentation/providers/economy_providers.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../domain/entities/agency_entity.dart';
import '../providers/agency_presence_provider.dart';
import '../providers/agency_providers.dart';
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
      backgroundColor: const Color(0xFF0A1020),
      appBar: AppBar(
        title: const Text('Ajans Panel'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () => ref.read(agencyDashboardProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(agencyDashboardProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _AgencyHeader(agency: agency),
            const SizedBox(height: 16),
            walletAsync.when(
              data: (w) {
                if (w == null) return const SizedBox.shrink();
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    'Ajans jeton kredisi: ${w.jetonBalance.toStringAsFixed(0)} '
                    '$jetonLabel${w.isLocked ? ' (kilitli)' : ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
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
            _SectionTitle('Canlı durum'),
            presenceAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return _emptyHint('Canlı durum API yok veya üye yok.');
                }
                return Column(
                  children: items.take(8).map((m) {
                    final label = (m['label'] ?? m['status'] ?? '').toString();
                    final name = (m['name'] ?? m['username'] ?? 'Üye').toString();
                    return ListTile(
                      dense: true,
                      title: Text(name, style: const TextStyle(color: Colors.white)),
                      trailing: Text(label, style: const TextStyle(fontSize: 11)),
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
            _SectionTitle('Üyeler (${dash.members.length})'),
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
            _SectionTitle('Son Kazançlar'),
            if (dash.earnings.isEmpty)
              _emptyHint('Kazanç kaydı yok.')
            else
              ...dash.earnings.take(8).map((e) => _EarningTile(e, jetonLabel: jetonLabel)),
            const SizedBox(height: 20),
            _SectionTitle('Görevler'),
            if (dash.tasks.isEmpty)
              _emptyHint('Aktif görev yok.')
            else
              ...dash.tasks.map((t) => _TaskTile(t, jetonLabel: jetonLabel)),
          ],
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2A50), Color(0xFF0A1428)],
        ),
        border: Border.all(color: Colors.white24),
      ),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
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
    return Card(
      color: const Color(0xFF141E35),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage:
              member.avatarUrl != null ? canlifalImageProvider(member.avatarUrl!) : null,
          child: member.avatarUrl == null
              ? Text(member.name.isNotEmpty ? member.name[0] : '?')
              : null,
        ),
        title: Text(member.name, style: const TextStyle(color: Colors.white)),
        subtitle: Text(
          '${member.role ?? "Üye"} · ${member.earnings} $jetonLabel',
          style: const TextStyle(color: Colors.white60),
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
              color: member.isOnline ? Colors.greenAccent : Colors.grey,
            ),
          ],
        ),
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
    return Card(
      color: const Color(0xFF141E35),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          '+${earning.amount} $jetonLabel',
          style: const TextStyle(
            color: Color(0xFF00E676),
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          [
            if (earning.memberName != null) earning.memberName,
            if (earning.source != null) earning.source,
          ].whereType<String>().join(' · '),
          style: const TextStyle(color: Colors.white60),
        ),
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
    return Card(
      color: const Color(0xFF141E35),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          task.completed ? Icons.check_circle : Icons.radio_button_unchecked,
          color: task.completed ? Colors.greenAccent : Colors.white54,
        ),
        title: Text(task.title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(
          '${task.reward} $jetonLabel${task.description != null ? " · ${task.description}" : ""}',
          style: const TextStyle(color: Colors.white60),
        ),
      ),
    );
  }
}
