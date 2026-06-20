import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/live_beauty_settings.dart';
import '../../../agora/presentation/agora_room_manager.dart';
import '../../../trtc/presentation/trtc_room_manager.dart';
import 'package:tencent_rtc_sdk/trtc_cloud.dart';
import 'package:tencent_rtc_sdk/trtc_cloud_def.dart';

const _prefsKey = 'live_beauty_settings_v1';

class LiveBeautyNotifier extends Notifier<LiveBeautySettings> {
  AgoraRoomManager? _agora;
  TrtcRoomManager? _trtc;

  @override
  LiveBeautySettings build() {
    Future.microtask(_load);
    return const LiveBeautySettings();
  }

  void bindRtc({AgoraRoomManager? agora, TrtcRoomManager? trtc}) {
    _agora = agora;
    _trtc = trtc;
    _applyToRtc(state);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final map = jsonDecode(raw);
      if (map is Map<String, dynamic>) {
        state = LiveBeautySettings.fromJson(map);
        _applyToRtc(state);
      }
    } catch (_) {}
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(state.toJson()));
  }

  Future<void> update(LiveBeautySettings next) async {
    state = next;
    await _persist();
    await _applyToRtc(next);
  }

  Future<void> _applyToRtc(LiveBeautySettings s) async {
    final agora = _agora;
    if (agora != null && agora.engine != null) {
      await agora.applyBeauty(
        enabled: s.enabled,
        smoothness: s.smoothness,
        lightening: s.whitening + s.brightness * 0.35,
        redness: s.contrast * 0.25,
        sharpness: s.sharpness,
      );
    }
    final trtc = _trtc;
    if (trtc != null) {
      try {
        final cloud = await TRTCCloud.sharedInstance();
        cloud.setBeautyStyle(
          TRTCBeautyStyle.nature,
          (s.smoothness * 9).round().clamp(0, 9),
          (s.whitening * 9).round().clamp(0, 9),
          (s.contrast * 9).round().clamp(0, 9),
        );
      } catch (_) {}
    }
  }
}

final liveBeautyProvider =
    NotifierProvider<LiveBeautyNotifier, LiveBeautySettings>(
  LiveBeautyNotifier.new,
);
