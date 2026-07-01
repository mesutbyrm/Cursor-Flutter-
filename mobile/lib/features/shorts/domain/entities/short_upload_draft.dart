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
        'emoji': emoji,
        'x': position.dx,
        'y': position.dy,
        'scale': scale,
        'rotation': rotation,
      };

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
}
