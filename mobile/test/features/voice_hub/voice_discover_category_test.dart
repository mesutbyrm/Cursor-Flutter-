import 'package:canlifal_social/features/voice_hub/data/datasources/voice_rooms_discover_remote_datasource.dart';
import 'package:canlifal_social/features/voice_hub/presentation/utils/voice_room_category_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('assignable categories map to server query param', () {
    for (final c in kVoiceRoomAssignableCategories) {
      expect(
        VoiceRoomsDiscoverRemoteDataSource.serverCategoryForDiscover(c.id),
        c.id,
      );
    }
  });

  test('all and popular skip server category filter', () {
    expect(VoiceRoomsDiscoverRemoteDataSource.serverCategoryForDiscover('all'), isNull);
    expect(
      VoiceRoomsDiscoverRemoteDataSource.serverCategoryForDiscover('popular'),
      isNull,
    );
    expect(
      VoiceRoomsDiscoverRemoteDataSource.serverCategoryForDiscover(null),
      isNull,
    );
  });
}
