import 'dart:async';

/// Kontrol sonucu durumu.
enum CfCheckStatus { ok, warn, fail, skip }

class CfCheckOutcome {
  const CfCheckOutcome(this.status, [this.detail = '']);
  const CfCheckOutcome.ok([String detail = '']) : this(CfCheckStatus.ok, detail);
  const CfCheckOutcome.warn(String detail) : this(CfCheckStatus.warn, detail);
  const CfCheckOutcome.fail(String detail) : this(CfCheckStatus.fail, detail);
  const CfCheckOutcome.skip(String detail) : this(CfCheckStatus.skip, detail);

  final CfCheckStatus status;
  final String detail;

  /// Gecikmeye göre durum: [warnMs] üstü uyarı, [failMs] üstü hata.
  factory CfCheckOutcome.latency(
    int ms, {
    String label = '',
    int warnMs = 1500,
    int failMs = 6000,
  }) {
    final text = '${label.isEmpty ? '' : '$label '}$ms ms';
    if (ms >= failMs) return CfCheckOutcome.fail('çok yavaş: $text');
    if (ms >= warnMs) return CfCheckOutcome.warn('yavaş: $text');
    return CfCheckOutcome.ok(text);
  }
}

class CfCheckSpec {
  const CfCheckSpec(
    this.name,
    this.run, {
    this.timeout = const Duration(seconds: 12),
  });

  final String name;
  final Future<CfCheckOutcome> Function() run;
  final Duration timeout;
}

class CfCheckResult {
  const CfCheckResult(this.name, this.status, this.detail, this.ms);
  final String name;
  final CfCheckStatus status;
  final String detail;
  final int ms;
}

/// Kontrolleri sırayla çalıştırır; her biri zaman aşımı ve hata yakalama ile
/// sarılıdır — bir kontrol tüm taramayı asla takıp bırakamaz.
abstract final class CfCheckRunner {
  static Future<CfCheckResult> runOne(CfCheckSpec spec) async {
    final sw = Stopwatch()..start();
    try {
      final out = await spec.run().timeout(spec.timeout);
      return CfCheckResult(spec.name, out.status, out.detail, sw.elapsedMilliseconds);
    } on TimeoutException {
      return CfCheckResult(
        spec.name,
        CfCheckStatus.fail,
        'zaman aşımı (${spec.timeout.inSeconds} sn)',
        sw.elapsedMilliseconds,
      );
    } catch (e) {
      return CfCheckResult(
        spec.name,
        CfCheckStatus.fail,
        _safeMessage(e),
        sw.elapsedMilliseconds,
      );
    }
  }

  static Future<List<CfCheckResult>> runAll(
    List<CfCheckSpec> specs, {
    void Function(CfCheckResult result)? onResult,
    bool Function()? isCancelled,
  }) async {
    final results = <CfCheckResult>[];
    for (final spec in specs) {
      if (isCancelled?.call() == true) break;
      final r = await runOne(spec);
      results.add(r);
      onResult?.call(r);
    }
    return results;
  }

  /// Hata metni: token/JWT sızdırmaz, kısa tutulur.
  static String _safeMessage(Object e) {
    var t = e.toString();
    t = t.replaceAll(RegExp(r'eyJ[A-Za-z0-9_-]{6,}\.[A-Za-z0-9_-]{6,}[A-Za-z0-9._-]*'), '[jwt]');
    t = t.replaceAll(RegExp(r'bearer\s+\S+', caseSensitive: false), 'Bearer [x]');
    return t.length > 160 ? '${t.substring(0, 160)}…' : t;
  }
}
