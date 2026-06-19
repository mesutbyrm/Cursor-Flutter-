/// Canlı fal isteği / oturum durumu (üretim API ile uyumlu).
enum PsychicSessionStatus {
  pending,
  accepted,
  active,
  rejected,
  expired,
  ended,
  cancelled;

  static PsychicSessionStatus fromApi(String? raw, {String? tellerResponse}) {
    final status = (raw ?? '').toLowerCase();
    final response = (tellerResponse ?? '').toLowerCase();
    if (response == 'accepted' || status == 'active' || status == 'accepted') {
      return PsychicSessionStatus.active;
    }
    if (response == 'rejected' ||
        response == 'declined' ||
        status == 'rejected' ||
        status == 'declined') {
      return PsychicSessionStatus.rejected;
    }
    if (status == 'ended' || status == 'completed') {
      return PsychicSessionStatus.ended;
    }
    if (status == 'cancelled' || status == 'canceled') {
      return PsychicSessionStatus.cancelled;
    }
    if (status == 'expired' || status == 'timeout') {
      return PsychicSessionStatus.expired;
    }
    return PsychicSessionStatus.pending;
  }

  bool get isWaiting => this == PsychicSessionStatus.pending;
  bool get isActive =>
      this == PsychicSessionStatus.active || this == PsychicSessionStatus.accepted;
  bool get isTerminal =>
      this == PsychicSessionStatus.rejected ||
      this == PsychicSessionStatus.ended ||
      this == PsychicSessionStatus.cancelled ||
      this == PsychicSessionStatus.expired;
}
