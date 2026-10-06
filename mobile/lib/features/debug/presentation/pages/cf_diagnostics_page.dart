import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../core/diagnostics/cf_diag.dart';
import '../../../../core/diagnostics/cf_diagnostic_export.dart';
import '../../../../core/diagnostics/cf_diagnostic_logger.dart';
import '../../../../core/diagnostics/cf_monitors.dart';
import '../../../../core/diagnostics/cf_resource_tracker.dart';
import '../../../../core/diagnostics/cf_self_check.dart';
import '../../../../core/diagnostics/cf_trace.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/network/sse/base_sse_service.dart';
import '../../../../core/network/token_storage.dart';
import '../../../../core/performance/app_perf_metrics.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live_psychics/presentation/providers/live_psychics_providers.dart';
import '../../../trtc/presentation/providers/trtc_providers.dart';

/// CANLIFAL DIAGNOSTICS — iç kullanım: kendi kendine tanı, performans, ağ,
/// TRTC/SSE ve hata kayıtları. Üretim kullanıcılarına menüde gösterilmez;
/// ayarlardaki sürüm satırına uzun basılarak açılır.
class CfDiagnosticsPage extends ConsumerStatefulWidget {
  const CfDiagnosticsPage({super.key});

  @override
  ConsumerState<CfDiagnosticsPage> createState() => _CfDiagnosticsPageState();
}

class _CfDiagnosticsPageState extends ConsumerState<CfDiagnosticsPage> {
  final _results = <CfCheckResult>[];
  var _running = false;
  var _cancelled = false;

  @override
  void initState() {
    super.initState();
    CfDiag.addListener(_onDiag);
    CfDiagnosticLogger.fileLoggingEnabled.addListener(_onDiag);
    CfDiagnosticLogger.revision.addListener(_onDiag);
  }

  @override
  void dispose() {
    _cancelled = true;
    CfDiag.removeListener(_onDiag);
    CfDiagnosticLogger.fileLoggingEnabled.removeListener(_onDiag);
    CfDiagnosticLogger.revision.removeListener(_onDiag);
    super.dispose();
  }

  void _onDiag() {
    if (mounted) setState(() {});
  }

  var _exporting = false;

