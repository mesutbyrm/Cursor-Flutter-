import '../config/env.dart';

/// `/api/animations/resolve` ve `/api/animations/manifest` tek animasyon yükü.
///
/// Kaynak: backend `AnimationPayload` (merkezi çözümleyici). `assetUrl`
/// göreli (`/cosmetics/...`) olabilir → [resolvedAssetUrl] siteye tamamlar.
class AnimationPayload {
  const AnimationPayload({
    required this.animationId,
    required this.category,
    required this.type,
    required this.assetUrl,
    this.slug,
    this.thumbnailUrl,
    this.soundUrl,
    this.durationMs = 3000,
    this.position = 'center',
    this.scale = 'medium',
    this.anchor = 'user',
    this.priority = 10,
    this.canSkip = true,
    this.cooldownMs = 0,
    this.source = '',
  });

  factory AnimationPayload.fromJson(Map<String, dynamic> j) {
    String s(Object? v, [String d = '']) => v?.toString() ?? d;
    int i(Object? v, int d) => v is num ? v.toInt() : int.tryParse('$v') ?? d;
    return AnimationPayload(
      animationId: s(j['animationId'] ?? j['id']),
      slug: j['slug']?.toString(),
      category: s(j['category']),
      type: s(j['type'], 'image').toLowerCase(),
      assetUrl: s(j['assetUrl']),
      thumbnailUrl: j['thumbnailUrl']?.toString(),
      soundUrl: j['soundUrl']?.toString(),
      durationMs: i(j['durationMs'], 3000),
      position: s(j['position'], 'center'),
      scale: s(j['scale'], 'medium'),
      anchor: s(j['anchor'], 'user'),
      priority: i(j['priority'], 10),
      canSkip: j['canSkip'] is bool ? j['canSkip'] as bool : true,
      cooldownMs: i(j['cooldownMs'], 0),
      source: s(j['source']),
    );
  }

  final String animationId;
  final String? slug;
  final String category;
  final String type;
  final String assetUrl;
  final String? thumbnailUrl;
  final String? soundUrl;
  final int durationMs;
  final String position;
  final String scale;
  final String anchor;
  final int priority;
  final bool canSkip;
  final int cooldownMs;
  final String source;

  static String absoluteUrl(String? raw) {
    final u = raw?.trim() ?? '';
    if (u.isEmpty) return '';
    if (u.startsWith('http://') || u.startsWith('https://')) return u;
    final origin = Env.siteOrigin;
    return u.startsWith('/') ? '$origin$u' : '$origin/$u';
  }

  String get resolvedAssetUrl => absoluteUrl(assetUrl);
  String? get resolvedSoundUrl {
    final u = absoluteUrl(soundUrl);
    return u.isEmpty ? null : u;
  }

  bool get isSvg => resolvedAssetUrl.toLowerCase().split('?').first.endsWith('.svg');

  /// Ölçek sözlüğü → çarpan (`small|medium|large`).
  double get scaleFactor => switch (scale) {
        'small' => 0.7,
        'large' => 1.25,
        _ => 1.0,
      };
}
