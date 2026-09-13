/// Gold+ giriş efekti sunumu.
enum EntranceVisualStyle {
  /// Takım renkleri + amblem — üstten kayarak geçer (varsayılan).
  topTeamPass,
  /// Eski tam ekran sinematik giriş.
  centerFullscreen,
}

extension EntranceVisualStyleWire on EntranceVisualStyle {
  String get wire => name;

  static EntranceVisualStyle parse(String? raw) {
    final k = raw?.trim().toLowerCase() ?? '';
    return switch (k) {
      'centerfullscreen' ||
      'center' ||
      'fullscreen' ||
      'cinematic' =>
        EntranceVisualStyle.centerFullscreen,
      _ => EntranceVisualStyle.topTeamPass,
    };
  }
}
