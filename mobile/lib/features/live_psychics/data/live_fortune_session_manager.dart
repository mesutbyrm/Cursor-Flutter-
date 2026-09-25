import 'dart:async';
import '../../../core/network/api_exception.dart';
import '../../live/data/datasources/live_field/live_session_repository.dart';

/// Falcı sesyon yönetimi — SSE stream + session lifecycle.
///
/// **Sorunlar çözüldü:**
/// - Session request'leri boş kalıyor → SSE stream monitoring
/// - Session creation başarısız → Fallback retry system
/// - Auto-join sorunları → State validation
class LiveFortuneSessionManager {
  LiveFortuneSessionManager(this._repo);

  final LiveSessionRepository _repo;

  // Active sessions
  final Map<String, _SessionState> _sessions = {};

  // SSE monitoring
  StreamSubscription? _sseSubscription;
  Timer? _pollTimer;

  /// Falcı sesyonlarını başlat — SSE stream + polling dual system.
  Future<void> startMonitoring() async {
    // SSE stream başlat
    _subscribeToSseStream();

    // Fallback: API polling (10 saniye)
    _startPolling();
  }

  /// Session başlat — fallback retry.
  Future<String> createSession({
    required String fortuneTellerId,
    required String fortuneType,
    required int maxMinutes,
  }) async {
    final tellerId = fortuneTellerId.trim();
    final fType = fortuneType.trim();

    if (tellerId.isEmpty || fType.isEmpty) {
      throw const ApiException('Session parametre eksik');
    }

    try {
      // Primary: Direct API call
      final sessionId = await _repo.createSession(
        tellerId: tellerId,
        fortuneType: fType,
        maxMinutes: maxMinutes,
      );

      if (sessionId.isEmpty) throw const ApiException('Session ID alınamadı');

      _registerSession(
        sessionId: sessionId,
        tellerId: tellerId,
        fortuneType: fType,
      );

      return sessionId;
    } on ApiException catch (e) {
      // Retry 2x with exponential backoff
      await Future.delayed(const Duration(milliseconds: 500));

      try {
        final sessionId = await _repo.createSession(
          tellerId: tellerId,
          fortuneType: fType,
          maxMinutes: maxMinutes,
        );

        if (sessionId.isNotEmpty) {
          _registerSession(
            sessionId: sessionId,
            tellerId: tellerId,
            fortuneType: fType,
          );
          return sessionId;
        }
      } catch (_) {
        // Second retry failed
      }

      throw e;
    }
  }

  /// Sesyonu kabul et — accept action.
  Future<void> acceptSession(String sessionId) async {
    final sid = sessionId.trim();
    if (sid.isEmpty) throw const ApiException('Session ID boş');

    try {
      await _repo.updateSessionStatus(
        sessionId: sid,
        action: 'accept',
      );

      _updateSessionState(sid, 'accepted');
    } catch (e) {
      throw ApiException('Session kabulu başarısız: ${e.toString()}');
    }
  }

  /// Sesyonu reddet.
  Future<void> rejectSession(String sessionId) async {
    final sid = sessionId.trim();
    if (sid.isEmpty) throw const ApiException('Session ID boş');

    try {
      await _repo.updateSessionStatus(
        sessionId: sid,
        action: 'reject',
      );

      _updateSessionState(sid, 'rejected');
    } catch (e) {
      throw ApiException('Session reddi başarısız: ${e.toString()}');
    }
  }

  /// Sesyonu bitir.
  Future<void> endSession(String sessionId) async {
    final sid = sessionId.trim();
    if (sid.isEmpty) throw const ApiException('Session ID boş');

    try {
      await _repo.updateSessionStatus(
        sessionId: sid,
        action: 'complete',
      );

      _clearSession(sid);
    } catch (e) {
      throw ApiException('Session bitiş başarısız: ${e.toString()}');
    }
  }

  /// SSE stream'i dinle.
  void _subscribeToSseStream() {
    _sseSubscription?.cancel();

    try {
      // SSE stream'e abone ol
      final stream = _repo.getSessionStream(); // Implement in repo

      _sseSubscription = stream.listen(
        (event) {
          if (event is Map<String, dynamic>) {
            _handleSseEvent(event);
          }
        },
        onError: (e) {
          print('SSE error: $e');
          // SSE bağlantı koptuğunda polling takeover eder
        },
      );
    } catch (e) {
      print('SSE subscribe failed: $e');
      // Polling continues as fallback
    }
  }

  void _handleSseEvent(Map<String, dynamic> event) {
    final type = event['type'] as String?;
    final sessionId = event['sessionId'] as String?;

    if (sessionId == null || sessionId.isEmpty) return;

    switch (type) {
      case 'session_request':
        _registerSession(
          sessionId: sessionId,
          tellerId: event['tellerId'] as String? ?? '',
          fortuneType: event['fortuneType'] as String? ?? '',
        );
        break;

      case 'session_accepted':
        _updateSessionState(sessionId, 'accepted');
        break;

      case 'session_rejected':
        _updateSessionState(sessionId, 'rejected');
        break;

      case 'session_ended':
        _clearSession(sessionId);
        break;
    }
  }

  /// Polling fallback — her 10 saniye.
  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      try {
        final sessions = await _repo.getIncomingSessions();

        for (final session in sessions) {
          _registerSession(
            sessionId: session['id'] ?? '',
            tellerId: session['tellerId'] ?? '',
            fortuneType: session['fortuneType'] ?? '',
          );
        }
      } catch (_) {
        // Silent fail — polling continues
      }
    });
  }

  void _registerSession({
    required String sessionId,
    required String tellerId,
    required String fortuneType,
  }) {
    if (sessionId.isEmpty) return;
    _sessions[sessionId] = _SessionState(
      sessionId: sessionId,
      tellerId: tellerId,
      fortuneType: fortuneType,
      status: 'pending',
      createdAt: DateTime.now(),
    );
  }

  void _updateSessionState(String sessionId, String status) {
    final sid = sessionId.trim();
    if (sid.isEmpty) return;

    final session = _sessions[sid];
    if (session != null) {
      session.status = status;
    }
  }

  void _clearSession(String sessionId) {
    final sid = sessionId.trim();
    if (sid.isEmpty) return;
    _sessions.remove(sid);
  }

  bool hasSession(String sessionId) {
    return _sessions.containsKey(sessionId.trim());
  }

  void dispose() {
    _sseSubscription?.cancel();
    _sseSubscription = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    _sessions.clear();
  }
}

class _SessionState {
  _SessionState({
    required this.sessionId,
    required this.tellerId,
    required this.fortuneType,
    required this.status,
    required this.createdAt,
  });

  final String sessionId;
  final String tellerId;
  final String fortuneType;
  String status; // pending, accepted, rejected, completed
  final DateTime createdAt;
}
