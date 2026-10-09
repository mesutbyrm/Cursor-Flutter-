import 'package:canlifal_social/core/theme/app_theme.dart';
import 'package:canlifal_social/features/shorts/data/datasources/shorts_remote_datasource.dart';
import 'package:canlifal_social/features/shorts/domain/entities/short_upload_draft.dart';
import 'package:canlifal_social/features/shorts/domain/entities/short_video_entity.dart';
import 'package:canlifal_social/features/shorts/presentation/providers/shorts_providers.dart';
import 'package:canlifal_social/features/shorts/presentation/widgets/short_video_edit_sheet.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRemote extends ShortsRemoteDataSource {
  _FakeRemote() : super(Dio());

  Map<String, Object?>? lastPatch;

  @override
  Future<ShortVideoEntity> updateVideo(
    String videoId, {
    String? description,
    String? thumbnailUrl,
    String? visibility,
    String? commentSetting,
    bool? allowDuet,
    String? locationName,
  }) async {
    lastPatch = {
      'id': videoId,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'visibility': visibility,
      'commentSetting': commentSetting,
      'allowDuet': allowDuet,
      'locationName': locationName,
    };
    return ShortVideoEntity(
      id: videoId,
      userId: 'u1',
      videoUrl: 'https://cdn.example.com/v.mp4',
      description: description,
      visibility: visibility ?? 'everyone',
    );
  }
}

const _video = ShortVideoEntity(
  id: 'v1',
  userId: 'u1',
  videoUrl: 'https://cdn.example.com/v.mp4',
  description: 'eski',
);

void main() {
  test('«Sadece ben» sunucunun beklediği private değeriyle gider', () {
    expect(ShortVisibility.onlyMe.wireValue, 'private');
  });

  testWidgets('yalnız değişen alanlar PATCH ile gönderilir', (tester) async {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final remote = _FakeRemote();
    ShortVideoEntity? result;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [shortsRemoteProvider.overrideWithValue(remote)],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async {
                    result = await showShortVideoEditSheet(context, _video);
                  },
                  child: const Text('aç'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();

    // Değişiklik yokken Kaydet kapalı.
    final save = find.byKey(const Key('short-edit-save'));
    expect(tester.widget<FilledButton>(save).onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('short-edit-description')),
      'yeni #trend',
    );
    await tester.tap(find.text('Sadece ben'));
    await tester.pump();
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(remote.lastPatch?['id'], 'v1');
    expect(remote.lastPatch?['description'], 'yeni #trend');
    expect(remote.lastPatch?['visibility'], 'private');
    expect(remote.lastPatch?['commentSetting'], isNull);
    expect(remote.lastPatch?['allowDuet'], isNull);
    expect(remote.lastPatch?['thumbnailUrl'], isNull);
    expect(result?.description, 'yeni #trend');
  });
}
