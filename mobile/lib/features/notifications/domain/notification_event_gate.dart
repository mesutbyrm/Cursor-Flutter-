import 'package:shared_preferences/shared_preferences.dart';

/// Oturum ve kalıcı düzeyde bildirim olayı tekrarını engeller.
///
/// - İlk REST/SSE batch geçmişi popup olarak oynatılmaz ([seedFromHistory]).
/// - Aynı [eventId] oturumda yalnızca bir kez işlenir.
/// - Dialog gösterilen jeton ödeme bildirimleri kullanıcı bazında kalıcı saklanır.
class NotificationEventGate {
  NotificationEventGate({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;
  final _sessionSeen = <String>{};
  var _historySeeded = false;
  DateTime? _sessionStartedAt;

  static const _prefsPrefix = 'notif_dialog_shown_v1_';

  void markSessionStart() {
    _sessionStartedAt = DateTime.now();
    _historySeeded = false;
    _sessionSeen.clear();
  }

  /// İlk tam liste yüklemesinde mevcut kayıtları "görüldü" say — popup yok.
  void seedFromHistory(Iterable<String> ids) {
    if (_historySeeded) return;
    _historySeeded = true;
    for (final id in ids) {
      final key = id.trim();
      if (key.isNotEmpty) _sessionSeen.add(key);
    }
  }

  /// Gerçek zamanlı (SSE/push) olay — yalnızca oturumda ilk kez işlenir.
  bool shouldProcessRealtime(String eventId) {
    final key = eventId.trim();
    if (key.isEmpty) return false;
    return _sessionSeen.add(key);
  }

  /// Geçmiş listeden popup: yalnızca okunmamış + oturum başlangıcından sonra oluşmuş.
  bool shouldShowHistoricalPopup({
    required String eventId,
    required bool isRead,
    DateTime? createdAt,
  }) {
    final key = eventId.trim();
    if (key.isEmpty) return false;
    if (_sessionSeen.contains(key)) return false;
    if (isRead) {
      _sessionSeen.add(key);
      return false;
    }
    final started = _sessionStartedAt;
    if (started != null && createdAt != null && createdAt.isBefore(started)) {
      _sessionSeen.add(key);
      return false;
    }
    return _sessionSeen.add(key);
  }

  Future<bool> wasDialogShownPersisted({
    required String userId,
    required String eventId,
  }) async {
    final uid = userId.trim();
    final id = eventId.trim();
    if (uid.isEmpty || id.isEmpty) return false;
    final prefs = await _ensurePrefs();
    return prefs.getBool('$_prefsPrefix$uid::$id') ?? false;
  }

  Future<void> markDialogShownPersisted({
    required String userId,
    required String eventId,
  }) async {
    final uid = userId.trim();
    final id = eventId.trim();
    if (uid.isEmpty || id.isEmpty) return;
    final prefs = await _ensurePrefs();
    await prefs.setBool('$_prefsPrefix$uid::$id', true);
  }

  Future<SharedPreferences> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }
}
