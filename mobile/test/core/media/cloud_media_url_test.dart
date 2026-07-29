import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/core/media/cloud_media_url.dart';

void main() {
  test('R2 gift path resolves to CDN', () {
    expect(
      CloudMediaUrl.resolve('gift/gifts/uuid.mp4'),
      'https://cdn.girlive.com/gift/gifts/uuid.mp4',
    );
  });

  test('http URL passes through unchanged', () {
    const url = 'https://cdn.girlive.com/gift/gifts/a.mp4';
    expect(CloudMediaUrl.resolve(url), url);
  });
}
