import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../domain/entities/live_fortune_request_entity.dart';
import '../../gifts/providers/live_gift_providers.dart';
import '../../providers/co_broadcast_provider.dart';
import '../../providers/live_guest_grid_provider.dart';
import '../../providers/live_fortune_request_provider.dart';
import '../../providers/live_host_dashboard_provider.dart';
import '../../providers/live_video_pk_provider.dart';
import '../../providers/live_stream_engagement_provider.dart';
import '../../providers/live_stream_viewers_provider.dart';
import '../../../../../core/widgets/lazy_list_views.dart';
import '../../widgets/broadcast_room/live_moderation_sheet.dart';
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
    _tabs = TabController(length: 7, vsync: this);
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
                      Tab(text: 'Etkinlik'),
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
                        _EngagementTab(streamId: widget.streamId),
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
    if (state.requests.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Fal isteği yok', style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    final sections = grouped.entries.toList(growable: false);
    final rows = <_FortuneRow>[];
    for (var s = 0; s < sections.length; s++) {
      final entry = sections[s];
      rows.add(_FortuneRow.title(entry.key));
      for (final r in entry.value) {
        rows.add(_FortuneRow.request(r));
      }
      if (s < sections.length - 1) {
        rows.add(const _FortuneRow.gap());
      }
    }

    return LazyListView(
      padding: const EdgeInsets.all(12),
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        return switch (row) {
          _FortuneTitle(:final label) => _sectionTitle(label),
          _FortuneRequest(:final request) => _FortuneSwipeCard(
              request: request,
              onAccept: () =>
                  _setStatus(ref, request.id, LiveFortuneRequestStatus.reviewing),
              onHold: () =>
                  _setStatus(ref, request.id, LiveFortuneRequestStatus.held),
              onComplete: () =>
                  _setStatus(ref, request.id, LiveFortuneRequestStatus.answered),
              onCancel: () =>
                  _setStatus(ref, request.id, LiveFortuneRequestStatus.cancelled),
            ),
          _FortuneGap() => const SizedBox(height: 8),
        };
      },
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
    required this.onHold,
    required this.onComplete,
    required this.onCancel,
  });

  final LiveFortuneRequestEntity request;
  final VoidCallback onAccept;
  final VoidCallback onHold;
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
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${request.fortuneType}\n${request.question}\n$waitLabel · ${request.jetonCost} jeton',
                style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: [
                  TextButton(
                    onPressed: onHold,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.amber,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 28),
                    ),
                    child: const Text('Beklet', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ],
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
            child: Text('${g.jetonAmount}', style: const TextStyle(fontSize: 11)),
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

class _GuestsTab extends ConsumerWidget {
  const _GuestsTab({required this.streamId});
  final String streamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final co = ref.watch(coBroadcastProvider);
    final requests = co.joinRequests;
    final guests = co.coBroadcasters;
    final itemCount = 1 + requests.length + 1 + guests.length;

    return LazyListView(
      padding: const EdgeInsets.all(12),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _sectionTitle('Bekleyen istekler');
        }
        if (index <= requests.length) {
          final r = requests[index - 1];
          return ListTile(
            title: Text(
              r['userName']?.toString() ?? r['displayName']?.toString() ?? 'İzleyici',
              style: const TextStyle(color: Colors.white),
            ),
            trailing: FilledButton(
              onPressed: () {
                final uid = r['userId']?.toString() ?? '';
                if (uid.isNotEmpty) {
                  ref.read(coBroadcastProvider.notifier).approveRequest(
                        streamId: streamId,
                        userId: uid,
                      );
                  ref.read(liveGuestGridProvider.notifier).addGuest(
                        slotIndex: 1,
                        userId: uid,
                        displayName: r['userName']?.toString() ??
                            r['displayName']?.toString() ??
                            'Konuk',
                      );
                }
              },
              child: const Text('Kabul'),
            ),
          );
        }
        if (index == requests.length + 1) {
          return _sectionTitle('Aktif konuklar');
        }
        final g = guests[index - requests.length - 2];
        return ListTile(
          title: Text(
            g['userName']?.toString() ?? 'Konuk',
            style: const TextStyle(color: Colors.white),
          ),
        );
      },
    );
  }
}

class _ModerationTab extends ConsumerStatefulWidget {
  const _ModerationTab({required this.streamId});
  final String streamId;

  @override
  ConsumerState<_ModerationTab> createState() => _ModerationTabState();
}

class _ModerationTabState extends ConsumerState<_ModerationTab> {
  final _userIdCtrl = TextEditingController();

