import 'package:shared_preferences/shared_preferences.dart';

/// Kullanıcının kapattığı hediye hedefleri — (context, contextId, goalId).
abstract final class GiftGoalDismissStorage {
  static String _key(String context, String contextId) {
    final c = context.trim();
    final id = contextId.trim();
    return 'gift_goal_dismiss_${c}_$id';
  }

  static Future<Set<String>> readDismissedIds({
    required String context,
    required String contextId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key(context, contextId));
    if (list == null || list.isEmpty) return {};
    return list.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
  }

  static Future<bool> isDismissed({
    required String context,
    required String contextId,
    required String goalId,
  }) async {
    final id = goalId.trim();
    if (id.isEmpty) return false;
    final set = await readDismissedIds(context: context, contextId: contextId);
    return set.contains(id);
  }

  static Future<void> dismiss({
    required String context,
    required String contextId,
    required String goalId,
  }) async {
    final id = goalId.trim();
    if (id.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final key = _key(context, contextId);
    final set = await readDismissedIds(context: context, contextId: contextId);
    if (set.contains(id)) return;
    set.add(id);
    await prefs.setStringList(key, set.toList()..sort());
  }
}
