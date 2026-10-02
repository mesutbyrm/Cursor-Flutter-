import '../../../core/network/api_exception.dart';

/// Üyelik satın alma denemesinin ham istek/yanıt özeti (tanılama).
class MembershipPurchaseAttempt {
  const MembershipPurchaseAttempt({
    required this.method,
    required this.url,
    required this.requestBody,
    this.statusCode,
    this.responseBody,
    this.errorType,
  });

  final String method;
  final String url;
  final Map<String, dynamic>? requestBody;
  final int? statusCode;
  final Object? responseBody;
  final String? errorType;

  String get summary {
    final b = responseBody?.toString() ?? '';
    final preview = b.length > 400 ? '${b.substring(0, 400)}…' : b;
    return '$method $url\n'
        '  istek : ${requestBody ?? '-'}\n'
        '  durum : ${statusCode ?? '-'}${errorType != null ? ' ($errorType)' : ''}\n'
        '  yanıt : ${preview.isEmpty ? '-' : preview}';
  }
}

/// Üyelik satın alma hatası — kullanıcıya anlamlı mesaj + kopyalanabilir
/// teknik ayrıntı. [ApiException] olduğu için mevcut yakalayıcılar çalışır.
class MembershipPurchaseException extends ApiException {
  MembershipPurchaseException(
    super.message, {
    super.statusCode,
    required this.planId,
    required this.attempts,
    this.serverMessage,
  });

  final String planId;
  final List<MembershipPurchaseAttempt> attempts;

  /// Sunucunun döndürdüğü ham hata metni (varsa).
  final String? serverMessage;

  String get technicalReport {
    final b = StringBuffer()
      ..writeln('Üyelik satın alma hatası')
      ..writeln('planId: $planId')
      ..writeln('sunucu mesajı: ${serverMessage ?? '-'}')
      ..writeln('deneme sayısı: ${attempts.length}');
    for (final a in attempts) {
      b
        ..writeln('---')
        ..writeln(a.summary);
    }
    return b.toString();
  }
}

/// Sunucu hata metnini kullanıcı dostu Türkçe mesaja çevirir.
String membershipPurchaseUserMessage({
  required int? statusCode,
  required String? serverMessage,
  required String planLabel,
}) {
  final raw = (serverMessage ?? '').trim();
  final low = raw.toLowerCase();

  if (low.contains('yetersiz jeton') || low.contains('insufficient_jeton')) {
    return raw.isNotEmpty ? raw : 'Yetersiz jeton bakiyesi.';
  }
  if (low.contains('yetersiz cfc') || low.contains('insufficient_cfc')) {
    return raw.isNotEmpty ? raw : 'Yetersiz CFC bakiyesi.';
  }
  if (statusCode == 404 || low.contains('plan not found')) {
    return '$planLabel planı sunucuda bulunamadı veya şu an satışta değil. '
        'Paket listesi yenileniyor; lütfen biraz sonra tekrar deneyin.';
  }
  if (statusCode == 401) {
    return 'Oturum süresi doldu. Çıkış yapıp tekrar giriş yapın.';
  }
  if (statusCode == 403) {
    return 'Bu üyelik şu an hesabınız için satın alınamıyor.';
  }
  if (statusCode == 429) {
    return 'Çok fazla deneme yapıldı. Birkaç dakika sonra tekrar deneyin.';
  }
  if (statusCode != null && statusCode >= 500) {
    return 'Sunucu şu an işlemi tamamlayamadı. Jetonunuz düşmüşse üyeliğiniz '
        'kısa sürede aktifleşir; değilse destekle iletişime geçin.';
  }
  if (raw.isNotEmpty && !raw.contains('<')) return raw;
  return 'Üyelik satın alınamadı. Lütfen tekrar deneyin.';
}

/// Plan kimliği sunucudaki gerçek plan kimliği (cuid) mi, yoksa yalnızca
/// katalogdaki tier adı mı? Tier adı ile satın alma sunucuda `Plan not found`
/// (404) döner.
bool looksLikeServerPlanId(String id) {
  final t = id.trim().toLowerCase();
  if (t.isEmpty) return false;
  const tierNames = {
    'basic',
    'free',
    'gold',
    'premium',
    'diamond',
    'svip',
    'super_vip',
    'vip',
  };
  return !tierNames.contains(t);
}
