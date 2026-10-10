import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../admin/presentation/providers/staff_access_provider.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../girlive_patron_address.dart';
import '../providers/girlive_publisher_assistant_provider.dart';

Future<void> showGirLivePublisherAssistantSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String roomKey,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF0E0A1A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (_, scroll) => GirLivePublisherAssistantSheet(
        roomKey: roomKey,
        scrollController: scroll,
      ),
    ),
  );
}

class GirLivePublisherAssistantSheet extends ConsumerStatefulWidget {
  const GirLivePublisherAssistantSheet({
    super.key,
    required this.roomKey,
    required this.scrollController,
  });

  final String roomKey;
  final ScrollController scrollController;

  @override
  ConsumerState<GirLivePublisherAssistantSheet> createState() =>
      _GirLivePublisherAssistantSheetState();
}

class _GirLivePublisherAssistantSheetState
    extends ConsumerState<GirLivePublisherAssistantSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(girlivePublisherAssistantProvider(widget.roomKey).notifier)
          .refresh();
    });
  }

  String _dur(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '$h sa $m dk';
    return '$m dk';
  }

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(girlivePublisherAssistantProvider(widget.roomKey));
    final user = ref.watch(authControllerProvider).valueOrNull;
    final staff = ref.watch(staffAccessProvider);
    final salutation = GirLivePatronAddress.salutation(
      staff: staff,
      realName: user?.display,
      username: user?.username,
    );

    final metrics = view.localMetrics;
    final server = view.serverReport;
    final gross = server?.grossGiftJeton ?? view.grossGiftJeton;
    final netHint = server?.netOwnerJeton;
    final visits = server?.totalVisits ?? metrics?.totalVisitEvents ?? 0;
    final unique = server?.uniqueVisitors ?? metrics?.uniqueVisitorCount ?? 0;
    final returns = server?.returnVisitors ?? metrics?.returnVisitorCount ?? 0;
    final pkDone = server?.pkCompleted ?? metrics?.pkCompleted ?? 0;
    final pkWon = server?.pkWon ?? metrics?.pkWon ?? 0;
    final pkLost = server?.pkLost ?? metrics?.pkLost ?? 0;

    final started = server?.startedAt ?? metrics?.startedAt;
    final elapsed = server?.endedAt != null && started != null
        ? server!.endedAt!.difference(started)
        : metrics?.elapsed ?? Duration.zero;

    final liveLine = view.liveLine?.replaceFirst('Patron', salutation);

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '🤖 GirLive — Yayıncı Asistanım',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Yalnızca siz görürsünüz · genel sohbete yazılmaz',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12),
        ),
        if (view.loading) ...[
          const SizedBox(height: 24),
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ],
        if (liveLine != null) ...[
          const SizedBox(height: 16),
          _card(
            child: Text(
              liveLine,
              style: const TextStyle(color: Colors.white, height: 1.35),
            ),
          ),
        ],
        const SizedBox(height: 16),
        _sectionTitle('Yayın süresi ve oda'),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (started != null)
                _row('Açılış', _fmtTime(started)),
              _row('Geçen süre', _dur(elapsed)),
              _row('Toplam ziyaret', '$visits'),
              _row('Tekil ziyaretçi', '$unique'),
              _row('Tekrar gelen', '$returns'),
              if (metrics?.peakActiveViewerCount != null &&
                  metrics!.peakActiveViewerCount > 0)
                _row('En yüksek eşzamanlı', '${metrics.peakActiveViewerCount}'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _sectionTitle('Hediye ve Jeton'),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _row('Brüt hediye (Jeton)', '$gross'),
              if (netHint != null) _row('Size yansıyan net', '$netHint Jeton'),
              _row('Hediye adedi (oturum)', '${view.giftCount}'),
              const SizedBox(height: 8),
              Text(
                'Jeton değeri gerçek para değildir; net kazanç cüzdan '
                'hareketlerinden doğrulanır.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        if (pkDone > 0) ...[
          const SizedBox(height: 12),
          _sectionTitle('PK'),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row('Tamamlanan PK', '$pkDone'),
                _row('Kazanılan', '$pkWon'),
                _row('Kaybedilen', '$pkLost'),
                if ((server?.pkDraw ?? metrics?.pkDraw ?? 0) > 0)
                  _row('Berabere', '${server?.pkDraw ?? metrics?.pkDraw}'),
              ],
            ),
          ),
        ],
        if (view.tips.isNotEmpty) ...[
          const SizedBox(height: 12),
          _sectionTitle('Öneriler'),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final t in view.tips)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      '💡 $salutation, $t',
                      style: const TextStyle(color: Colors.white, height: 1.35),
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (!view.hasServer && !view.loading) ...[
          const SizedBox(height: 12),
          Text(
            'Detaylı geçmiş raporlar sunucu entegrasyonu ile açılır '
            '(gün/hafta/ay). Oturum verileri cihazınızda toplanır.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
            ),
          ),
        ],
        if (view.error != null) ...[
          const SizedBox(height: 8),
          Text(
            'Sunucu raporu alınamadı (${view.error}). Yerel oturum verisi gösteriliyor.',
            style: const TextStyle(color: Color(0xFFFFAB91), fontSize: 11),
          ),
        ],
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: view.loading
              ? null
              : () => ref
                  .read(girlivePublisherAssistantProvider(widget.roomKey).notifier)
                  .refresh(),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Yenile'),
        ),
      ],
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          t,
          style: const TextStyle(
            color: Color(0xFFFFD54F),
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      );

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1430),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _fmtTime(DateTime dt) {
    final l = dt.toLocal();
    return '${l.day}.${l.month}.${l.year} '
        '${l.hour.toString().padLeft(2, '0')}:'
        '${l.minute.toString().padLeft(2, '0')}';
  }
}
