import '../../domain/entities/short_video_entity.dart';
import '../providers/shorts_playback_providers.dart';

List<ShortVideoEntity> filterShortsForSafeSettings(
  List<ShortVideoEntity> videos,
  ShortsSafeSettings settings,
) {
  if (!settings.restrictedMode && !settings.hideMature) {
    return videos;
  }
  return videos.where((v) {
    if (settings.restrictedMode) {
      if (v.isMatureContent) return false;
      if (v.contentRating == 'teen') return false;
    }
    if (settings.hideMature && v.isMatureContent) return false;
    return true;
  }).toList();
}
