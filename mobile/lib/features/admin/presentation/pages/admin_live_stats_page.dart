import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/util/json_util.dart';
import '../../../../core/widgets/mock_ui_kit.dart';
import '../../../live/presentation/providers/live_streams_list_notifier.dart';
import '../providers/admin_panel_providers.dart';
import '../providers/staff_access_provider.dart';

/// `GET /api/admin/statistics` → `streams` bölümü (hediye toplamı, toplam yayın).
final adminStreamStatsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(adminRemoteProvider);
  return dio.fetchStreamStatistics();
});

/// `GET /api/admin/live-stats?days=N` — uç dağıtılmadıysa `null`.
final adminLiveStatsProvider =
    FutureProvider.autoDispose.family<AdminLiveStats?, int>((ref, days) async {
  final raw = await ref.watch(adminRemoteProvider).fetchLiveStats(days);
  return raw == null ? null : AdminLiveStats.fromJson(raw);
});

class AdminLiveStats {
  const AdminLiveStats({
    this.activeStreams,
    this.totalViewers,
    this.giftRevenue,
    this.activeBroadcasters,
    this.series = const [],
  });

  factory AdminLiveStats.fromJson(Map<String, dynamic> j) {
    int? n(String k) => j[k] == null ? null : asInt(j[k]);
    return AdminLiveStats(
      activeStreams: n('activeStreams'),
      totalViewers: n('totalViewers'),
      giftRevenue: n('giftRevenue'),
      activeBroadcasters: n('activeBroadcasters'),
      series: [
        for (final row in asJsonList(j['series']))
          AdminSeriesPoint(
            _dayLabel('${row['date'] ?? ''}'),
            asInt(row['viewers']).toDouble(),
          ),
      ],
    );
  }

  final int? activeStreams;
  final int? totalViewers;
  final int? giftRevenue;
  final int? activeBroadcasters;
  final List<AdminSeriesPoint> series;
}

String _dayLabel(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  const months = [
    'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
    'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
  ];
  return '${d.day} ${months[d.month - 1]}';
}

/// Admin — canlı yayın istatistikleri.
///
/// Kartlar önce `live-stats` ucundan, yoksa canlı yayın listesi ve
/// `/api/admin/statistics` kaynaklarından gelir. Grafik yalnızca sunucu
/// serisi varsa çizilir; sahte veri üretilmez.
class AdminLiveStatsPage extends ConsumerStatefulWidget {
  const AdminLiveStatsPage({super.key, this.series = const []});

  /// Test / önizleme için dışarıdan verilen seri (sunucu serisi önceliklidir).
  final List<AdminSeriesPoint> series;

  @override
  ConsumerState<AdminLiveStatsPage> createState() => _AdminLiveStatsPageState();
}

class _AdminLiveStatsPageState extends ConsumerState<AdminLiveStatsPage> {
  var _days = 7;

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(staffAccessProvider);
    final c = context.colors;
    if (!access.canManageLiveStreams && !access.canViewReports) {
      return MockScaffold(
        title: 'Canlı Yayın İstatistikleri',
        body: Center(
          child: Text(
            'Bu alan için yetkiniz yok.',
            style: TextStyle(color: c.onSurfaceVariant),
          ),
        ),
      );
    }

    final server = ref.watch(adminLiveStatsProvider(_days)).valueOrNull;
    final streams = ref.watch(liveStreamsListNotifierProvider).valueOrNull;
    final live = streams?.where((s) => s.isLive).toList();
    final viewers = live?.fold<int>(0, (a, s) => a + s.viewerCount);
    final hosts = live
        ?.map((s) => s.hostUserId ?? s.streamerName ?? s.id)
        .toSet()
        .length;
    final stats = ref.watch(adminStreamStatsProvider).valueOrNull;
    final giftValue = (stats?['totalGiftsValue'] as num?)?.toInt();

    final activeStreams = server?.activeStreams ?? live?.length;
    final totalViewers = server?.totalViewers ?? viewers;
    final giftRevenue = server?.giftRevenue ?? giftValue;
    final activeHosts = server?.activeBroadcasters ?? hosts;
    final series =
        (server?.series.isNotEmpty ?? false) ? server!.series : widget.series;

    String fmt(int? v) => v == null ? '—' : _compact(v);

