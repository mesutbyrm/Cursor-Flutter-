import '../entities/live_stream_entity.dart';
import 'live_discover_category.dart';

/// Kategori bazlı keşfet sıralaması — fal yayınları öne çıkar.
List<LiveStreamEntity> rankLiveStreamsForDiscover({
  required List<LiveStreamEntity> streams,
  required LiveDiscoverCategory filter,
  LiveDiscoverCategory? userAffinity,
}) {
  if (streams.isEmpty) return streams;

  final affinity = userAffinity ?? filter;
  final scored = streams.map((s) {
    var score = s.viewerCount.toDouble();
    if (s.isLive) score += 50;
    if (s.isPkLive) score += 30;
    if (s.isVipHost) score += 20;

    final cat = (s.category ?? '').toLowerCase();
    final title = s.title.toLowerCase();
    final tags = s.tags.map((t) => t.toLowerCase()).join(' ');

    bool matches(LiveDiscoverCategory c) {
      if (c == LiveDiscoverCategory.all) return true;
      final api = c.apiCategory;
      if (api != null && cat.contains(api)) return true;
      return c.keywords.any(
        (k) => title.contains(k) || tags.contains(k) || cat.contains(k),
      );
    }

    if (filter != LiveDiscoverCategory.all && !matches(filter)) {
      score -= 1000;
    }

    if (affinity.isFortuneFamily) {
      if (cat.contains('fortune') || cat.contains('fal')) score += 80;
      if (matches(affinity)) score += 120;
      if (cat == 'chat' || cat == 'game' || cat == 'general') score -= 40;
    }

    return (s, score);
  }).toList();

  scored.sort((a, b) => b.$2.compareTo(a.$2));
  return scored.map((e) => e.$1).where((s) {
    if (filter == LiveDiscoverCategory.all) return true;
    final cat = (s.category ?? '').toLowerCase();
    final title = s.title.toLowerCase();
    final tags = s.tags.map((t) => t.toLowerCase()).join(' ');
    if (filter.apiCategory != null && cat.contains(filter.apiCategory!)) {
      return true;
    }
    return filter.keywords.any(
      (k) => title.contains(k) || tags.contains(k) || cat.contains(k),
    );
  }).toList();
}
