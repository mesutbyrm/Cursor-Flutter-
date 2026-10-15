import 'dart:convert';
import 'dart:ui';

import 'package:equatable/equatable.dart';

enum CosmeticNameStyleMode { solid, gradient, glow, outline, shine }

/// Sitedeki isim efekti (`NameEffect.cssPreset`) → uygulama stili.
///
/// Sunucu CSS nesnesi döndürür, ör.
/// `{"backgroundImage":"linear-gradient(90deg,#FDE68A,#F59E0B,#B45309)",
///   "WebkitBackgroundClip":"text","color":"transparent"}`,
/// `{"color":"#FDE68A","textShadow":"0 0 6px #F59E0B, 0 0 14px #F59E0B"}`,
/// `{"color":"#E9D5FF","WebkitTextStroke":"1px #6D28D9"}`,
/// `{..., "animation":"cfShine 2.8s linear infinite"}`.
/// Eski biçim `{"gradient":[..],"animation":"shine"}` da desteklenir.
class CosmeticNameStyle extends Equatable {
  const CosmeticNameStyle({
    required this.mode,
    required this.colors,
    this.accent,
    this.periodMs = 2800,
  });

  final CosmeticNameStyleMode mode;

  /// solid/glow/outline: [0] yazı rengi; gradient/shine: geçiş durakları.
  final List<Color> colors;

  /// glow: parlama rengi; outline: kontur rengi.
  final Color? accent;
  final int periodMs;

  static final _hex = RegExp(r'#([0-9a-fA-F]{8}|[0-9a-fA-F]{6}|[0-9a-fA-F]{3})\b');
  static final _rgb = RegExp(r'rgba?\(([^)]+)\)');

  static List<Color> colorsIn(String? css) {
    if (css == null || css.isEmpty) return const [];
    final out = <({int at, Color c})>[];
    for (final m in _hex.allMatches(css)) {
      final c = parseColor(m.group(0));
      if (c != null) out.add((at: m.start, c: c));
    }
    for (final m in _rgb.allMatches(css)) {
      final parts = m.group(1)!.split(',').map((e) => e.trim()).toList();
      if (parts.length < 3) continue;
      final r = int.tryParse(parts[0]), g = int.tryParse(parts[1]), b = int.tryParse(parts[2]);
      if (r == null || g == null || b == null) continue;
      final a = parts.length > 3 ? (double.tryParse(parts[3]) ?? 1) : 1.0;
      out.add((at: m.start, c: Color.fromARGB((a * 255).round(), r, g, b)));
    }
    out.sort((a, b) => a.at.compareTo(b.at));
    return [for (final e in out) e.c];
  }

  static Color? parseColor(String? raw) {
    if (raw == null) return null;
    var h = raw.trim().replaceAll('#', '');
    if (h.length == 3) h = h.split('').map((c) => '$c$c').join();
    if (h.length == 6) h = 'FF$h';
    if (h.length != 8) return null;
    final v = int.tryParse(h, radix: 16);
    return v == null ? null : Color(v);
  }

  static CosmeticNameStyle? parse(Object? raw) {
    Map<String, dynamic>? m;
    if (raw is Map) {
      m = raw.map((k, v) => MapEntry(k.toString(), v));
    } else if (raw is String && raw.trim().startsWith('{')) {
      try {
        final d = jsonDecode(raw);
        if (d is Map) m = d.map((k, v) => MapEntry(k.toString(), v));
      } catch (_) {}
    }
    if (m == null || m.isEmpty) return null;

    String? s(String k) => m![k]?.toString();
    final anim = (s('animation') ?? '').toLowerCase();
    final isShine = anim.contains('shine');
    final periodMatch = RegExp(r'([\d.]+)s').firstMatch(anim);
    final period = periodMatch != null
        ? ((double.tryParse(periodMatch.group(1)!) ?? 2.8) * 1000).round()
        : 2800;

    // Eski biçim: {"gradient":[...], "animation":"shine"}
    final legacy = m['gradient'] ?? m['colors'];
    if (legacy is List && legacy.isNotEmpty) {
      final cs = legacy.map((e) => parseColor(e?.toString())).whereType<Color>().toList();
      if (cs.isNotEmpty) {
        return CosmeticNameStyle(
          mode: isShine ? CosmeticNameStyleMode.shine : CosmeticNameStyleMode.gradient,
          colors: cs.length == 1 ? [cs.first, cs.first] : cs,
          periodMs: period,
        );
      }
    }

    final bg = s('backgroundImage') ?? s('background') ?? s('backgroundimage');
    if (bg != null && bg.contains('gradient')) {
      final cs = colorsIn(bg);
      if (cs.isNotEmpty) {
        return CosmeticNameStyle(
          mode: isShine ? CosmeticNameStyleMode.shine : CosmeticNameStyleMode.gradient,
          colors: cs.length == 1 ? [cs.first, cs.first] : cs,
          periodMs: period,
        );
      }
    }
    final color = parseColor(s('color'));
    final shadow = colorsIn(s('textShadow'));
    if (shadow.isNotEmpty) {
      return CosmeticNameStyle(
        mode: CosmeticNameStyleMode.glow,
        colors: [color ?? const Color(0xFFFFFFFF)],
        accent: shadow.first,
      );
    }
    final stroke = colorsIn(s('WebkitTextStroke') ?? s('webkitTextStroke') ?? s('textStroke'));
    if (stroke.isNotEmpty) {
      return CosmeticNameStyle(
        mode: CosmeticNameStyleMode.outline,
        colors: [color ?? const Color(0xFFFFFFFF)],
        accent: stroke.first,
      );
    }
    if (color != null) {
      return CosmeticNameStyle(mode: CosmeticNameStyleMode.solid, colors: [color]);
    }
    return null;
  }

  @override
  List<Object?> get props => [mode, colors, accent, periodMs];
}
