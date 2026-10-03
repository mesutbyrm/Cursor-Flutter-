import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../../core/widgets/settings_kit.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../../live/presentation/providers/live_streams_list_notifier.dart';
import '../providers/admin_panel_providers.dart';
import '../providers/staff_access_provider.dart';

/// `GET /api/admin/statistics` → `streams` bölümü (hediye toplamı, toplam yayın).
final adminStreamStatsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(adminRemoteProvider);
  return dio.fetchStreamStatistics();
});

/// Admin — canlı yayın istatistikleri.
///
/// Sayılar gerçek kaynaklardan gelir: canlı yayın listesi (aktif yayın,
/// toplam izleyici, aktif yayıncı) ve `/api/admin/statistics` (hediye değeri).
/// Son 7 gün grafiği için sunucuda zaman serisi ucu olmadığından grafik
/// boş-durum gösterir; sahte veri çizilmez.
class AdminLiveStatsPage extends ConsumerWidget {
  const AdminLiveStatsPage({super.key, this.series = const []});

  /// Sunucu zaman serisi sağlayınca (ör. izleyici/gün) doldurulur.
  final List<AdminSeriesPoint> series;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(staffAccessProvider);
    final c = context.colors;
    if (!access.canManageLiveStreams && !access.canViewReports) {
      return Scaffold(
        body: DiscoverBackground(
          child: Center(
            child: Text(
              'Bu alan için yetkiniz yok.',
              style: TextStyle(color: c.onSurfaceVariant),
            ),
          ),
        ),
      );
    }

    final streams = ref.watch(liveStreamsListNotifierProvider).valueOrNull;
    final live = streams?.where((s) => s.isLive).toList();
    final viewers = live?.fold<int>(0, (a, s) => a + s.viewerCount);
    final hosts = live
        ?.map((s) => s.hostUserId ?? s.streamerName ?? s.id)
        .toSet()
        .length;
    final stats = ref.watch(adminStreamStatsProvider).valueOrNull;
    final giftValue = (stats?['totalGiftsValue'] as num?)?.toInt();

    String fmt(int? v) => v == null ? '—' : _compact(v);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: 'Canlı Yayın İstatistikleri',
          subtitle: 'Anlık durum',
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(adminStreamStatsProvider);
              ref.invalidate(liveStreamsListNotifierProvider);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 40),
              children: [
                SettingsTileGrid(
                  children: [
                    _Stat(
                      icon: Icons.live_tv_rounded,
                      label: 'Aktif Yayın',
                      value: fmt(live?.length),
                      accent: const Color(0xFF19C37D),
                    ),
                    _Stat(
                      icon: Icons.remove_red_eye_rounded,
                      label: 'Toplam İzleyici',
                      value: fmt(viewers),
                      accent: const Color(0xFFE056FD),
                    ),
                    _Stat(
                      icon: Icons.card_giftcard_rounded,
                      label: 'Hediye Geliri (toplam)',
                      value: fmt(giftValue),
                      accent: const Color(0xFF8E6BFF),
                    ),
                    _Stat(
                      icon: Icons.mic_external_on_rounded,
                      label: 'Aktif Yayıncı',
                      value: fmt(hosts),
                      accent: const Color(0xFFFFB020),
                    ),
                  ],
                ),
                const SettingsSectionHeader('Son 7 Gün', icon: Icons.show_chart_rounded),
                SettingsPanel(
                  child: AdminSeriesChart(points: series),
                ),
              ],
            ),
          ),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: c.surfaceContainer,
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: c.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: c.onSurfaceMuted),
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

/// Basit çizgi grafik. [points] boşsa sahte veri çizmez, boş-durum gösterir.
class AdminSeriesChart extends StatelessWidget {
  const AdminSeriesChart({super.key, required this.points});

  final List<AdminSeriesPoint> points;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (points.length < 2) {
      return SizedBox(
        height: 120,
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
      height: 160,
      child: CustomPaint(
        size: Size.infinite,
        painter: _LinePainter(points, c.primary, c.onSurfaceMuted),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter(this.points, this.color, this.muted);

  final List<AdminSeriesPoint> points;
  final Color color;
  final Color muted;

  @override
  void paint(Canvas canvas, Size size) {
    final maxV = points.map((p) => p.value).reduce(math.max);
    final top = maxV <= 0 ? 1.0 : maxV;
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = size.width * i / (points.length - 1);
      final y = size.height - (points[i].value / top) * (size.height - 8) - 4;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) =>
      old.points != points || old.color != color;
}
