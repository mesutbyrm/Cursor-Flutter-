/// Agora yayın kalitesi — düşük gecikme ve dinamik bitrate.
enum LiveStreamQualityPreset {
  auto(
    'auto',
    'Otomatik',
    width: 1280,
    height: 720,
    bitrateKbps: 0,
    fps: 30,
    lowLatency: true,
  ),
  q360(
    '360p',
    '360p',
    width: 640,
    height: 360,
    bitrateKbps: 600,
    fps: 24,
    lowLatency: true,
  ),
  q720(
    '720p',
    '720p HD',
    width: 1280,
    height: 720,
    bitrateKbps: 1500,
    fps: 30,
    lowLatency: true,
  ),
  q1080(
    '1080p',
    '1080p Full HD',
    width: 1920,
    height: 1080,
    bitrateKbps: 2500,
    fps: 30,
    lowLatency: false,
  );

  const LiveStreamQualityPreset(
    this.key,
    this.label, {
    required this.width,
    required this.height,
    required this.bitrateKbps,
    required this.fps,
    required this.lowLatency,
  });

  final String key;
  final String label;
  final int width;
  final int height;
  final int bitrateKbps;
  final int fps;
  final bool lowLatency;

  bool get isAuto => this == LiveStreamQualityPreset.auto;

  /// Ağ kalitesi 0–5 (Agora); düşükse bir kademe düşür.
  LiveStreamQualityPreset downgradeFromNetwork(int quality) {
    if (isAuto) {
      if (quality <= 1) return LiveStreamQualityPreset.q360;
      if (quality <= 3) return LiveStreamQualityPreset.q720;
      return LiveStreamQualityPreset.q1080;
    }
    return switch (this) {
      LiveStreamQualityPreset.q1080 when quality <= 2 =>
        LiveStreamQualityPreset.q720,
      LiveStreamQualityPreset.q720 when quality <= 1 =>
        LiveStreamQualityPreset.q360,
      _ => this,
    };
  }
}
