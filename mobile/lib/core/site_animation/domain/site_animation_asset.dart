enum SiteAnimationMediaKind {
  native,
  lottie,
  video,
  svga,
  rive,
}

class SiteAnimationAsset {
  const SiteAnimationAsset({
    this.url,
    this.bundlePath,
    this.kind = SiteAnimationMediaKind.native,
    this.previewMp4Key,
  });

  final String? url;
  final String? bundlePath;
  final SiteAnimationMediaKind kind;
  /// Demo / preview MP4 anahtarı — production'da tercihen Lottie/SVGA kullanılır.
  final String? previewMp4Key;

  bool get hasRemote => url != null && url!.trim().isNotEmpty;
  bool get hasBundle => bundlePath != null && bundlePath!.trim().isNotEmpty;
  bool get isPlayable => hasRemote || hasBundle;

  String get cacheKey =>
      url?.trim().isNotEmpty == true ? url!.trim() : bundlePath ?? previewMp4Key ?? '';
}