  List<CfCheckSpec> _specs() {
    final container = ProviderScope.containerOf(context, listen: false);
    final dio = container.read(dioProvider);

    Future<CfCheckOutcome> httpCheck(String path, {String label = ''}) async {
      final sw = Stopwatch()..start();
      try {
        final res = await dio.get<dynamic>(path);
        final code = res.statusCode ?? 0;
        if (code >= 200 && code < 300) {
          return CfCheckOutcome.latency(sw.elapsedMilliseconds, label: label);
        }
        return CfCheckOutcome.fail('HTTP $code');
      } on DioException catch (e) {
        return CfCheckOutcome.fail(
          e.response?.statusCode != null
              ? 'HTTP ${e.response!.statusCode}'
              : (e.type.name),
        );
      }
    }

    return [
      CfCheckSpec('Authentication', () async {
        final user = container.read(authControllerProvider).valueOrNull;
        return user == null
            ? const CfCheckOutcome.fail('giriş yapılmamış')
            : const CfCheckOutcome.ok('oturum açık');
      }),
      CfCheckSpec('JWT', () async {
        final token = await container.read(tokenStorageProvider).readAccess();
        if (token == null || token.isEmpty) {
          return const CfCheckOutcome.fail('erişim anahtarı yok');
        }
        final left = _jwtSecondsLeft(token);
        if (left == null) return const CfCheckOutcome.ok('biçim tanınmadı');
        if (left <= 0) return const CfCheckOutcome.warn('süresi dolmuş (yenilenir)');
        if (left < 300) return CfCheckOutcome.warn('$left sn kaldı');
        return CfCheckOutcome.ok('${(left / 60).floor()} dk geçerli');
      }),
      CfCheckSpec('API', () => httpCheck('/api/public/jeton-price', label: 'gecikme')),
      CfCheckSpec('Profile', () => httpCheck(ApiEndpoints.me, label: 'gecikme')),
      CfCheckSpec('Live Fortune', () async {
        final sw = Stopwatch()..start();
        final list = await container
            .read(livePsychicsRepositoryProvider)
            .fetchPsychics(page: 1, limit: 5, onlineOnly: false);
        final o = CfCheckOutcome.latency(sw.elapsedMilliseconds,
            label: '${list.length} falcı,');
        return o;
      }),
      CfCheckSpec('Session (aktif seans sorgusu)', () async {
        final sw = Stopwatch()..start();
        final active = await container
            .read(livePsychicsRepositoryProvider)
            .fetchActiveSessionsOrNull();
        if (active == null) return const CfCheckOutcome.fail('sorgu başarısız');
        return CfCheckOutcome.latency(sw.elapsedMilliseconds,
            label: '${active.length} aktif,');
      }),
      CfCheckSpec('TRTC Token', () async {
        final user = container.read(authControllerProvider).valueOrNull;
        if (user == null) return const CfCheckOutcome.skip('giriş gerekli');
        final sw = Stopwatch()..start();
        try {
          final creds = await container.read(trtcRemoteProvider).fetchToken(
                roomId: 'cf-diagnostics-${user.id}',
                role: 'audience',
                userId: user.id,
              );
          // Token değeri asla gösterilmez/loglanmaz.
          return creds.isValid
              ? CfCheckOutcome.latency(sw.elapsedMilliseconds)
              : const CfCheckOutcome.fail('geçersiz yanıt');
        } on DioException catch (e) {
          final code = e.response?.statusCode;
          // Sahte oda için sunucu reddedebilir; uç erişilebilir demektir.
          if (code != null && code >= 400 && code < 500) {
            return CfCheckOutcome.warn('uç erişilebilir, HTTP $code (sahte oda)');
          }
          return CfCheckOutcome.fail(code != null ? 'HTTP $code' : e.type.name);
        }
      }),
      CfCheckSpec('SSE (bağlantı)', () async {
        final token = await container.read(tokenStorageProvider).readAccess();
        if (token == null || token.isEmpty) {
          return const CfCheckOutcome.skip('giriş gerekli');
        }
        final probe = Dio(BaseOptions(
          baseUrl: Env.apiBaseUrl,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ));
        final cancel = CancelToken();
        final sw = Stopwatch()..start();
        try {
          final res = await probe.get<ResponseBody>(
            ApiEndpoints.fortuneTellerSessionsStream,
            options: Options(
              responseType: ResponseType.stream,
              headers: {
                'Accept': 'text/event-stream',
                'Authorization': 'Bearer ${token.trim()}',
              },
            ),
            cancelToken: cancel,
          );
          final code = res.statusCode ?? 0;
          return code == 200
              ? CfCheckOutcome.latency(sw.elapsedMilliseconds, label: 'bağlandı,')
              : CfCheckOutcome.fail('HTTP $code');
        } on DioException catch (e) {
          final code = e.response?.statusCode;
          return CfCheckOutcome.fail(code != null ? 'HTTP $code' : e.type.name);
        } finally {
          cancel.cancel('probe');
          probe.close(force: true);
        }
      }),
      CfCheckSpec('Heartbeat (seans SSE)', () async {
        final last = CfDiag.lastRoomSseEventAt;
        if (last == null) {
          return const CfCheckOutcome.skip('aktif seans SSE bağlantısı yok');
        }
        final age = DateTime.now().difference(last);
        return age > BaseSseService.heartbeatTimeout
            ? CfCheckOutcome.fail('heartbeat timeout: ${age.inSeconds} sn')
            : CfCheckOutcome.ok('son olay ${age.inSeconds} sn önce');
      }),
    ];
  }

