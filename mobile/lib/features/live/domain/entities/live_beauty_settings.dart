/// Güzelleştirme ayarları — Agora / TRTC ile senkron.
class LiveBeautySettings {
  const LiveBeautySettings({
    this.enabled = true,
    this.smoothness = 0.45,
    this.whitening = 0.35,
    this.faceSlim = 0.0,
    this.eyeEnlarge = 0.0,
    this.brightness = 0.0,
    this.contrast = 0.0,
    this.sharpness = 0.25,
    this.filterIndex = 0,
    this.filterStrength = 0.5,
  });

  final bool enabled;
  final double smoothness;
  final double whitening;
  final double faceSlim;
  final double eyeEnlarge;
  final double brightness;
  final double contrast;
  final double sharpness;
  final int filterIndex;
  final double filterStrength;

  static const filterNames = [
    'Orijinal',
    'Sıcak',
    'Soğuk',
    'Vintage',
    'Pembe',
    'Gece',
  ];

  LiveBeautySettings copyWith({
    bool? enabled,
    double? smoothness,
    double? whitening,
    double? faceSlim,
    double? eyeEnlarge,
    double? brightness,
    double? contrast,
    double? sharpness,
    int? filterIndex,
    double? filterStrength,
  }) {
    return LiveBeautySettings(
      enabled: enabled ?? this.enabled,
      smoothness: smoothness ?? this.smoothness,
      whitening: whitening ?? this.whitening,
      faceSlim: faceSlim ?? this.faceSlim,
      eyeEnlarge: eyeEnlarge ?? this.eyeEnlarge,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      sharpness: sharpness ?? this.sharpness,
      filterIndex: filterIndex ?? this.filterIndex,
      filterStrength: filterStrength ?? this.filterStrength,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'smoothness': smoothness,
        'whitening': whitening,
        'faceSlim': faceSlim,
        'eyeEnlarge': eyeEnlarge,
        'brightness': brightness,
        'contrast': contrast,
        'sharpness': sharpness,
        'filterIndex': filterIndex,
        'filterStrength': filterStrength,
      };

  factory LiveBeautySettings.fromJson(Map<String, dynamic> json) {
    double d(dynamic v) => (v is num) ? v.toDouble().clamp(0.0, 1.0) : 0.0;
    return LiveBeautySettings(
      enabled: json['enabled'] != false,
      smoothness: d(json['smoothness']),
      whitening: d(json['whitening']),
      faceSlim: d(json['faceSlim']),
      eyeEnlarge: d(json['eyeEnlarge']),
      brightness: d(json['brightness']),
      contrast: d(json['contrast']),
      sharpness: d(json['sharpness']),
      filterIndex: (json['filterIndex'] as num?)?.toInt() ?? 0,
      filterStrength: d(json['filterStrength']),
    );
  }
}
