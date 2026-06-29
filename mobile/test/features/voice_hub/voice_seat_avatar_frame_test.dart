import 'package:canlifal_social/features/voice_hub/domain/entities/chat_room_presence.dart';
import 'package:canlifal_social/features/voice_hub/presentation/widgets/premium_2026/voice_seat_avatar_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SeatAvatarStyle', () {
    test('mic kapalıyken gri gradient döner', () {
      final colors = SeatAvatarStyle.ringGradient(
        SeatAvatarRole.admin,
        micOpen: false,
      );
      expect(colors.first, const Color(0xFF6B7280));
    });

    test('admin rolü renkli gradient döner', () {
      final colors = SeatAvatarStyle.ringGradient(
        SeatAvatarRole.admin,
        micOpen: true,
      );
      expect(colors.length, greaterThan(2));
      expect(colors.first, const Color(0xFF7C4DFF));
    });

    test('yetkili roller animasyonlu çerçeve kullanır', () {
      expect(SeatAvatarStyle.animatedRoleFrame(SeatAvatarRole.admin), isTrue);
      expect(SeatAvatarStyle.animatedRoleFrame(SeatAvatarRole.guest), isFalse);
    });
  });

  group('SeatAvatarRoleResolver', () {
    test('host koltuğu host rolü verir', () {
      const user = ChatRoomPresence(id: '1', name: 'Mesut');
      expect(
        SeatAvatarRoleResolver.resolve(user: user, isHost: true),
        SeatAvatarRole.host,
      );
    });
  });

  group('ChatRoomPresence', () {
    test('micOpen koltukta ve susturulmamışken true', () {
      const user = ChatRoomPresence(
        id: '1',
        name: 'Ali',
        seatIndex: 2,
        isMuted: false,
      );
      expect(user.micOpen, isTrue);
    });

    test('micOpen susturulmuşken false', () {
      const user = ChatRoomPresence(
        id: '1',
        name: 'Ali',
        seatIndex: 2,
        isMuted: true,
      );
      expect(user.micOpen, isFalse);
    });
  });
}
