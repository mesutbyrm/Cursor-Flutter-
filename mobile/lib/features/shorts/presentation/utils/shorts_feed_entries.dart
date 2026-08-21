import '../../domain/entities/short_video_entity.dart';
import '../../domain/entities/shorts_feed_entry.dart';

/// Shorts akışı — yalnızca backend videoları (fake sponsor slot yok).
List<ShortsFeedEntry> buildShortsFeedEntries(
  List<ShortVideoEntity> videos, {
  int adEveryN = 5,
}) {
  return [for (final v in videos) ShortsFeedEntry.video(v)];
}
