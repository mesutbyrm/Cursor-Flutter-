/// Yayın kare hızı — preset’ten bağımsız seçilebilir.
enum LiveStreamFpsMode {
  auto('Otomatik', 0),
  fps15('15 FPS', 15),
  fps24('24 FPS', 24),
  fps30('30 FPS', 30);

  const LiveStreamFpsMode(this.label, this.fps);

  final String label;
  /// `0` = preset’in varsayılan FPS’i kullanılır.
  final int fps;

  bool get isAuto => this == LiveStreamFpsMode.auto;
}
