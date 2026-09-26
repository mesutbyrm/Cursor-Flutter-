import '../../../core/util/json_util.dart';

/// Misafir (yayına katılma) isteğinin sunucu tarafındaki karşılığı.
enum LiveGuestRequestOutcome {
  /// Sunucu isteği kaydettiğini bildirdi.
  acknowledged,

  /// İstek gönderildi, 2xx döndü ama sunucu kayıt ürettiğini bildirmedi.
  ///
  /// Bu durum kullanıcıya "gönderildi" diye gösterilmez: üretimde
  /// `/api/live/guest` uçları yayıncının okuduğu listeye yazmayan bir
  /// yanıt döndürebiliyor ve istek sessizce kayboluyordu.
  unconfirmed,
}

/// Sunucu yanıtı isteği gerçekten kaydettiğini gösteriyor mu.
///
/// Boş gövde, `success: false` veya hata alanı taşıyan yanıt onay sayılmaz.
/// Onay için bir kayıt izi aranır: başarı bayrağı, durum alanı ya da istek /
/// oturum kimliği.
bool isGuestRequestAcknowledged(Map<String, dynamic>? body) {
  if (body == null || body.isEmpty) return false;

  final success = body['success'];
  if (success == false) return false;
  final ok = body['ok'];
  if (ok == false) return false;

  final error = pick(body, ['error', 'message', 'errorEn'])?.toString().trim();
  if (error != null && error.isNotEmpty && success != true && ok != true) {
    return false;
  }

  if (success == true || ok == true) return true;

  final id = pick(body, [
    'requestId',
    'sessionId',
    'guestRequestId',
    'id',
  ])?.toString().trim();
  if (id != null && id.isNotEmpty) return true;

  final status = pick(body, ['status', 'state'])?.toString().trim();
  if (status != null && status.isNotEmpty) return true;

  // İç içe kayıt: {request: {...}} / {guest: {...}} / {session: {...}}
  for (final key in const ['request', 'guest', 'session', 'joinRequest']) {
    final nested = body[key];
    if (nested is Map && nested.isNotEmpty) return true;
  }
  return false;
}
