import 'entities/psychic_session_status.dart';
import 'repositories/live_psychics_repository.dart';

/// Danışan yeni randevu öncesi aktif/bekleyen seans kontrolü.
abstract final class PsychicClientSessionGuard {
  static bool blocksNewBooking(PsychicSessionStatus status) =>
      status.isWaiting || status.isActive;

  static PsychicSessionStatusResult? firstBlockingFromActive(
    List<PsychicSessionStatusResult> sessions,
  ) {
    for (final s in sessions) {
      if (!s.isClient) continue;
      if (blocksNewBooking(s.status)) return s;
    }
    return null;
  }
}
