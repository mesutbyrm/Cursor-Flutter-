/// PK aksiyonu (accept / reject / cancel / end) sırasında sunucunun döndürdüğü
/// hatanın "istenen sonuç zaten gerçekleşmiş" anlamına gelip gelmediğini söyler.
///
/// Örnek: süre dolduğunda sunucu maçı kendisi bitirir. Kullanıcı bu sırada
/// "PK'yi Bitir"e basarsa sunucu `400 — PK zaten bitmiş` döner. Kullanıcı
/// açısından istenen sonuç (maç bitti) zaten sağlanmıştır; bu bir hata değil,
/// istemcinin durumu güncel değildir. Böyle durumlarda hata göstermek yerine
/// sunucudan yeniden senkron olunmalıdır.
///
/// Not: Mesaj eşleştirmesi üretim sunucusunun Türkçe metinlerine dayanıyor —
/// yerel `api/` aynası bu uçları içermiyor. Sunucu yapılandırılmış bir hata
/// kodu (`errorCode`) döndürmeye başlarsa eşleştirme oraya taşınmalıdır.
bool pkActionErrorMeansAlreadySettled(Object? error) {
  if (error == null) return false;
  final raw = error.toString();

  // Türkçe büyük/küçük harf dönüşümü (İ/ı) güvenilmez olduğu için doğrudan
  // alt dize araması yapılıyor; sunucunun gönderdiği yazımlar listeleniyor.
  const turkishMarkers = <String>[
    'zaten bitmiş',
    'zaten bitti',
    'zaten sona erdi',
    'zaten iptal',
    'zaten reddedil',
    'zaten kabul edil',
    'durumu değişti',
  ];
  for (final marker in turkishMarkers) {
    if (raw.contains(marker)) return true;
  }

  final lower = raw.toLowerCase();
  const asciiMarkers = <String>[
    'already ended',
    'already finished',
    'already cancelled',
    'already canceled',
    'already rejected',
    'already accepted',
  ];
  for (final marker in asciiMarkers) {
    if (lower.contains(marker)) return true;
  }

  return false;
}
