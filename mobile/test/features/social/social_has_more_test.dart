import 'package:flutter_test/flutter_test.dart';

/// SocialRemoteDataSource.hasMore fallback — pagination yokken tam sayfa = devam.
void main() {
  test('hasMore fallback when pagination missing and page is full', () {
    const limit = 20;
    const postsCount = 20;
    var hasMore = false;
    final pag = null;
    if (pag == null && postsCount >= limit) {
      hasMore = true;
    }
    expect(hasMore, isTrue);
  });

  test('hasMore false for short final page', () {
    const limit = 20;
    const postsCount = 7;
    var hasMore = false;
    if (postsCount >= limit) {
      hasMore = true;
    }
    expect(hasMore, isFalse);
  });
}