    return MockScaffold(
      title: 'Canlı Yayın İstatistikleri',
      startAligned: true,
      actions: [
        PopupMenuButton<int>(
          tooltip: 'Dönem',
          initialValue: _days,
          onSelected: (v) => setState(() => _days = v),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 7, child: Text('Son 7 Gün')),
            PopupMenuItem(value: 14, child: Text('Son 14 Gün')),
            PopupMenuItem(value: 30, child: Text('Son 30 Gün')),
          ],
          child: Container(
            margin: const EdgeInsetsDirectional.only(end: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: mockCardColor(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: mockCardBorder(context)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Son $_days Gün',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: c.onSurface,
                  ),
                ),
                Icon(Icons.keyboard_arrow_down_rounded,
                    size: 16, color: c.onSurface),
              ],
            ),
          ),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminStreamStatsProvider);
          ref.invalidate(adminLiveStatsProvider(_days));
          ref.invalidate(liveStreamsListNotifierProvider);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsetsDirectional.fromSTEB(14, 6, 14, 40),
          children: [
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    icon: Icons.sensors_rounded,
                    label: 'Aktif Yayın',
                    value: fmt(activeStreams),
                    accent: const Color(0xFF19B6E8),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Stat(
                    icon: Icons.remove_red_eye_rounded,
                    label: 'Toplam İzleyici',
                    value: fmt(totalViewers),
                    accent: const Color(0xFFE056FD),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    icon: Icons.card_giftcard_rounded,
                    label: 'Hediye Geliri',
                    value: fmt(giftRevenue),
                    accent: const Color(0xFF8B5CF6),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Stat(
                    icon: Icons.mic_external_on_rounded,
                    label: 'Aktif Yayıncı',
                    value: fmt(activeHosts),
                    accent: const Color(0xFFFFB020),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
              decoration: BoxDecoration(
                color: mockCardColor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: mockCardBorder(context)),
              ),
              child: AdminSeriesChart(points: series),
            ),
          ],
        ),
      ),
    );
  }
}

String _compact(int v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
  return '$v';
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: mockCardColor(context),
        border: Border.all(color: mockCardBorder(context)),
      ),
      child: Row(
        children: [
          MockIconSquare(icon: icon, color: accent, size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: c.onSurfaceMuted),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: c.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminSeriesPoint {
  const AdminSeriesPoint(this.label, this.value);
  final String label;
  final double value;
}

/// Gradyan dolgulu çizgi grafik. [points] boşsa sahte veri çizmez, boş-durum gösterir.
class AdminSeriesChart extends StatelessWidget {
  const AdminSeriesChart({super.key, required this.points});

  final List<AdminSeriesPoint> points;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (points.length < 2) {
      return SizedBox(
        height: 140,
        child: Center(
          child: Text(
            'Zaman serisi verisi sunucudan henüz sağlanmıyor.',
            textAlign: TextAlign.center,
            style: TextStyle(color: c.onSurfaceMuted, fontSize: 12.5),
          ),
        ),
      );
    }
    return SizedBox(
      height: 190,
      child: CustomPaint(
        size: Size.infinite,
        painter: _LinePainter(
          points,
          const Color(0xFF8B5CF6),
          c.onSurfaceMuted,
          c.onSurfaceMuted.withValues(alpha: 0.18),
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter(this.points, this.color, this.muted, this.grid);

  final List<AdminSeriesPoint> points;
  final Color color;
  final Color muted;
  final Color grid;

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 34.0;
    const bottomPad = 20.0;
    final plotW = size.width - leftPad;
    final plotH = size.height - bottomPad - 6;
    final maxV = points.map((p) => p.value).reduce(math.max);
    final top = maxV <= 0 ? 1.0 : maxV;

    TextPainter tp(String t) => TextPainter(
          text: TextSpan(text: t, style: TextStyle(
              color: muted,
              fontSize: 9,
              fontFamily: AppTheme.fontFamily,
            )),
          textDirection: TextDirection.ltr,
        )..layout();

    for (var i = 0; i <= 3; i++) {
      final y = 6 + plotH * i / 3;
      canvas.drawLine(
        Offset(leftPad, y),
        Offset(size.width, y),
        Paint()
          ..color = grid
          ..strokeWidth = 1,
      );
      final label = tp(_compact((top * (3 - i) / 3).round()));
      label.paint(canvas, Offset(leftPad - label.width - 4, y - 5));
    }

    Offset at(int i) => Offset(
          leftPad + plotW * i / (points.length - 1),
          6 + plotH - (points[i].value / top) * plotH,
        );

    final line = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < points.length; i++) {
      final a = at(i - 1);
      final b = at(i);
      final mx = (a.dx + b.dx) / 2;
      line.cubicTo(mx, a.dy, mx, b.dy, b.dx, b.dy);
    }
    final fill = Path.from(line)
      ..lineTo(at(points.length - 1).dx, 6 + plotH)
      ..lineTo(at(0).dx, 6 + plotH)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.38), color.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    final last = at(points.length - 1);
    canvas.drawCircle(last, 4.5, Paint()..color = Colors.white);
    canvas.drawCircle(last, 3, Paint()..color = color);

    final step = math.max(1, (points.length / 6).ceil());
    for (var i = 0; i < points.length; i += step) {
      final l = tp(points[i].label);
      l.paint(
        canvas,
        Offset(
          (at(i).dx - l.width / 2).clamp(0.0, size.width - l.width),
          size.height - 12,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) =>
      old.points != points || old.color != color;
}
