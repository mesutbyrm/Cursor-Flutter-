import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum ShortVisibility { everyone, followers, closeFriends, onlyMe }

enum ShortCommentSetting { everyone, off, followers }

extension ShortVisibilityWire on ShortVisibility {
  String get wireValue => switch (this) {
        ShortVisibility.everyone => 'everyone',
        ShortVisibility.followers => 'followers',
        ShortVisibility.closeFriends => 'close_friends',
        ShortVisibility.onlyMe => 'only_me',
      };

  String get label => switch (this) {
        ShortVisibility.everyone => 'Herkes',
        ShortVisibility.followers => 'Takipçiler',
        ShortVisibility.closeFriends => 'Yakın arkadaşlar',
        ShortVisibility.onlyMe => 'Sadece ben',
      };
}

extension ShortCommentSettingWire on ShortCommentSetting {
  String get wireValue => switch (this) {
        ShortCommentSetting.everyone => 'everyone',
        ShortCommentSetting.off => 'off',
        ShortCommentSetting.followers => 'followers',
      };

  String get label => switch (this) {
        ShortCommentSetting.everyone => 'Yorum açık',
        ShortCommentSetting.off => 'Yorum kapalı',
        ShortCommentSetting.followers => 'Yalnızca takipçiler',
      };
}

class ShortTextOverlay extends Equatable {
  const ShortTextOverlay({
    required this.id,
    required this.text,
    required this.position,
    this.fontSize = 24,
    this.color = Colors.white,
    this.backgroundColor,
    this.rotation = 0,
    this.scale = 1,
    this.fontFamily,
    this.hasShadow = true,
  });

  final String id;
  final String text;
  final Offset position;
  final double fontSize;
  final Color color;
  final Color? backgroundColor;
  final double rotation;
  final double scale;
  final String? fontFamily;
  final bool hasShadow;

  ShortTextOverlay copyWith({
    String? text,
    Offset? position,
    double? fontSize,
    Color? color,
    Color? backgroundColor,
    double? rotation,
    double? scale,
    String? fontFamily,
    bool? hasShadow,
  }) {
    return ShortTextOverlay(
      id: id,
      text: text ?? this.text,
      position: position ?? this.position,
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      fontFamily: fontFamily ?? this.fontFamily,
      hasShadow: hasShadow ?? this.hasShadow,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'x': position.dx,
        'y': position.dy,
        'fontSize': fontSize,
        'color': color.toARGB32(),
        'backgroundColor': backgroundColor?.toARGB32(),
        'rotation': rotation,
        'scale': scale,
        'fontFamily': fontFamily,
        'hasShadow': hasShadow,
      };

  factory ShortTextOverlay.fromJson(Map<String, dynamic> json) {
    return ShortTextOverlay(
      id: (json['id'] ?? '').toString(),
      text: (json['text'] ?? '').toString(),
      position: Offset(
        (json['x'] as num?)?.toDouble() ?? 0,
        (json['y'] as num?)?.toDouble() ?? 0,
      ),
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 24,
      color: Color((json['color'] as num?)?.toInt() ?? Colors.white.toARGB32()),
      backgroundColor: json['backgroundColor'] != null
          ? Color((json['backgroundColor'] as num).toInt())
          : null,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
      scale: (json['scale'] as num?)?.toDouble() ?? 1,
      fontFamily: json['fontFamily']?.toString(),
      hasShadow: json['hasShadow'] != false,
    );
  }

  @override
  List<Object?> get props =>
      [id, text, position, fontSize, color, backgroundColor, rotation, scale];
}

class ShortStickerOverlay extends Equatable {
  const ShortStickerOverlay({
    required this.id,
    required this.emoji,
    required this.position,
    this.scale = 1,
    this.rotation = 0,
  });

  final String id;
  final String emoji;
  final Offset position;
  final double scale;
  final double rotation;

