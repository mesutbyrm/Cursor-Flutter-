enum GiftPlatform {
  mobile,
  web,
  all;

  static GiftPlatform parse(String? raw) {
    return switch (raw?.toLowerCase().trim()) {
      'web' => GiftPlatform.web,
      'all' => GiftPlatform.all,
      _ => GiftPlatform.mobile,
    };
  }

  String get queryValue => switch (this) {
        GiftPlatform.mobile => 'mobile',
        GiftPlatform.web => 'web',
        GiftPlatform.all => 'all',
      };
}
