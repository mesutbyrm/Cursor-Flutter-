import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../domain/entities/live_fortune_request_entity.dart';
import '../../gifts/providers/live_gift_providers.dart';
import '../../providers/co_broadcast_provider.dart';
import '../../providers/live_fortune_request_provider.dart';
import '../../providers/live_host_dashboard_provider.dart';
import '../../providers/live_video_pk_provider.dart';
import 'live_host_dashboard_chart.dart';

/// Sağdan açılan yayıncı kontrol merkezi — 6 sekme.
Future<void> openLiveHostControlCenter({
  required BuildContext context,
  required WidgetRef ref,
  required String streamId,
  required bool isHost,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Kontrol merkezi',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (ctx, anim1, anim2) {
      return Align(
        alignment: Alignment.centerRight,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: _LiveHostControlCenter(
            streamId: streamId,
            isHost: isHost,
          ),
        ),
      );
    },
  );
}

class _LiveHostControlCenter extends ConsumerStatefulWidget {
  const _LiveHostControlCenter({
    required this.streamId,
    required this.isHost,
  });

  final String streamId;
  final bool isHost;

  @override
  ConsumerState<_LiveHostControlCenter> createState() =>
      _LiveHostControlCenterState();
}

class _LiveHostControlCenterState extends ConsumerState<_LiveHostControlCenter>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width * 0.88;
    final height = MediaQuery.sizeOf(context).height;

    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            width: width.clamp(300, 420),
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1A1030).withValues(alpha: 0.94),
                  const Color(0xFF0D0D18).withValues(alpha: 0.98),
                ],
              ),
              border: Border(
                left: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                    child: Row(
                      children: [
                        const Text(
                          'Kontrol Merkezi',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  TabBar(
                    controller: _tabs,
                    isScrollable: true,
                    indicatorColor: const Color(0xFFB832FF),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white54,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
                    tabs: const [
                      Tab(text: 'Fal'),
                      Tab(text: 'Hediye'),
                      Tab(text: 'PK'),
                      Tab(text: 'Konuk'),
                      Tab(text: 'Mod'),
                      Tab(text: 'İstatistik'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabs,
                      children: [
                        _FortuneTab(streamId: widget.streamId),
                        _GiftsTab(streamId: widget.streamId),
                        _PkTab(streamId: widget.streamId),
                        _GuestsTab(streamId: widget.streamId),
                        _ModerationTab(streamId: widget.streamId),
                        _StatsTab(streamId: widget.streamId),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}

class _FortuneTab extends ConsumerWidget {
  const _FortuneTab({required this.streamId});
  final String streamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(liveFortuneRequestsProvider(streamId));
    final grouped = _groupByPriority(state.requests);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final entry in grouped.entries) ...[
          _sectionTitle(entry.key),
          ...entry.value.map(
            (r) => _FortuneSwipeCard(
              request: r,
              onAccept: () => _setStatus(ref, r.id, LiveFortuneRequestStatus.reviewing),
              onComplete: () => _setStatus(ref, r.id, LiveFortuneRequestStatus.answered),
              onCancel: () => _setStatus(ref, r.id, LiveFortuneRequestStatus.cancelled),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (state.requests.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Fal isteği yok', style: TextStyle(color: Colors.white54)),
            ),
          ),
      ],
    );
  }

  Map<String, List<LiveFortuneRequestEntity>> _groupByPriority(
    List<LiveFortuneRequestEntity> items,
  ) {
    final vip = <LiveFortuneRequestEntity>[];
    final priority = <LiveFortuneRequestEntity>[];
    final standard = <LiveFortuneRequestEntity>[];
    for (final r in sortFortuneRequestQueue(items)) {
      switch (r.priority) {
        case LiveFortunePriority.vip:
        case LiveFortunePriority.superFal:
        case LiveFortunePriority.urgent:
          vip.add(r);
        case LiveFortunePriority.priority:
          priority.add(r);
        case LiveFortunePriority.standard:
          standard.add(r);
      }
    }
    return {
      if (vip.isNotEmpty) '⭐ VIP': vip,
      if (priority.isNotEmpty) '⚡ Öncelikli': priority,
      if (standard.isNotEmpty) '📋 Standart': standard,
    };
  }

  void _setStatus(
    WidgetRef ref,
    String id,
    LiveFortuneRequestStatus status,
  ) {
    ref.read(liveFortuneRequestsProvider(streamId).notifier).setStatus(id, status);
  }
}

class _FortuneSwipeCard extends StatelessWidget {
  const _FortuneSwipeCard({
    required this.request,
    required this.onAccept,
    required this.onComplete,
    required this.onCancel,
  });

  final LiveFortuneRequestEntity request;
  final VoidCallback onAccept;
  final VoidCallback onComplete;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final wait = DateTime.now().difference(request.createdAt);
    final waitLabel = wait.inMinutes > 0
        ? '${wait.inMinutes} dk'
        : '${wait.inSeconds} sn';

    return Dismissible(
      key: ValueKey(request.id),
      background: _swipeBg(Colors.green, Icons.check_rounded, 'Tamamla', Alignment.centerLeft),
      secondaryBackground:
          _swipeBg(Colors.red, Icons.close_rounded, 'İptal', Alignment.centerRight),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          onComplete();
        } else {
          onCancel();
        }
        return false;
      },
      child: Card(
        color: Colors.white.withValues(alpha: 0.06),
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          onTap: onAccept,
          title: Text(
            request.displayName,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            '${request.fortuneType}\n${request.question}\n$waitLabel · ${request.jetonCost} jeton',
            style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
          ),
          trailing: Text(
            request.priority.label,
            style: TextStyle(
              color: request.isPremiumTier
                  ? const Color(0xFFFFD700)
                  : const Color(0xFFB832FF),
              fontWeight: FontWeight.w900,
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }

  Widget _swipeBg(Color c, IconData icon, String label, Alignment align) {
    return Container(
      alignment: align,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: c.withValues(alpha: 0.35),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _GiftsTab extends ConsumerWidget {
  const _GiftsTab({required this.streamId});
  final String streamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gifts = ref.watch(liveGiftControllerProvider).notifications;
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: gifts.length,
      itemBuilder: (_, i) {
        final g = gifts[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFFB832FF).withValues(alpha: 0.3),
            child: Text('${g.combo}', style: const TextStyle(fontSize: 11)),
          ),
          title: Text(g.senderName, style: const TextStyle(color: Colors.white)),
          subtitle: Text(
            '${g.giftName} · ${g.coinCost} jeton',
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
        );
      },
    );
  }
}

class _PkTab extends ConsumerWidget {
  const _PkTab({required this.streamId});
  final String streamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pk = ref.watch(liveVideoPkProvider(streamId));
    final battle = pk.battle;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (battle == null)
          const Text('Aktif PK daveti yok', style: TextStyle(color: Colors.white54))
        else ...[
          Text('Durum: ${pk.status}', style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 8),
          Text(
            'Skor: ${pk.leftScore} — ${pk.rightScore}',
            style: const TextStyle(
              color: Color(0xFFFFD700),
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 16),
          if (pk.status == 'pending')
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        ref.read(liveVideoPkProvider(streamId).notifier).reject(),
                    child: const Text('Reddet'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () =>
                        ref.read(liveVideoPkProvider(streamId).notifier).accept(),
                    child: const Text('Kabul'),
                  ),
                ),
              ],
            ),
        ],
      ],
    );
  }
}

class _GuestsTab extends ConsumerStatefulWidget {
  const _GuestsTab({required this.streamId});
  final String streamId;

  @override
  ConsumerState<_GuestsTab> createState() => _GuestsTabState();
}

class _GuestsTabState extends ConsumerState<_GuestsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(coBroadcastProvider.notifier).loadViewers(widget.streamId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final co = ref.watch(coBroadcastProvider);

    ref.listen(coBroadcastProvider.select((s) => s.error), (prev, next) {
      if (next != null && next.isNotEmpty && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next)),
        );
      }
    });

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Davet aç/kapat anahtarı — yalnızca bu cihazda UI'ı etkiler.
        Card(
          color: Colors.white.withValues(alpha: 0.06),
          child: SwitchListTile(
            value: co.inviteEnabled,
            onChanged: (v) =>
                ref.read(coBroadcastProvider.notifier).setInviteEnabled(v),
            title: const Text(
              'İzleyici davetlerine açık',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              co.inviteEnabled
                  ? 'İzleyicilerden birini seçip davet edebilirsiniz'
                  : 'Davet etme kapalı — yine de bekleyen istekleri onaylayabilirsiniz',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
            activeThumbColor: const Color(0xFFB832FF),
          ),
        ),
        const SizedBox(height: 8),

        _sectionTitle('Bekleyen istekler'),
        if (co.joinRequests.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Bekleyen istek yok',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
        ...co.joinRequests.map(
          (r) => ListTile(
            title: Text(
              r['userName']?.toString() ?? r['displayName']?.toString() ?? 'İzleyici',
              style: const TextStyle(color: Colors.white),
            ),
            trailing: FilledButton(
              onPressed: () {
                final uid = r['userId']?.toString() ?? '';
                if (uid.isNotEmpty) {
                  ref.read(coBroadcastProvider.notifier).approveRequest(
                        streamId: widget.streamId,
                        userId: uid,
                      );
                }
              },
              child: const Text('Kabul'),
            ),
          ),
        ),

        const SizedBox(height: 16),
        _sectionTitle('Aktif konuklar'),
        if (co.coBroadcasters.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Aktif konuk yok',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
        ...co.coBroadcasters.map(
          (g) => ListTile(
            title: Text(
              g['userName']?.toString() ?? 'Konuk',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),

        // Davet et bölümü — yalnızca anahtar açıkken gösterilir.
        if (co.inviteEnabled) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              _sectionTitle('İzleyiciyi davet et'),
              const Spacer(),
              IconButton(
                icon: co.viewersLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded, color: Colors.white54, size: 18),
                onPressed: co.viewersLoading
                    ? null
                    : () => ref
                        .read(coBroadcastProvider.notifier)
                        .loadViewers(widget.streamId),
              ),
            ],
          ),
          if (co.viewers.isEmpty && !co.viewersLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Davet edilebilecek izleyici yok',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),
          ...co.viewers.map((v) {
            final uid = v['userId']?.toString() ?? v['id']?.toString() ?? '';
            final name = v['userName']?.toString() ??
                v['displayName']?.toString() ??
                v['name']?.toString() ??
                'İzleyici';
            // Zaten konuk olan veya isteği bekleyen izleyiciyi listeden
            // ayıklamaya gerek yok — backend zaten uygun durumu döndürür,
            // ama burada en azından aktif konukları gizleyelim.
            final alreadyGuest = co.coBroadcasters.any(
              (g) => (g['userId']?.toString() ?? g['id']?.toString() ?? '') == uid,
            );
            if (alreadyGuest || uid.isEmpty) return const SizedBox.shrink();
            return ListTile(
              title: Text(name, style: const TextStyle(color: Colors.white)),
              trailing: OutlinedButton(
                onPressed: co.loading
                    ? null
                    : () async {
                        try {
                          await ref.read(coBroadcastProvider.notifier).invite(
                                streamId: widget.streamId,
                                inviteeId: uid,
                              );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('$name davet edildi')),
                            );
                          }
                        } catch (_) {
                          // Hata zaten state.error üzerinden ref.listen
                          // ile snackbar olarak gösteriliyor.
                        }
                      },
                child: const Text('Davet Et'),
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _ModerationTab extends ConsumerWidget {
  const _ModerationTab({required this.streamId});
  final String streamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Sohbet mesajına uzun basarak moderasyon menüsünü açabilirsiniz.',
          style: TextStyle(color: Colors.white60, fontSize: 12),
        ),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.shield_rounded, color: Colors.white70),
          title: const Text('Hızlı moderasyon', style: TextStyle(color: Colors.white)),
          subtitle: const Text(
            'Kullanıcı ID ile moderasyon',
            style: TextStyle(color: Colors.white54, fontSize: 11),
          ),
          onTap: () {
            // Host uses chat long-press in room.
          },
        ),
      ],
    );
  }
}