  ShortStickerOverlay copyWith({
    Offset? position,
    double? scale,
    double? rotation,
  }) {
    return ShortStickerOverlay(
      id: id,
      emoji: emoji,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'emoji': emoji,
        'x': position.dx,
        'y': position.dy,
        'scale': scale,
        'rotation': rotation,
      };

  factory ShortStickerOverlay.fromJson(Map<String, dynamic> json) {
    return ShortStickerOverlay(
      id: (json['id'] ?? '').toString(),
      emoji: (json['emoji'] ?? '').toString(),
      position: Offset(
        (json['x'] as num?)?.toDouble() ?? 0,
        (json['y'] as num?)?.toDouble() ?? 0,
      ),
      scale: (json['scale'] as num?)?.toDouble() ?? 1,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, emoji, position, scale, rotation];
}

class ShortUploadDraft extends Equatable {
  const ShortUploadDraft({
    this.sourcePath,
    this.editedPath,
    this.thumbnailPath,
    this.coverTimeMs = 0,
    this.brightness = 0,
    this.contrast = 1,
    this.saturation = 1,
    this.playbackSpeed = 1,
    this.muted = false,
    this.textOverlays = const [],
    this.stickerOverlays = const [],
    this.musicId,
    this.musicTitle,
    this.musicStartSec = 0,
    this.musicVolume = 1,
    this.videoVolume = 1,
    this.voiceoverPath,
    this.description = '',
    this.mentionUserIds = const [],
    this.visibility = ShortVisibility.everyone,
    this.commentSetting = ShortCommentSetting.everyone,
    this.allowDuet = true,
    this.locationLabel,
    this.locationLat,
    this.locationLng,
  });

  final String? sourcePath;
  final String? editedPath;
  final String? thumbnailPath;
  final int coverTimeMs;
  final double brightness;
  final double contrast;
  final double saturation;
  final double playbackSpeed;
  final bool muted;
  final List<ShortTextOverlay> textOverlays;
  final List<ShortStickerOverlay> stickerOverlays;
  final String? musicId;
  final String? musicTitle;
  final double musicStartSec;
  final double musicVolume;
  final double videoVolume;
  final String? voiceoverPath;
  final String description;
  final List<String> mentionUserIds;
  final ShortVisibility visibility;
  final ShortCommentSetting commentSetting;
  final bool allowDuet;
  final String? locationLabel;
  final double? locationLat;
  final double? locationLng;

  String? get videoPath => editedPath ?? sourcePath;

  ShortUploadDraft copyWith({
    String? sourcePath,
    String? editedPath,
    String? thumbnailPath,
    int? coverTimeMs,
    double? brightness,
    double? contrast,
    double? saturation,
    double? playbackSpeed,
    bool? muted,
    List<ShortTextOverlay>? textOverlays,
    List<ShortStickerOverlay>? stickerOverlays,
    String? musicId,
    String? musicTitle,
    double? musicStartSec,
    double? musicVolume,
    double? videoVolume,
    String? voiceoverPath,
    String? description,
    List<String>? mentionUserIds,
    ShortVisibility? visibility,
    ShortCommentSetting? commentSetting,
    bool? allowDuet,
    String? locationLabel,
    double? locationLat,
    double? locationLng,
  }) {
    return ShortUploadDraft(
      sourcePath: sourcePath ?? this.sourcePath,
      editedPath: editedPath ?? this.editedPath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      coverTimeMs: coverTimeMs ?? this.coverTimeMs,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      muted: muted ?? this.muted,
      textOverlays: textOverlays ?? this.textOverlays,
      stickerOverlays: stickerOverlays ?? this.stickerOverlays,
      musicId: musicId ?? this.musicId,
      musicTitle: musicTitle ?? this.musicTitle,
      musicStartSec: musicStartSec ?? this.musicStartSec,
      musicVolume: musicVolume ?? this.musicVolume,
      videoVolume: videoVolume ?? this.videoVolume,
      voiceoverPath: voiceoverPath ?? this.voiceoverPath,
      description: description ?? this.description,
      mentionUserIds: mentionUserIds ?? this.mentionUserIds,
      visibility: visibility ?? this.visibility,
      commentSetting: commentSetting ?? this.commentSetting,
      allowDuet: allowDuet ?? this.allowDuet,
      locationLabel: locationLabel ?? this.locationLabel,
      locationLat: locationLat ?? this.locationLat,
      locationLng: locationLng ?? this.locationLng,
    );
  }

  @override
  List<Object?> get props => [
        sourcePath,
        editedPath,
        thumbnailPath,
        description,
        visibility,
        commentSetting,
      ];

  Map<String, dynamic> toJson() => {
        'sourcePath': sourcePath,
        'editedPath': editedPath,
        'thumbnailPath': thumbnailPath,
        'coverTimeMs': coverTimeMs,
        'brightness': brightness,
        'contrast': contrast,
        'saturation': saturation,
        'playbackSpeed': playbackSpeed,
        'muted': muted,
        'textOverlays': textOverlays.map((e) => e.toJson()).toList(),
        'stickerOverlays': stickerOverlays.map((e) => e.toJson()).toList(),
        'musicId': musicId,
        'musicTitle': musicTitle,
        'musicStartSec': musicStartSec,
        'musicVolume': musicVolume,
        'videoVolume': videoVolume,
        'voiceoverPath': voiceoverPath,
        'description': description,
        'mentionUserIds': mentionUserIds,
        'visibility': visibility.wireValue,
        'commentSetting': commentSetting.wireValue,
        'allowDuet': allowDuet,
        'locationLabel': locationLabel,
        'locationLat': locationLat,
        'locationLng': locationLng,
      };

  factory ShortUploadDraft.fromJson(Map<String, dynamic> json) {
    ShortVisibility parseVisibility(String? raw) {
      return ShortVisibility.values.firstWhere(
        (v) => v.wireValue == raw,
        orElse: () => ShortVisibility.everyone,
      );
    }

    ShortCommentSetting parseComment(String? raw) {
      return ShortCommentSetting.values.firstWhere(
        (v) => v.wireValue == raw,
        orElse: () => ShortCommentSetting.everyone,
      );
    }

    final textRaw = json['textOverlays'];
    final stickerRaw = json['stickerOverlays'];

    return ShortUploadDraft(
      sourcePath: json['sourcePath']?.toString(),
      editedPath: json['editedPath']?.toString(),
      thumbnailPath: json['thumbnailPath']?.toString(),
      coverTimeMs: (json['coverTimeMs'] as num?)?.toInt() ?? 0,
      brightness: (json['brightness'] as num?)?.toDouble() ?? 0,
      contrast: (json['contrast'] as num?)?.toDouble() ?? 1,
      saturation: (json['saturation'] as num?)?.toDouble() ?? 1,
      playbackSpeed: (json['playbackSpeed'] as num?)?.toDouble() ?? 1,
      muted: json['muted'] == true,
      textOverlays: textRaw is List
          ? textRaw
              .whereType<Map>()
              .map((e) => ShortTextOverlay.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      stickerOverlays: stickerRaw is List
          ? stickerRaw
              .whereType<Map>()
              .map((e) =>
                  ShortStickerOverlay.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      musicId: json['musicId']?.toString(),
      musicTitle: json['musicTitle']?.toString(),
      musicStartSec: (json['musicStartSec'] as num?)?.toDouble() ?? 0,
      musicVolume: (json['musicVolume'] as num?)?.toDouble() ?? 1,
      videoVolume: (json['videoVolume'] as num?)?.toDouble() ?? 1,
      voiceoverPath: json['voiceoverPath']?.toString(),
      description: (json['description'] ?? '').toString(),
      mentionUserIds: json['mentionUserIds'] is List
          ? (json['mentionUserIds'] as List).map((e) => e.toString()).toList()
          : const [],
      visibility: parseVisibility(json['visibility']?.toString()),
      commentSetting: parseComment(json['commentSetting']?.toString()),
      allowDuet: json['allowDuet'] != false,
      locationLabel: json['locationLabel']?.toString(),
      locationLat: (json['locationLat'] as num?)?.toDouble(),
      locationLng: (json['locationLng'] as num?)?.toDouble(),
    );
  }
}

/// Kayıtlı taslak meta bilgisi.
class ShortSavedDraftMeta extends Equatable {
  const ShortSavedDraftMeta({
    required this.id,
    required this.userId,
    required this.savedAtMs,
    required this.previewLabel,
    this.thumbnailPath,
  });

  final String id;
  final String userId;
  final int savedAtMs;
  final String previewLabel;
  final String? thumbnailPath;

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'savedAtMs': savedAtMs,
        'previewLabel': previewLabel,
        'thumbnailPath': thumbnailPath,
      };

  factory ShortSavedDraftMeta.fromJson(Map<String, dynamic> json) {
    return ShortSavedDraftMeta(
      id: (json['id'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      savedAtMs: (json['savedAtMs'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
      previewLabel: (json['previewLabel'] ?? 'Taslak').toString(),
      thumbnailPath: json['thumbnailPath']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, userId, savedAtMs, previewLabel, thumbnailPath];
}
