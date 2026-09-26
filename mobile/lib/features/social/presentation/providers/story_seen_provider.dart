import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/social_story_ring_entity.dart';

/// Bu cihazda izlenen hikâye kimlikleri — backend "görüldü" bilgisi vermiyor.
final storySeenProvider = NotifierProvider<StorySeenNotifier, Set<String>>(
  StorySeenNotifier.new,
);

class StorySeenNotifier extends Notifier<Set<String>> {
  static const prefsKey = 'social_story_seen_v1';
  static const maxEntries = 600;

  List<String> _order = const [];

  @override
  Set<String> build() {
    unawaited(_load());
    return const {};
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(prefsKey) ?? const [];
      // Yükleme sırasında işaretlenenler kaybolmasın.
      _order = [...stored.where((id) => !state.contains(id)), ..._order];
      state = {..._order};
    } catch (_) {}
  }

  void markSeen(String storyId) {
    if (storyId.isEmpty || state.contains(storyId)) return;
    var next = [..._order, storyId];
    if (next.length > maxEntries) next = next.sublist(next.length - maxEntries);
    _order = next;
    state = {...next};
    unawaited(_persist(next));
  }

  Future<void> _persist(List<String> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(prefsKey, ids);
    } catch (_) {}
  }
}

/// Halkadaki tüm hikâyeler izlendiyse true. Hikâye listesi boşsa izlenmemiş sayılır.
bool isStoryRingSeen(SocialStoryRingEntity ring, Set<String> seen) {
  if (ring.stories.isEmpty) return false;
  return ring.stories.every((s) => seen.contains(s.id));
}

/// İzlenmemiş halkalar önde; kendi içinde sunucu sırası korunur.
List<SocialStoryRingEntity> sortRingsUnseenFirst(
  List<SocialStoryRingEntity> rings,
  Set<String> seen,
) {
  final unseen = <SocialStoryRingEntity>[];
  final seenRings = <SocialStoryRingEntity>[];
  for (final r in rings) {
    (isStoryRingSeen(r, seen) ? seenRings : unseen).add(r);
  }
  return [...unseen, ...seenRings];
}