  static int? _jwtSecondsLeft(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;
      var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      final json = String.fromCharCodes(Uri.parse('data:;base64,$payload')
          .data!
          .contentAsBytes());
      final m = RegExp(r'"exp"\s*:\s*(\d+)').firstMatch(json);
      if (m == null) return null;
      final exp = int.parse(m.group(1)!);
      return exp - DateTime.now().millisecondsSinceEpoch ~/ 1000;
    } catch (_) {
      return null;
    }
  }

  Future<void> _run() async {
    if (_running) return;
    setState(() {
      _running = true;
      _results.clear();
    });
    final trace = CfTrace.start('SELF_DIAGNOSTIC', CfCategory.unknown);
    await CfCheckRunner.runAll(
      _specs(),
      isCancelled: () => _cancelled,
      onResult: (r) {
        if (!mounted) return;
        setState(() => _results.add(r));
        trace.step(r.name, failed: r.status == CfCheckStatus.fail);
      },
    );
    trace.finish();
    if (mounted) setState(() => _running = false);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 11,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('CANLIFAL DIAGNOSTICS'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Errors'),
              Tab(text: 'Network'),
              Tab(text: 'Timer'),
              Tab(text: 'Polling'),
              Tab(text: 'SSE'),
              Tab(text: 'TRTC'),
              Tab(text: 'Requests'),
              Tab(text: 'Freeze'),
              Tab(text: 'Resources'),
              Tab(text: 'Self check'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _overviewTab(),
            _combinedErrorsTab(),
            _networkTab(),
            _fileCategoryTab(CfFileLogCategory.timer),
            _fileCategoryTab(CfFileLogCategory.polling),
            _logTab({CfCategory.sse}),
            _logTab({CfCategory.trtc}),
            _fileCategoryTab(CfFileLogCategory.request),
            _freezeTab(),
            _resourcesTab(),
            _diagnosticsTab(),
          ],
        ),
      ),
    );
  }

  String _healthStatus() {
    final snap = CfResourceTracker.snapshot();
    final bad = snap.activeTimers > 3 ||
        snap.activePollers > 2 ||
        snap.activeSse > 1 ||
        snap.activeTrtc > 1 ||
        snap.activeRequests > 3 ||
        CfFreezeWatchdog.freezeCount > 0 ||
        CfDiagnosticLogger.errors.isNotEmpty;
    if (bad) return 'CRITICAL';
    if (snap.activeTimers > 1 ||
        snap.activePollers > 0 ||
        CfFrameMonitor.stats.janky > 5) {
      return 'WARNING';
    }
    return 'HEALTHY';
  }

  Widget _overviewTab() {
    final snap = CfResourceTracker.snapshot();
    final lf = CfResourceTracker.snapshot(module: 'live_fortune');
    final ls = CfResourceTracker.snapshot(module: 'live_stream');
    final vr = CfResourceTracker.snapshot(module: 'voice_room');
    final status = _healthStatus();
    final statusColor = switch (status) {
      'HEALTHY' => Colors.greenAccent,
      'WARNING' => Colors.amberAccent,
      _ => Colors.redAccent,
    };
    String row(String label, int n, {int okMax = 1}) =>
        '$label  $n ${n <= okMax ? '✓' : '🔴'}';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('STATUS: $status',
            style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 18, color: statusColor)),
        if (CfDiagnosticLogger.sessionId != null)
          Text('Session: ${CfDiagnosticLogger.sessionId}',
              style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 12),
        const Text('LIVE FORTUNE', style: TextStyle(fontWeight: FontWeight.w800)),
        Text(row('Timer', lf.activeTimers, okMax: 2)),
        Text(row('Polling', lf.activePollers, okMax: 1)),
        Text(row('SSE', lf.activeSse)),
        Text(row('TRTC', lf.activeTrtc)),
        Text(row('Requests', lf.activeRequests, okMax: 2)),
        const SizedBox(height: 8),
        const Text('LIVE STREAM', style: TextStyle(fontWeight: FontWeight.w800)),
        Text(row('Timer', ls.activeTimers, okMax: 2)),
        Text(row('SSE', ls.activeSse)),
        Text(row('TRTC', ls.activeTrtc)),
        const SizedBox(height: 8),
        const Text('VOICE ROOM', style: TextStyle(fontWeight: FontWeight.w800)),
        Text(row('Timer', vr.activeTimers, okMax: 2)),
        Text(row('SSE', vr.activeSse)),
        Text(row('TRTC', vr.activeTrtc)),
        const SizedBox(height: 8),
        Text(
          'Global · Timer ${snap.activeTimers} · SSE ${snap.activeSse} · '
          'TRTC ${snap.activeTrtc} · Freeze ${CfFreezeWatchdog.freezeCount}',
        ),
        const Divider(height: 24),
        ValueListenableBuilder<bool>(
          valueListenable: CfDiagnosticLogger.fileLoggingEnabled,
          builder: (context, fileOn, _) => SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Dosyaya kaydet (Redmi test)'),
            subtitle: const Text(
              'canlifal_diagnostic.log — gerçek cihaz kullanımını kaydeder. '
              'Mock/integration testleri ayrı kalır.',
            ),
            value: fileOn,
            onChanged: (v) => unawaited(CfDiagnosticLogger.setFileLogging(v)),
          ),
        ),
        FilledButton.icon(
          onPressed: _exporting
              ? null
              : () async {
                  setState(() => _exporting = true);
                  final err = await CfDiagnosticExport.exportAndShare();
                  if (mounted && err != null) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(err)));
                  }
                  if (mounted) setState(() => _exporting = false);
                },
          icon: _exporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.upload_file_rounded),
          label: const Text('LOGU DIŞA AKTAR (ZIP)'),
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<bool>(
          valueListenable: CfDiag.verbose,
          builder: (context, on, _) => SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Ayrıntılı izleme (kare / donma)'),
            value: on,
            onChanged: (v) {
              unawaited(CfDiag.setVerbose(v));
              CfMonitors.init();
            },
          ),
        ),
      ],
    );
  }

  Widget _combinedErrorsTab() {
    final fileErrs = CfDiagnosticLogger.errors.reversed.take(40).toList();
    final diagErrs = CfDiag.entries
        .where((e) => e.level == CfLevel.error)
        .toList()
        .reversed
        .take(40)
        .toList();
    if (fileErrs.isEmpty && diagErrs.isEmpty) {
      return const Center(child: Text('Hata kaydı yok.'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (fileErrs.isNotEmpty) ...[
          const Text('Dosya logger', style: TextStyle(fontWeight: FontWeight.w800)),
          for (final e in fileErrs)
            Text(
              '${e['at']} [${e['level']}] ${e['message']}',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          const Divider(height: 24),
        ],
        const Text('CfDiag', style: TextStyle(fontWeight: FontWeight.w800)),
        for (final e in diagErrs) _entryText(e),
      ],
    );
  }

  Widget _fileCategoryTab(CfFileLogCategory cat) {
    final events = CfDiagnosticLogger.recentEvents
        .where((e) => e['category'] == cat.name)
        .toList()
        .reversed
        .toList();
    final diag = CfDiag.byCategories(_cfCategoriesFor(cat)).reversed.take(30);
    if (events.isEmpty && diag.isEmpty) {
      return Center(child: Text('${cat.name} kaydı yok.'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (events.isNotEmpty) ...[
          const Text('Dosya (son olaylar)', style: TextStyle(fontWeight: FontWeight.w800)),
          for (final e in events)
            Text('${e['at']} [${e['level']}] ${e['message']}',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
          const Divider(height: 16),
        ],
        for (final e in diag) _entryText(e),
      ],
    );
  }

  Set<CfCategory> _cfCategoriesFor(CfFileLogCategory cat) => switch (cat) {
        CfFileLogCategory.timer || CfFileLogCategory.polling => {CfCategory.ui},
        CfFileLogCategory.request => {CfCategory.network},
        CfFileLogCategory.sse => {CfCategory.sse},
        CfFileLogCategory.trtc => {CfCategory.trtc},
        _ => {CfCategory.unknown},
      };

  Widget _freezeTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Donma: ${CfFreezeWatchdog.freezeCount} · en uzun: '
          '${CfFreezeWatchdog.worstFreezeMs} ms\n'
          'Jank: ${CfFrameMonitor.stats.janky} · en kötü kare: '
          '${CfFrameMonitor.stats.worstMs} ms',
        ),
        const Divider(height: 16),
        ...CfDiagnosticLogger.recentEvents
            .where((e) => e['level'] == 'freeze' || e['level'] == 'warning')
            .map(
              (e) => Text('${e['at']} ${e['message']}',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
            ),
        const Divider(height: 16),
        for (final e
            in CfDiag.byCategories({CfCategory.ui}).reversed.take(25))
          _entryText(e),
      ],
    );
  }

  Widget _resourcesTab() {
    final snap = CfResourceTracker.snapshot();
    final records = snap.activeRecords;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'timers=${snap.activeTimers} pollers=${snap.activePollers} '
          'sse=${snap.activeSse} trtc=${snap.activeTrtc} '
          'requests=${snap.activeRequests} subscriptions=${snap.activeSubscriptions}',
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
        const Divider(height: 16),
        if (records.isEmpty) const Text('Aktif kaynak yok.'),
        for (final r in records)
          Text(
            '${r.kind.name} ${r.id} · ${r.module} · ${r.label}',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
          ),
      ],
    );
  }

  Widget _diagnosticsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(
          onPressed: _running ? null : _run,
          icon: _running
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.health_and_safety_rounded),
          label: Text(_running ? 'Kontrol ediliyor…' : 'Kendi kendine tanıyı çalıştır'),
        ),
        const SizedBox(height: 16),
        if (_results.isEmpty && !_running)
          const Text('Henüz çalıştırılmadı.'),
        for (final r in _results) _resultTile(r),
        if (_results.isNotEmpty)
          TextButton.icon(
            onPressed: () => unawaited(Clipboard.setData(
              ClipboardData(text: _results.map(_resultLine).join('\n')),
            )),
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Sonucu kopyala'),
          ),
      ],
    );
  }

  static String _icon(CfCheckStatus s) => switch (s) {
        CfCheckStatus.ok => '✓',
        CfCheckStatus.warn => '⚠',
        CfCheckStatus.fail => '✗',
        CfCheckStatus.skip => '–',
      };

  static String _resultLine(CfCheckResult r) =>
      '${_icon(r.status)} ${r.name}${r.detail.isEmpty ? '' : ': ${r.detail}'}';

  Widget _resultTile(CfCheckResult r) {
    final color = switch (r.status) {
      CfCheckStatus.ok => Colors.greenAccent,
      CfCheckStatus.warn => Colors.amberAccent,
      CfCheckStatus.fail => Colors.redAccent,
      CfCheckStatus.skip => Colors.grey,
    };
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Text(
        _icon(r.status),
        style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800),
      ),
      title: Text(r.name),
      subtitle: r.detail.isEmpty ? null : Text(r.detail),
      trailing: Text('${r.ms} ms'),
    );
  }

  Widget _networkTab() {
    final items = AppPerfMetrics.slowest(limit: 40, group: 'api');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('En yavaş API çağrıları', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        if (items.isEmpty) const Text('Henüz ölçüm yok.'),
        for (final e in items)
          Text('${e.durationMs} ms  ${e.name}${e.statusCode != null ? '  (${e.statusCode})' : ''}',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        const SizedBox(height: 8),
        const Text('Bekleyen işlemler', style: TextStyle(fontWeight: FontWeight.w800)),
        for (final p in CfDiag.pendingOps) Text(p),
      ],
    );
  }

  Widget _logTab(Set<CfCategory> cats) {
    final list = CfDiag.byCategories(cats).reversed.toList();
    if (list.isEmpty) return const Center(child: Text('Kayıt yok.'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (_, i) => _entryText(list[i]),
    );
  }

  Widget _entryText(CfDiagEntry e) {
    final extra = e.data.isEmpty
        ? ''
        : '\n  ${e.data.entries.map((x) => '${x.key}=${x.value}').join('  ')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        '${_time(e.at)} [${e.category.label}]'
        '${e.traceId != null ? ' ${e.traceId}' : ''} ${e.message}$extra',
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      ),
    );
  }

  static String _time(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:'
      '${t.second.toString().padLeft(2, '0')}';
}
