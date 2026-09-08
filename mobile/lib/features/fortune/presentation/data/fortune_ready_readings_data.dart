/// Hazır yorum vitrin verisi.
typedef FortuneReadyReadingItem = ({
  String title,
  String slug,
  String body,
});

const fortuneReadyReadingItems = <FortuneReadyReadingItem>[
  (
    title: 'Kahve Falı Hazır Yorumu',
    slug: 'kahve-fali',
    body:
        'Fincanında yeni bir yol, kalabalık bir haber ve beklediğin bir görüşme görünüyor.',
  ),
  (
    title: 'Tarot Hazır Yorumu',
    slug: 'tarot',
    body: 'Kartların değişim, karar ve yeni başlangıç temasını vurguluyor.',
  ),
  (
    title: 'Yıldızname Hazır Yorumu',
    slug: 'yildiz-haritasi',
    body:
        'Gökyüzü sana sabır, plan ve doğru zamanda atılacak adım mesajı veriyor.',
  ),
  (
    title: 'Aşk Yorumu',
    slug: 'ask-fali',
    body:
        'Kalbinde netleşmeyen bir konu yakın zamanda konuşma ile aydınlanabilir.',
  ),
];