  @override
  void dispose() {
    _userIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _quickMod(String action) async {
    final userId = _userIdCtrl.text.trim();
    if (userId.isEmpty) return;
    final mod = ref.read(liveModerationProvider(widget.streamId).notifier);
    final ok = switch (action) {
      'mute' => await mod.muteUser(userId),
      'kick' => await mod.kickUser(userId),
      'ban' => await mod.banUser(userId),
      'mod' => await mod.addModerator(userId),
      _ => false,
    };
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'İşlem uygulandı' : 'İşlem başarısız')),
    );
    if (ok) {
      ref.read(liveStreamEngagementProvider.notifier).logViolation(
            '$action → $userId',
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final violations = ref.watch(liveStreamEngagementProvider).violations;
    final log = violations.reversed.take(20).toList(growable: false);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(12),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed([
              TextField(
                controller: _userIdCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Kullanıcı ID',
                  hintText: 'Moderasyon hedefi',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _modBtn('Sustur', Icons.volume_off_rounded, () => _quickMod('mute')),
                  _modBtn('At', Icons.logout_rounded, () => _quickMod('kick')),
                  _modBtn('Ban', Icons.block_rounded, () => _quickMod('ban')),
                  _modBtn('Mod yap', Icons.shield_rounded, () => _quickMod('mod')),
                ],
              ),
              const SizedBox(height: 16),
              _sectionTitle('İhlal günlüğü'),
              if (log.isEmpty)
                const Text('Kayıt yok', style: TextStyle(color: Colors.white54)),
              const SizedBox(height: 8),
              const Text(
                'Sohbette uzun basarak da moderasyon açabilirsiniz.',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ]),
          ),
        ),
        if (log.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverList.builder(
              itemCount: log.length,
              itemBuilder: (context, index) => ListTile(
                dense: true,
                leading: const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 18),
                title: Text(
                  log[index],
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _modBtn(String label, IconData icon, VoidCallback onTap) {
    return FilledButton.tonalIcon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }
}

class _EngagementTab extends ConsumerStatefulWidget {
  const _EngagementTab({required this.streamId});
  final String streamId;

  @override
  ConsumerState<_EngagementTab> createState() => _EngagementTabState();
}

class _EngagementTabState extends ConsumerState<_EngagementTab> {
  final _pollQ = TextEditingController();
  final _opt1 = TextEditingController();
  final _opt2 = TextEditingController();
  final _banner = TextEditingController();

  @override
  void dispose() {
    _pollQ.dispose();
    _opt1.dispose();
    _opt2.dispose();
    _banner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eng = ref.watch(liveStreamEngagementProvider);
    final poll = eng.activePoll;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _sectionTitle('Anket'),
        TextField(
          controller: _pollQ,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Soru',
            labelStyle: TextStyle(color: Colors.white70),
          ),
        ),
        TextField(
          controller: _opt1,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Seçenek 1',
            labelStyle: TextStyle(color: Colors.white70),
          ),
        ),
        TextField(
          controller: _opt2,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Seçenek 2',
            labelStyle: TextStyle(color: Colors.white70),
          ),
        ),
        Row(
          children: [
            FilledButton(
              onPressed: () {
                ref.read(liveStreamEngagementProvider.notifier).createPoll(
                      question: _pollQ.text,
                      optionLabels: [_opt1.text, _opt2.text],
                    );
              },
              child: const Text('Başlat'),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () =>
                  ref.read(liveStreamEngagementProvider.notifier).closePoll(),
              child: const Text('Kapat'),
            ),
          ],
        ),
        if (poll != null) ...[
          Text(
            poll.question,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          for (final o in poll.options)
            ListTile(
              dense: true,
              title: Text(o.label, style: const TextStyle(color: Colors.white70)),
              trailing: Text('${o.votes}', style: const TextStyle(color: Colors.amber)),
            ),
          Text(
            'İzleyiciler sohbete !oy 1 veya !oy 2 yazarak oy verir.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 10),
          ),
        ],
        const SizedBox(height: 16),
        _sectionTitle('Etkinlik duyurusu'),
        TextField(
          controller: _banner,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Banner metni',
            labelStyle: TextStyle(color: Colors.white70),
          ),
        ),
        FilledButton.tonal(
          onPressed: () => ref
              .read(liveStreamEngagementProvider.notifier)
              .setEventBanner(_banner.text),
          child: const Text('Yayınla'),
        ),
        if (eng.eventBanner != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(eng.eventBanner!, style: const TextStyle(color: Colors.cyanAccent)),
          ),
        const SizedBox(height: 16),
        _sectionTitle('Çekiliş'),
        FilledButton.icon(
          onPressed: () async {
            final viewers = await ref.read(liveStreamViewersProvider(widget.streamId).future);
            final names = viewers.map((v) => v.displayName).where((n) => n.isNotEmpty).toList();
            final winner = ref.read(liveStreamEngagementProvider.notifier).pickGiveawayWinner(names);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(winner != null ? 'Kazanan: $winner' : 'İzleyici yok')),
            );
          },
          icon: const Icon(Icons.casino_rounded),
          label: const Text('Rastgele kazanan seç'),
        ),
        if (eng.lastGiveawayWinner != null)
          Text(
            'Son kazanan: ${eng.lastGiveawayWinner}',
            style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w800),
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

sealed class _FortuneRow {
  const _FortuneRow();
  const factory _FortuneRow.title(String label) = _FortuneTitle;
  const factory _FortuneRow.request(LiveFortuneRequestEntity request) =
      _FortuneRequest;
  const factory _FortuneRow.gap() = _FortuneGap;
}

final class _FortuneTitle extends _FortuneRow {
  const _FortuneTitle(this.label);
  final String label;
}

final class _FortuneRequest extends _FortuneRow {
  const _FortuneRequest(this.request);
  final LiveFortuneRequestEntity request;
}

final class _FortuneGap extends _FortuneRow {
  const _FortuneGap();
}