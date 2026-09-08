import 'package:flutter/material.dart';

import '../../../core/auth/voice_staff_rank.dart';
import '../../../core/util/json_util.dart';
import '../domain/site_animation_asset.dart';
import '../domain/site_animation_command.dart';
import '../domain/site_animation_layout.dart';
import '../domain/site_animation_tier.dart';
import '../domain/site_animation_type.dart';
import 'site_animation_asset_registry.dart';

/// SSE `room_event` payload → [SiteAnimationCommand].
abstract final class SiteAnimationParser {
  static const _roomMemberJoined = {
    'room_member_joined',
    'user_joined',
    'userjoined',
    'join',
  };
  static const _roomMemberLeft = {
    'room_member_left',
    'user_left',
    'userleft',
    'leave',
  };
  static const _roomMemberSeatChanged = {
    'room_member_seat_changed',
    'seat_changed',
    'seatchanged',
  };
  static const _micEnabled = {'mic_enabled', 'mic_on'};
  static const _micDisabled = {'mic_disabled', 'mic_off'};
  static const _ownerChanged = {'owner_changed', 'host_changed'};

  static SiteAnimationCommand? fromRoomEvent({
    required String roomId,
    required String event,
    required Map<String, dynamic> payload,
    String? ownerId,
  }) {
    final normalized = event.toLowerCase().trim();
    final userId =
        pick(payload, ['userId', 'id', 'uid'])?.toString().trim() ?? '';
    if (userId.isEmpty && !_ownerChanged.contains(normalized)) return null;

    final name = pick(payload, ['name', 'displayName', 'nickname'])
            ?.toString()
            .trim() ??
        'Kullanıcı';
    final membership = pick(payload, ['membership', 'tier', 'vipTier'])
        ?.toString();
    final chatRole = pick(payload, ['chatRole', 'role'])?.toString();
    final staffRank = VoiceStaffRankParser.resolve(
      username: pick(payload, ['nickname', 'username'])?.toString(),
      chatRole: chatRole,
    );
    final isOwner = ownerId != null &&
        ownerId.isNotEmpty &&
        userId == ownerId;
    final tier = SiteAnimationTier.resolve(
      membership: membership,
      staffRank: staffRank,
      isHost: payload['isHost'] == true || payload['seatIndex'] == 1,
      isOwner: isOwner,
    );

    final layout = _parseLayout(payload);
    final backendAsset = _parseAsset(payload);
    final animationId = _parseAnimationId(payload);
    final eventId = _eventId(roomId, normalized, payload, userId);

    SiteAnimationType? type;
    if (_roomMemberJoined.contains(normalized)) {
      type = tier == SiteAnimationTier.host
          ? SiteAnimationType.hostSeat
          : SiteAnimationType.memberJoined;
    } else if (_roomMemberLeft.contains(normalized)) {
      type = SiteAnimationType.memberLeft;
    } else if (_roomMemberSeatChanged.contains(normalized)) {
      type = SiteAnimationType.seatChanged;
    } else if (_ownerChanged.contains(normalized)) {
      type = SiteAnimationType.hostSeat;
    } else if (normalized == 'mic_changed') {
      final micOn = _parseBool(payload['micOn']) ?? true;
      type = micOn ? SiteAnimationType.micEnabled : SiteAnimationType.micDisabled;
    } else if (_micEnabled.contains(normalized)) {
      type = SiteAnimationType.micEnabled;
    } else if (_micDisabled.contains(normalized)) {
      type = SiteAnimationType.micDisabled;
    } else if (normalized == 'seat_rank_glow' ||
        normalized == 'seat_rank' ||
        normalized == 'seat_glow') {
      type = SiteAnimationType.seatRankGlow;
    }

    if (type == null) return null;

    final asset = SiteAnimationAssetRegistry.resolve(
      type: type,
      tier: tier,
      backendAsset: backendAsset,
    );

    var resolvedLayout = layout;
    if (type == SiteAnimationType.seatChanged) {
      resolvedLayout = layout.copyWith(
        seatIndex: _parseInt(payload['seatIndex']),
        fromSeatIndex: _parseInt(
          payload['previousSeatIndex'] ?? payload['oldSeatIndex'],
        ),
      );
    } else if (type.isSeatAnchored && layout.seatIndex == null) {
      resolvedLayout = layout.copyWith(
        seatIndex: _parseInt(payload['seatIndex']),
      );
    }

    return SiteAnimationCommand(
      eventId: eventId,
      roomId: roomId,
      type: type,
      tier: tier,
      userId: userId.isEmpty ? (ownerId ?? 'host') : userId,
      userName: name,
      avatarUrl: pick(payload, ['image', 'avatar', 'avatarUrl', 'profileImage'])
          ?.toString(),
      layout: resolvedLayout,
      asset: asset,
      micOn: _parseBool(payload['micOn']),
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
      animationId: animationId,
    );
  }

