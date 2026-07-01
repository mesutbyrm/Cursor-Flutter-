import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../core/providers/auth_selectors.dart';
import '../../domain/entities/short_comment_entity.dart';
import '../../domain/entities/short_video_entity.dart';
import '../providers/shorts_providers.dart';

Future<int?> showShortCommentsSheet(
  BuildContext context,
  WidgetRef ref,
  ShortVideoEntity video, {
  ValueChanged<int>? onCountChanged,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF121218),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) => _ShortCommentsSheet(
      video: video,
      onCountChanged: onCountChanged,
    ),
  );
}

class _ShortCommentsSheet extends ConsumerStatefulWidget {
  const _ShortCommentsSheet({
    required this.video,
    this.onCountChanged,
  });

  final ShortVideoEntity video;
  final ValueChanged<int>? onCountChanged;

  @override
  ConsumerState<_ShortCommentsSheet> createState() =>
      _ShortCommentsSheetState();
}

class _ShortCommentsSheetState extends ConsumerState<_ShortCommentsSheet> {
  final _controller = TextEditingController();
  List<ShortCommentEntity>? _comments;
  Object? _loadError;
  var _commentsLoading = true;
  var _commentsCount = 0;
  var _sending = false;
  String? _replyToId;
  String? _replyToLabel;

  @override
  void initState() {
    super.initState();
    _commentsCount = widget.video.commentsCount;
    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() {
      _commentsLoading = true;
      _loadError = null;
    });
    try {
      final list = await ref.read(shortsRepositoryProvider).fetchComments(
            widget.video.id,
          );
      if (!mounted) return;
      setState(() {
        _comments = list;
        _commentsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e;
        _commentsLoading = false;
      });
    }
  }

  void _notifyCount() {
    widget.onCountChanged?.call(_commentsCount);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startReply(ShortCommentEntity comment) {
    setState(() {
      _replyToId = comment.id;
      _replyToLabel = comment.author.label;
    });
  }

  void _cancelReply() {
    setState(() {
      _replyToId = null;
      _replyToLabel = null;
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final res = await ref.read(shortsRepositoryProvider).addComment(
            widget.video.id,
            text,
            parentId: _replyToId,
          );
      _controller.clear();
      _cancelReply();
      setState(() => _commentsCount = res.commentsCount);
      _notifyCount();
      await _loadComments();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _toggleCommentLike(ShortCommentEntity comment) async {
    try {
      await ref.read(shortsRepositoryProvider).toggleCommentLike(
            widget.video.id,
            comment.id,
          );
      await _loadComments();
    } catch (_) {}
  }

  Future<void> _deleteComment(ShortCommentEntity comment) async {
    final me = ref.read(currentUserIdProvider);
    if (me == null || me != comment.author.id) return;
    try {
      await ref.read(shortsRepositoryProvider).deleteComment(
            widget.video.id,
            comment.id,
          );
      await _loadComments();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final me = ref.watch(currentUserIdProvider);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).pop(_commentsCount);
        }
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.62,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Yorumlar ($_commentsCount)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              Expanded(child: _buildCommentsList(me)),
              if (_replyToLabel != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Yanıt: $_replyToLabel',
                          style: const TextStyle(color: Colors.white54),
                        ),
                      ),
                      IconButton(
                        onPressed: _cancelReply,
                        icon: const Icon(Icons.close, color: Colors.white54),
                      ),
                    ],
                  ),
                ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: _replyToId != null
                                ? 'Yanıt yaz...'
                                : 'Yorum yaz...',
                            hintStyle: const TextStyle(color: Colors.white38),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.08),
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
                      IconButton(
                        onPressed: _sending ? null : _send,
                        icon: _sending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send_rounded, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentsList(String? me) {
    if (_commentsLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white54),
      );
    }
    if (_loadError != null) {
      return Center(
        child: Text(
          _loadError.toString(),
          style: const TextStyle(color: Colors.white54),
        ),
      );
    }
    final comments = _comments ?? const [];
    if (comments.isEmpty) {
      return const Center(
        child: Text(
          'İlk yorumu sen yap',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: comments.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _CommentTile(
        comment: comments[i],
        me: me,
        onReply: _startReply,
        onLike: _toggleCommentLike,
        onDelete: _deleteComment,
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.me,
    required this.onReply,
    required this.onLike,
    required this.onDelete,
  });

  final ShortCommentEntity comment;
  final String? me;
  final ValueChanged<ShortCommentEntity> onReply;
  final ValueChanged<ShortCommentEntity> onLike;
  final ValueChanged<ShortCommentEntity> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CommentRow(
          comment: comment,
          me: me,
          onReply: onReply,
          onLike: onLike,
          onDelete: onDelete,
        ),
        if (comment.replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 42, top: 8),
            child: Column(
              children: [
                for (final reply in comment.replies)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _CommentRow(
                      comment: reply,
                      me: me,
                      onReply: onReply,
                      onLike: onLike,
                      onDelete: onDelete,
                      compact: true,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CommentRow extends StatelessWidget {
  const _CommentRow({
    required this.comment,
    required this.me,
    required this.onReply,
    required this.onLike,
    required this.onDelete,
    this.compact = false,
  });

  final ShortCommentEntity comment;
  final String? me;
  final ValueChanged<ShortCommentEntity> onReply;
  final ValueChanged<ShortCommentEntity> onLike;
  final ValueChanged<ShortCommentEntity> onDelete;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: compact ? 14 : 16,
          backgroundColor: Colors.white12,
          backgroundImage: comment.author.avatarUrl != null
              ? canlifalImageProvider(comment.author.avatarUrl!)
              : null,
          child: comment.author.avatarUrl == null
              ? Text(
                  comment.author.label.characters.first.toUpperCase(),
                  style: TextStyle(fontSize: compact ? 10 : 12),
                )
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      comment.author.label,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: compact ? 12 : 13,
                      ),
                    ),
                  ),
                  if (comment.isPinned)
                    const Icon(Icons.push_pin, size: 14, color: Colors.amber),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                comment.content,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: compact ? 13 : 14,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => onLike(comment),
                    child: Row(
                      children: [
                        Icon(
                          comment.likedByMe
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 14,
                          color: comment.likedByMe
                              ? Colors.redAccent
                              : Colors.white38,
                        ),
                        if (comment.likesCount > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '${comment.likesCount}',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => onReply(comment),
                    child: const Text(
                      'Yanıtla',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ),
                  if (me != null && me == comment.author.id) ...[
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => onDelete(comment),
                      child: const Text(
                        'Sil',
                        style: TextStyle(color: Colors.redAccent, fontSize: 11),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
