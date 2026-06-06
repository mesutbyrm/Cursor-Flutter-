/// Sosyal akış: her 2 gönderiden sonra sesli oda şeridi.
abstract final class SocialFeedLayout {
  SocialFeedLayout._();

  static int itemCount(int postCount) {
    if (postCount <= 0) return 0;
    return postCount + postCount ~/ 2;
  }

  static bool isRoomsStrip(int feedIndex, int postCount) =>
      postIndexAt(feedIndex, postCount) == null;

  /// Gönderi dizinindeki karşılık; oda şeridi için `null`.
  static int? postIndexAt(int feedIndex, int postCount) {
    if (feedIndex < 0 || feedIndex >= itemCount(postCount)) return null;

    var fi = 0;
    var pi = 0;
    while (pi < postCount) {
      if (fi == feedIndex) return pi;
      fi++;
      pi++;
      if (pi >= postCount) break;

      if (fi == feedIndex) return pi;
      fi++;
      pi++;
      if (pi >= postCount) break;

      if (fi == feedIndex) return null;
      fi++;
    }
    return null;
  }
}