  static String? _parseAnimationId(Map<String, dynamic> payload) {
    final direct = pick(payload, [
      'entranceAnimationId',
      'animationId',
      'siteAnimationId',
    ])?.toString();
    if (direct != null && direct.trim().isNotEmpty) return direct.trim();
    final anim = payload['animation'] ?? payload['animationMetadata'];
    if (anim is Map) {
      final nested = pick(Map<String, dynamic>.from(anim), [
        'id',
        'animationId',
        'entranceAnimationId',
      ])?.toString();
      if (nested != null && nested.trim().isNotEmpty) return nested.trim();
    }
    return null;
  }

  static String _eventId(
    String roomId,
    String event,
    Map<String, dynamic> payload,
    String userId,
  ) {
    final explicit = pick(payload, ['eventId', 'event_id', 'id'])?.toString();
    if (explicit != null && explicit.trim().isNotEmpty) {
      return explicit.trim();
    }
    final ts = pick(payload, ['timestamp', 'ts', 'createdAt'])?.toString() ?? '';
    return '$roomId:$event:$userId:$ts';
  }

  static SiteAnimationLayout _parseLayout(Map<String, dynamic> payload) {
    final anim = payload['animation'] ?? payload['animationMetadata'];
    final map = anim is Map ? Map<String, dynamic>.from(anim) : payload;

    final anchorRaw =
        pick(map, ['anchor', 'position', 'screenPosition'])?.toString();
    final anchor = switch (anchorRaw?.toUpperCase()) {
      'TOP_CENTER' || 'TOPCENTER' || 'CENTER_TOP' => SiteAnimationAnchor.topCenter,
      'SEAT' || 'SEAT_ANCHOR' => SiteAnimationAnchor.seat,
      'CUSTOM' => SiteAnimationAnchor.custom,
      _ => SiteAnimationAnchor.topLeft,
    };

    Offset? position;
    final pos = map['position'];
    if (pos is Map) {
      final x = _parseDouble(pos['x']) ?? _parseDouble(pos['left']);
      final y = _parseDouble(pos['y']) ?? _parseDouble(pos['top']);
      if (x != null && y != null) position = Offset(x, y);
    }

    return SiteAnimationLayout(
      anchor: anchor,
      position: position,
      scale: _parseDouble(map['scale']) ?? 1,
      durationMs: _parseInt(map['duration'] ?? map['durationMs']),
      seatIndex: _parseInt(map['seatIndex']),
      fromSeatIndex: _parseInt(map['fromSeatIndex'] ?? map['oldSeatIndex']),
    );
  }

  static SiteAnimationAsset? _parseAsset(Map<String, dynamic> payload) {
    final anim = payload['animation'] ?? payload['animationMetadata'];
    final map = anim is Map ? Map<String, dynamic>.from(anim) : payload;

    final url = pick(map, [
      'assetUrl',
      'animationUrl',
      'url',
      'videoUrl',
      'lottieUrl',
    ])?.toString();

    final assetType =
        pick(map, ['assetType', 'mediaType', 'animationType'])?.toString();
    final kind = switch (assetType?.toLowerCase()) {
      'lottie' || 'json' || 'dotlottie' => SiteAnimationMediaKind.lottie,
      'video' || 'mp4' || 'webm' => SiteAnimationMediaKind.video,
      'svga' => SiteAnimationMediaKind.svga,
      'rive' => SiteAnimationMediaKind.rive,
      _ => url != null && (url.endsWith('.json') || url.endsWith('.lottie'))
          ? SiteAnimationMediaKind.lottie
          : url != null &&
                  (url.endsWith('.mp4') || url.endsWith('.webm'))
              ? SiteAnimationMediaKind.video
              : SiteAnimationMediaKind.native,
    };

    if (url == null || url.trim().isEmpty) return null;

    return SiteAnimationAsset(
      url: url.trim(),
      kind: kind,
      previewMp4Key: pick(map, ['previewKey', 'previewMp4'])?.toString(),
    );
  }

  static bool? _parseBool(dynamic raw) {
    if (raw == null) return null;
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    final s = raw.toString().toLowerCase();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
    return null;
  }

  static int? _parseInt(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString());
  }

  static double? _parseDouble(dynamic raw) {
    if (raw == null) return null;
    if (raw is double) return raw;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString());
  }
}
