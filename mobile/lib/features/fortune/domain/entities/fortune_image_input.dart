/// Yerel dosya yolları — yükleme öncesi kullanıcı seçimi.
class FortuneLocalImageInput {
  const FortuneLocalImageInput({
    this.cupPath,
    this.saucerPath,
    this.palmPath,
    this.hand = 'right',
  });

  final String? cupPath;
  final String? saucerPath;
  final String? palmPath;
  final String hand;
}

/// Bulut depolama yolları — presigned yükleme sonrası API gövdesi.
class FortuneCloudImageInput {
  const FortuneCloudImageInput({
    this.cupImagePath,
    this.saucerImagePath,
    this.palmImagePath,
    this.hand = 'right',
  });

  final String? cupImagePath;
  final String? saucerImagePath;
  final String? palmImagePath;
  final String hand;
}
