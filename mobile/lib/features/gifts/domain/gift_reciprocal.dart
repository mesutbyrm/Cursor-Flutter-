import '../../../core/util/json_util.dart';

/// Kılavuz §9.9 `GET /api/gifts/check-reciprocal` yanıtı.
class ReciprocalGiftHint {
  const ReciprocalGiftHint({required this.isMutual, this.message});

  final bool isMutual;
  final String? message;

  bool get show => isMutual || (message != null && message!.trim().isNotEmpty);
}

ReciprocalGiftHint parseReciprocalGiftHint(dynamic body) {
  Map<String, dynamic> map;
  if (body is Map) {
    map = asJsonMap(body);
    if (map['data'] is Map) map = asJsonMap(map['data']);
  } else {
    return const ReciprocalGiftHint(isMutual: false);
  }
  final mutual = asBool(
    pick(map, ['reciprocal', 'isReciprocal', 'mutual', 'isMutual']),
  );
  final raw = jsonDisplayLabel(pick(map, ['message', 'hint', 'text', 'label']));
  final message = raw != null && raw.trim().isNotEmpty
      ? raw.trim()
      : (mutual ? 'Karşılıklı hediye geçmişiniz var' : null);
  return ReciprocalGiftHint(isMutual: mutual, message: message);
}
