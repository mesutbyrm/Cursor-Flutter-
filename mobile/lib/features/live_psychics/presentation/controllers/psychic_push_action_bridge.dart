import 'package:canlifal_social/features/live_psychics/presentation/providers/psychic_push_payload.dart';

/// OneSignal bildirim aksiyonları (Kabul / Reddet) — arka planda API çağrısı.
typedef PsychicPushRespondCallback = Future<void> Function(
  String sessionId,
  String action,
  Map<String, dynamic> data,
);

class PsychicPushActionBridge {
  PsychicPushActionBridge._();

  static PsychicPushRespondCallback? onRespond;

  static const acceptActionIds = {'accept', 'kabul', 'kabul_et', 'psychic_accept'};
  static const rejectActionIds = {'reject', 'reddet', 'psychic_reject'};

  /// Bildirim aksiyon düğmesi veya deep link payload.
  static Future<bool> handle({
    String? actionId,
    Map<String, dynamic>? data,
  }) async {
    if (data == null || data.isEmpty) return false;
    final invite = parsePsychicIncomingLoose(data);
    final sessionId = invite?.sessionId ??
        data['sessionId']?.toString() ??
        data['session_id']?.toString() ??
        '';
    if (sessionId.isEmpty) return false;

    final normalized = (actionId ?? data['action'] ?? data['buttonAction'])
        ?.toString()
        .trim()
        .toLowerCase();
    if (normalized == null || normalized.isEmpty) return false;

    String? apiAction;
    if (acceptActionIds.contains(normalized)) {
      apiAction = 'accept';
    } else if (rejectActionIds.contains(normalized)) {
      apiAction = 'reject';
    }
    if (apiAction == null) return false;

    final handler = onRespond;
    if (handler == null) return false;
    await handler(sessionId, apiAction, data);
    return true;
  }
}
