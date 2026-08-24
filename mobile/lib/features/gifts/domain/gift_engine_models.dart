import 'package:equatable/equatable.dart';

/// Backend Gift Engine öncelik seviyesi — boyut yalnızca backend değerine göre.
enum GiftEnginePriority {
  small,
  medium,
  large,
  ultra;

  static GiftEnginePriority parse(String? raw) {
    return switch (raw?.toUpperCase().trim()) {
      'SMALL' || 'small' => GiftEnginePriority.small,
      'MEDIUM' || 'medium' || 'MID' => GiftEnginePriority.medium,
      'LARGE' || 'large' || 'BIG' || 'big' => GiftEnginePriority.large,
      'ULTRA' || 'ultra' || 'HUGE' || 'huge' => GiftEnginePriority.ultra,
      _ => GiftEnginePriority.medium,
    };
  }

  /// Ekran kısa kenarına göre animasyon kutusu boyutu (layout sabiti).
  double sizeFactor(double shortestSide) => switch (this) {
        GiftEnginePriority.small => 72,
        GiftEnginePriority.medium => shortestSide * 0.35,
        GiftEnginePriority.large => shortestSide * 0.60,
        GiftEnginePriority.ultra => shortestSide,
      };
}

/// Backend display area — konum yalnızca backend değerine göre.
enum GiftEngineDisplayArea {
  fullScreen,
  center,
  seat,
  top,
  bottom;

  static GiftEngineDisplayArea parse(String? raw) {
    return switch (raw?.toUpperCase().trim().replaceAll(' ', '_')) {
      'FULL_SCREEN' ||
      'FULLSCREEN' ||
      'fullscreen' =>
        GiftEngineDisplayArea.fullScreen,
      'CENTER' || 'center' || 'ROOM_CENTER' || 'room_center' => GiftEngineDisplayArea.center,
      'SEAT' || 'seat' || 'ABOVE_SEAT' || 'above_seat' => GiftEngineDisplayArea.seat,
      'TOP' || 'top' || 'HEADER' || 'header' => GiftEngineDisplayArea.top,
      'BOTTOM' || 'bottom' || 'FOOTER' || 'footer' || 'MESSAGE_AREA' || 'message_area' =>
        GiftEngineDisplayArea.bottom,
      _ => GiftEngineDisplayArea.center,
    };
  }
}

/// Backend animasyon türü.
enum GiftEngineAnimationType {
  png,
  svg,
  lottie,
  mp4,
  webm,
  particle,
  rive,
  svga,
  gif,
  none;

  static GiftEngineAnimationType parse(String? raw) {
    return switch (raw?.toUpperCase().trim()) {
      'PNG' || 'png' || 'IMAGE' || 'image' || 'WEBP' => GiftEngineAnimationType.png,
      'SVG' || 'svg' => GiftEngineAnimationType.svg,
      'LOTTIE' || 'lottie' || 'JSON' => GiftEngineAnimationType.lottie,
      'MP4' || 'mp4' || 'VIDEO' || 'video' => GiftEngineAnimationType.mp4,
      'WEBM' || 'webm' => GiftEngineAnimationType.webm,
      'PARTICLE' || 'particle' || 'EFFECT' || 'effect' => GiftEngineAnimationType.particle,
      'RIVE' || 'rive' => GiftEngineAnimationType.rive,
      'SVGA' || 'svga' => GiftEngineAnimationType.svga,
      'GIF' || 'gif' => GiftEngineAnimationType.gif,
      _ => GiftEngineAnimationType.none,
    };
  }

  /// URL uzantısından animasyon türü (yeni CMS hediyeleri).
  static GiftEngineAnimationType inferFromUrl(String? url) {
    if (url == null || url.trim().isEmpty) return GiftEngineAnimationType.none;
    final lower = url.toLowerCase().split('?').first;
    if (lower.endsWith('.mp4')) return GiftEngineAnimationType.mp4;
    if (lower.endsWith('.webm')) return GiftEngineAnimationType.webm;
    if (lower.endsWith('.gif')) return GiftEngineAnimationType.gif;
    if (lower.endsWith('.json')) return GiftEngineAnimationType.lottie;
    if (lower.endsWith('.svg')) return GiftEngineAnimationType.svg;
    if (lower.endsWith('.svga')) return GiftEngineAnimationType.svga;
    if (lower.endsWith('.riv')) return GiftEngineAnimationType.rive;
    if (lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.avif')) {
      return GiftEngineAnimationType.png;
    }
    return GiftEngineAnimationType.none;
  }
}

