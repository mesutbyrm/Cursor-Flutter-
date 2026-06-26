import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/voice_hub/domain/entities/voice_room_ban_entry.dart';
import 'package:canlifal_social/features/voice_hub/presentation/utils/kick_strike_ui.dart';

void main() {
  group('KickStrikeUi', () {
    test('colors escalate yellow → orange → red', () {
      expect(KickStrikeUi.colorFor(1), const Color(0xFFEAB308));
      expect(KickStrikeUi.colorFor(2), const Color(0xFFF97316));
      expect(KickStrikeUi.colorFor(3), const Color(0xFFEF4444));
    });

    test('message mentions remaining strikes', () {
      expect(
        KickStrikeUi.messageFor(1),
        contains('1/3'),
      );
      expect(
        KickStrikeUi.messageFor(3, autoBanned: true),
        contains('ban'),
      );
    });
  });

  group('VoiceRoomBanEntry', () {
    test('parses nested user and bannedByUser', () {
      final entry = VoiceRoomBanEntry.fromJson({
        'id': 'ban_1',
        'userId': 'user_1',
        'reason': 'Hakaret',
        'user': {
          'id': 'user_1',
          'name': 'Ali',
          'username': 'ali',
          'image': 'https://img',
        },
        'bannedByUser': {'name': 'Moderatör'},
      });
      expect(entry.displayName, 'Ali');
      expect(entry.reason, 'Hakaret');
      expect(entry.bannedByName, 'Moderatör');
    });
  });
}
