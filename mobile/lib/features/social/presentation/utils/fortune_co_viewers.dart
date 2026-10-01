import '../../../auth/domain/entities/user_entity.dart';
import '../../../feed/domain/entities/post_entity.dart';
import '../widgets/instagram/social_fortune_scene_card.dart';

/// "Bu fala kimler baktı" — backend son bakanları vermez (`fortuneCount` yalnızca
/// toplam sayıdır). Yüklü akıştaki GERÇEK gönderilerden türetilir: aynı fal
/// türünü paylaşan (otomatik fal paylaşımı = o fala bakmış kişi) son [max]
/// farklı kullanıcı, gönderi sahibi hariç, en yeni önce. Akışta yoksa boş döner.
List<UserEntity> recentFortuneCoViewers(
  List<PostEntity> feed,
  PostEntity post, {
  int max = 3,
}) {
  final kind = fortuneSceneSlugFor(post.fortuneType ?? post.fortuneSlug);
  if (kind == null) return const [];
  final candidates = [
    for (final p in feed)
      if (p.id != post.id &&
          p.isFortunePost &&
          p.author.id.isNotEmpty &&
          p.author.id != post.author.id &&
          fortuneSceneSlugFor(p.fortuneType ?? p.fortuneSlug) == kind)
        p,
  ]..sort((a, b) {
      final ta = a.createdAt, tb = b.createdAt;
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1;
      if (tb == null) return -1;
      return tb.compareTo(ta);
    });
  final seen = <String>{};
  final out = <UserEntity>[];
  for (final p in candidates) {
    if (seen.add(p.author.id)) out.add(p.author);
    if (out.length >= max) break;
  }
  return out;
}
