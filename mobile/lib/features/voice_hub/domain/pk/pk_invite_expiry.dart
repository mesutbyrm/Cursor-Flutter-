import '../../../../core/network/api_exception.dart';

/// PK davet süresi — sunucu varsayılanı 60 sn.
const pkInviteTimeoutSeconds = 60;

const pkInviteExpiredMessage = 'PK isteği zaman aşımına uğradı';

const pkInviteExpiredApiHint = 'PK isteği zaman aşımına uğradı (60 saniye)';

/// PK davet / maç durumu — `expired` yeni değer.
bool isPkExpiredStatus(String? status) =>
    (status ?? '').trim().toLowerCase() == 'expired';

/// SSE / socket PK aksiyonları.
bool isPkExpiredAction(String? action) {
  final a = (action ?? '').trim().toLowerCase();
  return a == 'expired' || a == 'pk:expired' || a == 'pk_expired';
}

bool isPkInviteExpireApiError(Object error) {
  if (error is! ApiException) return false;
  if (error.statusCode != 400) return false;
  final msg = error.message.toLowerCase();
  return msg.contains('zaman aşım') ||
      msg.contains('timeout') ||
      msg.contains('expired') ||
      msg.contains('60 saniye');
}

/// Davet için kalan saniye — `expiresAt` öncelikli.
int pkInviteSecondsLeft({
  DateTime? expiresAt,
  int timeoutSeconds = pkInviteTimeoutSeconds,
}) {
  if (expiresAt != null) {
    final left = expiresAt.difference(DateTime.now()).inSeconds;
    return left < 0 ? 0 : left;
  }
  return timeoutSeconds > 0 ? timeoutSeconds : pkInviteTimeoutSeconds;
}

String pkInviteCountdownLabel(int secondsLeft) {
  final s = secondsLeft.clamp(0, 999);
  return '0:${s.toString().padLeft(2, '0')}';
}

DateTime? parsePkExpiresAt(dynamic raw) {
  if (raw == null) return null;
  return DateTime.tryParse(raw.toString());
}
