import '../../../feed/domain/entities/post_entity.dart';

/// Backend fal paylaşımını akış sayfasında bulmak için eşleştirme.
PostEntity? findMatchingFortunePost({
  required List<PostEntity> posts,
  String? postIdHint,
  String? authorId,
  String? fortuneId,
}) {
  if (postIdHint != null && postIdHint.isNotEmpty) {
    for (final p in posts) {
      if (p.id == postIdHint) return p;
    }
  }

  for (final p in posts) {
    if (authorId != null && authorId.isNotEmpty && p.author.id != authorId) {
      continue;
    }
    if (!p.isAutoShare && p.postType != 'fortune') continue;
    if (fortuneId != null &&
        fortuneId.isNotEmpty &&
        p.fortuneId != null &&
        p.fortuneId != fortuneId) {
      continue;
    }
    return p;
  }

  return null;
}