/// Koltuk efektleri — backend listesinden.
enum GiftSeatEffect {
  glow,
  border,
  shake,
  pulse,
  particle;

  static GiftSeatEffect? parse(String? raw) {
    return switch (raw?.toUpperCase().trim()) {
      'GLOW' || 'glow' => GiftSeatEffect.glow,
      'BORDER' || 'border' => GiftSeatEffect.border,
      'SHAKE' || 'shake' => GiftSeatEffect.shake,
      'PULSE' || 'pulse' => GiftSeatEffect.pulse,
      'PARTICLE' || 'particle' => GiftSeatEffect.particle,
      _ => null,
    };
  }
}

/// Backend'den gelen render talimatları — Flutter hesaplama yapmaz.
class GiftEngineConfig extends Equatable {
  const GiftEngineConfig({
    required this.priority,
    required this.displayArea,
    required this.animationType,
    required this.durationMs,
    required this.queueGapMs,
    required this.feedDurationMs,
    required this.startDelayMs,
    required this.combo,
    this.seatEffects = const [],
    this.assetUrl,
    this.imageUrl,
    this.videoUrl,
    this.thumbnailUrl,
    this.effectColor,
    this.particleKey,
    this.mediaType,
    this.assetFormat,
    this.mediaWidth,
    this.mediaHeight,
  });

  final GiftEnginePriority priority;
  final GiftEngineDisplayArea displayArea;
  final GiftEngineAnimationType animationType;
  final int durationMs;
  final int queueGapMs;
  final int feedDurationMs;
  final int startDelayMs;
  final int combo;
  final List<GiftSeatEffect> seatEffects;
  final String? assetUrl;
  final String? imageUrl;
  final String? videoUrl;
  final String? thumbnailUrl;
  final String? effectColor;
  final String? particleKey;
  final String? mediaType;
  final String? assetFormat;
  final int? mediaWidth;
  final int? mediaHeight;

  bool get isFullScreen =>
      displayArea == GiftEngineDisplayArea.fullScreen ||
      priority == GiftEnginePriority.ultra;

  String? get resolvedAssetUrl {
    final video = videoUrl?.trim();
    if (video != null && video.isNotEmpty) return video;
    final asset = assetUrl?.trim();
    if (asset != null && asset.isNotEmpty) return asset;
    final image = imageUrl?.trim();
    if (image != null && image.isNotEmpty) return image;
    return null;
  }

  String get comboLabel {
    final c = combo;
    if (c <= 1) return '';
    return 'x$c';
  }

  bool get showComboBadge => combo >= 2;

  @override
  List<Object?> get props => [
        priority,
        displayArea,
        animationType,
        durationMs,
        queueGapMs,
        feedDurationMs,
        startDelayMs,
        combo,
        seatEffects,
        assetUrl,
        imageUrl,
        videoUrl,
        thumbnailUrl,
        effectColor,
        particleKey,
        mediaType,
        assetFormat,
        mediaWidth,
        mediaHeight,
      ];
}

/// Sağ taraftaki gift feed satırı.
class GiftFeedItem extends Equatable {
  const GiftFeedItem({
    required this.id,
    required this.senderName,
    required this.giftName,
    required this.jetonAmount,
    required this.combo,
    required this.expiresAt,
    this.iconUrl,
    this.giftIcon,
  });

  final String id;
  final String senderName;
  final String giftName;
  final int jetonAmount;
  final int combo;
  final DateTime expiresAt;
  final String? iconUrl;
  final String? giftIcon;

  String get comboLabel => combo > 1 ? ' x$combo' : '';

  @override
  List<Object?> get props => [
        id,
        senderName,
        giftName,
        jetonAmount,
        combo,
        expiresAt,
        iconUrl,
        giftIcon,
      ];
}