class _StatsTab extends ConsumerWidget {
  const _StatsTab({required this.streamId});
  final String streamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dash = ref.watch(liveHostDashboardProvider(streamId));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _statRow('Toplam Jeton', '${dash.totalJeton}'),
        _statRow('Dakikalık', '${dash.perMinuteJeton}'),
        _statRow('Saatlik', '${dash.perHourJeton}'),
        _statRow('Hediye', '${dash.giftCount}'),
        _statRow('İzleyici', '${dash.viewerCount}'),
        _statRow('Beğeni', '${dash.likeCount}'),
        const SizedBox(height: 16),
        LiveHostDashboardChart(
          label: 'Gelir',
          values: dash.revenueHistory,
          color: const Color(0xFFFFD700),
        ),
        const SizedBox(height: 12),
        LiveHostDashboardChart(
          label: 'İzleyici',
          values: dash.viewerHistory,
          color: const Color(0xFF22D3EE),
        ),
        const SizedBox(height: 12),
        LiveHostDashboardChart(
          label: 'Hediye',
          values: dash.giftHistory,
          color: const Color(0xFFB832FF),
        ),
      ],
    );
  }

  Widget _statRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(k, style: const TextStyle(color: Colors.white60)),
          const Spacer(),
          Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

Widget _sectionTitle(String t) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 4),
    child: Text(
      t,
      style: const TextStyle(
        color: Color(0xFFB832FF),
        fontWeight: FontWeight.w900,
        fontSize: 12,
        letterSpacing: 0.5,
      ),
    ),
  );
}