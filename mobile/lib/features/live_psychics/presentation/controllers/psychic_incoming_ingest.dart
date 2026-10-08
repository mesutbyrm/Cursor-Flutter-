import '../../domain/entities/psychic_request_entity.dart';
import '../../domain/entities/psychic_session_status.dart';

/// Gelen canlı fal isteğinin kaynağı (SSE doğrudan; bus yalnızca harici).
enum PsychicIncomingRequestSource {
  sse,
  eventBus,
  poll,
}

/// Tek sessionId için tekrarlayan ingestion (SSE + poll + bus) engeli.
class PsychicIncomingIngestGate {
  final Set<String> _acceptedSessionIds = {};

  bool hasAccepted(String sessionId) {
    final id = sessionId.trim();
    return id.isNotEmpty && _acceptedSessionIds.contains(id);
  }

  /// `true` — bu sessionId ilk kez pipeline'a alınabilir.
  bool tryAcceptForIngest(String sessionId) {
    final id = sessionId.trim();
    if (id.isEmpty) return false;
    return _acceptedSessionIds.add(id);
  }

  void forget(String sessionId) {
    _acceptedSessionIds.remove(sessionId.trim());
  }

  void clear() => _acceptedSessionIds.clear();
}

/// Ingestion öncesi saf kontroller (widget/ref bağımsız test).
class PsychicIncomingIngestDecision {
  const PsychicIncomingIngestDecision._({
    required this.accept,
    required this.reason,
  });

  final bool accept;
  final String reason;

  static PsychicIncomingIngestDecision evaluate({
    required PsychicRequestEntity request,
    required PsychicIncomingIngestGate gate,
    required bool alreadyQueued,
    required bool dismissed,
    required bool presentingThisSession,
  }) {
    final sessionId = request.sessionId.trim();
    if (sessionId.isEmpty) {
      return const PsychicIncomingIngestDecision._(
        accept: false,
        reason: 'empty_session_id',
      );
    }
    if (!request.isPending) {
      return const PsychicIncomingIngestDecision._(
        accept: false,
        reason: 'not_pending',
      );
    }
    final status = request.status;
    if (status == PsychicSessionStatus.rejected ||
        status == PsychicSessionStatus.cancelled ||
        status == PsychicSessionStatus.expired ||
        status == PsychicSessionStatus.ended) {
      return const PsychicIncomingIngestDecision._(
        accept: false,
        reason: 'terminal_status',
      );
    }
    if (dismissed) {
      return const PsychicIncomingIngestDecision._(
        accept: false,
        reason: 'dismissed',
      );
    }
    if (presentingThisSession) {
      return const PsychicIncomingIngestDecision._(
        accept: false,
        reason: 'already_presenting',
      );
    }
    if (alreadyQueued || gate.hasAccepted(sessionId)) {
      return const PsychicIncomingIngestDecision._(
        accept: false,
        reason: 'duplicate',
      );
    }
    if (!gate.tryAcceptForIngest(sessionId)) {
      return const PsychicIncomingIngestDecision._(
        accept: false,
        reason: 'duplicate',
      );
    }
    return const PsychicIncomingIngestDecision._(
      accept: true,
      reason: 'accepted',
    );
  }
}
