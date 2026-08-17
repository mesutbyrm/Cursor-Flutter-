import '../providers/social_providers.dart';

/// Yorum eklendikten sonra akış + detay sayacını senkronize et.
void syncSocialPostCommentAdded({
  required SocialNotifier feed,
  required void Function(String postId) invalidateDetail,
  required String postId,
}) {
  final id = postId.trim();
  if (id.isEmpty) return;
  feed.bumpCommentCount(id);
  invalidateDetail(id);
}
