import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/diagnostics/cf_diag.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../data/content_detail_remote_datasource.dart';
import '../../domain/content_detail_models.dart';
import '../widgets/content_detail_widgets.dart';

/// Blog yazısı — `GET /api/blog?slug=`, beğeni/favori (`/api/blog/like`,
/// `/api/blog/favorite`, durum `/api/blog/interactions`) ve ilgili yazılar
/// (`/api/blog/related`).
class BlogPostPage extends ConsumerWidget {
  const BlogPostPage({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(blogPostProvider(slug));
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: async.valueOrNull?.title ?? 'Blog',
          subtitle: async.valueOrNull?.category,
          body: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ContentMessage(
              text: ApiException.userMessage(e),
              onRetry: () => ref.invalidate(blogPostProvider(slug)),
            ),
            data: (post) => _BlogBody(post: post),
          ),
        ),
      ),
    );
  }
}

class _BlogBody extends ConsumerWidget {
  const _BlogBody({required this.post});

  final BlogPostItem post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final related = ref.watch(blogRelatedProvider(post.slug)).valueOrNull ??
        const <BlogPostItem>[];
    final date = post.publishedAt?.toLocal();
    final meta = [
      if (post.authorName != null) post.authorName!,
      if (date != null)
        '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}',
      if (post.readTime > 0) '${post.readTime} dk okuma',
    ].join(' · ');
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        if ((post.coverImage ?? '').isNotEmpty) ...[
          ContentCover(
            url: post.coverImage,
            icon: Icons.article_rounded,
            size: MediaQuery.sizeOf(context).width - 32,
          ),
          const SizedBox(height: 12),
        ],
        if (meta.isNotEmpty)
          Text(meta, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        if (post.id.isNotEmpty) _InteractionBar(post: post),
        const SizedBox(height: 12),
        SelectableText(
          post.content ?? post.summary ?? '',
          style: const TextStyle(height: 1.55, fontSize: 15),
        ),
        if (related.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'İlgili yazılar',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          for (final r in related) ...[
            BlogPostTile(post: r, replace: true),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }
}

/// Beğeni + favori düğmeleri. Durum oturum açıkken sunucudan okunur;
/// oturum yoksa sunucu `false` döner, dokunuş 401 → kullanıcı mesajı.
class _InteractionBar extends ConsumerStatefulWidget {
  const _InteractionBar({required this.post});

  final BlogPostItem post;

  @override
  ConsumerState<_InteractionBar> createState() => _InteractionBarState();
}

class _InteractionBarState extends ConsumerState<_InteractionBar> {
  late var _likes = widget.post.likes;
  var _liked = false;
  var _favorited = false;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await ref
          .read(contentDetailRemoteProvider)
          .fetchInteractions(widget.post.id);
      if (!mounted) return;
      setState(() {
        _liked = s.liked;
        _favorited = s.favorited;
        if (s.likesCount > 0) _likes = s.likesCount;
      });
    } catch (e, st) {
      // Durum okunamazsa düğmeler varsayılanla kalır; kayıt düşülür.
      CfDiag.recordError(e, st, category: CfCategory.network);
    }
  }

  Future<void> _toggle({required bool like}) async {
    if (_busy) return;
    setState(() => _busy = true);
    final remote = ref.read(contentDetailRemoteProvider);
    try {
      if (like) {
        final liked = await remote.toggleLike(widget.post.id);
        if (!mounted) return;
        setState(() {
          if (liked != _liked) _likes += liked ? 1 : -1;
          if (_likes < 0) _likes = 0;
          _liked = liked;
        });
      } else {
        final fav = await remote.toggleFavorite(widget.post.id);
        if (!mounted) return;
        setState(() => _favorited = fav);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton.icon(
          onPressed: _busy ? null : () => _toggle(like: true),
          icon: Icon(
            _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: _liked ? const Color(0xFFE74C3C) : null,
          ),
          label: Text('$_likes'),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: _busy ? null : () => _toggle(like: false),
          icon: Icon(
            _favorited ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          ),
          label: Text(_favorited ? 'Kaydedildi' : 'Kaydet'),
        ),
      ],
    );
  }
}
