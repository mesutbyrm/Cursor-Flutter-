/// Admin panelinden yönetilen giriş efekti varsayılanları (cihaz önbelleği).
class EntranceEffectSettings {
  const EntranceEffectSettings({
    this.speed = 1.0,
    this.durationMs = 2400,
    this.passCount = 1,
    this.goldEnabled = true,
    this.diamondEnabled = true,
    this.svipEnabled = true,
    this.adminEnabled = true,
    this.teamColorsEnabled = true,
  });

  final double speed;
  final int durationMs;
  final int passCount;
  final bool goldEnabled;
  final bool diamondEnabled;
  final bool svipEnabled;
  final bool adminEnabled;
  final bool teamColorsEnabled;

  Duration get animationDuration => Duration(
        milliseconds: (durationMs / speed).round().clamp(900, 6000),
      );

  EntranceEffectSettings copyWith({
    double? speed,
    int? durationMs,
    int? passCount,
    bool? goldEnabled,
    bool? diamondEnabled,
    bool? svipEnabled,
    bool? adminEnabled,
    bool? teamColorsEnabled,
  }) {
    return EntranceEffectSettings(
      speed: speed ?? this.speed,
      durationMs: durationMs ?? this.durationMs,
      passCount: passCount ?? this.passCount,
      goldEnabled: goldEnabled ?? this.goldEnabled,
      diamondEnabled: diamondEnabled ?? this.diamondEnabled,
      svipEnabled: svipEnabled ?? this.svipEnabled,
      adminEnabled: adminEnabled ?? this.adminEnabled,
      teamColorsEnabled: teamColorsEnabled ?? this.teamColorsEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'speed': speed,
        'durationMs': durationMs,
        'passCount': passCount,
        'goldEnabled': goldEnabled,
        'diamondEnabled': diamondEnabled,
        'svipEnabled': svipEnabled,
        'adminEnabled': adminEnabled,
        'teamColorsEnabled': teamColorsEnabled,
      };

  factory EntranceEffectSettings.fromJson(Map<String, dynamic> json) {
    return EntranceEffectSettings(
      speed: (json['speed'] as num?)?.toDouble().clamp(0.5, 2.5) ?? 1.0,
      durationMs: (json['durationMs'] as num?)?.toInt().clamp(1200, 5000) ?? 2400,
      passCount: (json['passCount'] as num?)?.toInt().clamp(1, 3) ?? 1,
      goldEnabled: json['goldEnabled'] as bool? ?? true,
      diamondEnabled: json['diamondEnabled'] as bool? ?? true,
      svipEnabled: json['svipEnabled'] as bool? ?? true,
      adminEnabled: json['adminEnabled'] as bool? ?? true,
      teamColorsEnabled: json['teamColorsEnabled'] as bool? ?? true,
    );
  }
}
