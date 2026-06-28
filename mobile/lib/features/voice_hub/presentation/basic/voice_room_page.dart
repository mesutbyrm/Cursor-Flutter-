import 'package:flutter/material.dart';

import '../../../live/domain/entities/voice_room_entity.dart';
import '../voice_room_rtc_page.dart';
import 'voice_room_basic_mode.dart';
import 'voice_room_basic_page.dart';

/// Rota girişi — temel mod veya tam RTC sayfası.
Widget buildVoiceRoomPage(VoiceRoomEntity room) {
  if (VoiceRoomBasicMode.enabled) {
    return VoiceRoomBasicPage(room: room);
  }
  return VoiceRoomRtcPage(room: room);
}
