import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../../../../core/network/api_exception.dart';
import '../../../../../core/widgets/user_avatar.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../providers/social_providers.dart';
import '../../utils/social_user_profile_route.dart';
import '../social_linked_caption_text.dart';

/// Gönderi yorumları — GET/POST `/api/social/posts/:id/comments`.
class SocialPostCommentsSheet extends ConsumerStatefulWidget {
  const SocialPostCommentsSheet({
    super.key,
    required this.postId,
    this.initialCount = 0,
  });

  final String postId;
  final int initialCount;

  static Future<void> show(
    BuildContext context, {
    required String postId,
    int initialCount = 0,
  }) {
    final container = ProviderScope.containerOf(context);
    final authed = container.read(authControllerProvider).valueOrNull;
    if (authed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yorum yazmak için giriş yapın')),
      );
      context.go('/login');
      return Future.value();
    }
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF120A24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: SocialPostCommentsSheet(
          postId: postId,
          initialCount: initialCount,
        ),
      ),
    );
  }

  @override
  ConsumerState<SocialPostCommentsSheet> createState() =>
      _SocialPostCommentsSheetState();
}

class _SocialPostCommentsSheetState
    extends ConsumerState<SocialPostCommentsSheet> {
  final _controller = TextEditingController();
  var _sending = false;

  Future<void> _reload() async {
    ref.invalidate(postCommentsProvider(widget.postId));
    await ref.read(postCommentsProvider(widget.postId).future);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    final authed = ref.read(authControllerProvider).valueOrNull;
    if (authed == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yorum yazmak için giriş yapın')),
        );
        context.go('/login');
      }
      return;
    }
    setState(() => _sending = true);
    try {
      await ref.read(socialRepositoryProvider).addComment(widget.postId, text);
      ref.read(socialNotifierProvider.notifier).bumpCommentCount(widget.postId);
      _controller.clear();
      await _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yorum gönderildi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * 0.72;

    return SafeArea(
      child: SizedBox(
        height: maxH,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Text(
                    'Yorumlar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: context.colors.onSurface,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildCommentsList(context)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: TextStyle(color: context.colors.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Yorum yaz…',
                        filled: true,
                        fillColor: context.colors.surfaceContainer,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsList(BuildContext context) {
    final commentsAsync = ref.watch(postCommentsProvider(widget.postId));
    return commentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(ApiException.userMessage(e))),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Text(
              widget.initialCount > 0
                  ? 'Yorumlar yüklenemedi veya gizli.'
                  : 'İlk yorumu sen yaz.',
              style: TextStyle(color: context.colors.onSurfaceMuted),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 20),
            itemBuilder: (context, i) {
              final c = items[i];
              void openAuthor() {
                final id = c.author.id.trim();
                if (id.isEmpty) return;
                context.push(buildSocialUserProfileRoute(id));
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: openAuthor,
                    child: UserAvatar(url: c.author.avatarUrl, radius: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: openAuthor,
                          child: Text(
                            c.author.display,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SocialLinkedCaptionText(
                          text: c.text,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.35,
                            color: context.colors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
