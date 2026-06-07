import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/api_exception.dart';
import '../../../../../core/widgets/user_avatar.dart';
import '../../../domain/entities/social_comment_entity.dart';
import '../../providers/social_providers.dart';

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
  late Future<List<SocialCommentEntity>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = ref.read(socialRepositoryProvider).fetchComments(widget.postId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref.read(socialRepositoryProvider).addComment(widget.postId, text);
      _controller.clear();
      setState(_reload);
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
            Expanded(
              child: FutureBuilder<List<SocialCommentEntity>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Text(ApiException.userMessage(snap.error!)),
                    );
                  }
                  final items = snap.data ?? const [];
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
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Divider(height: 20),
                    itemBuilder: (context, i) {
                      final c = items[i];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          UserAvatar(url: c.author.avatarUrl, radius: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.author.display,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(c.text),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
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
}
