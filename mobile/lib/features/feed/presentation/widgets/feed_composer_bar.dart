import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/feed_providers.dart';

class FeedComposerBar extends ConsumerStatefulWidget {
  const FeedComposerBar({super.key});

  @override
  ConsumerState<FeedComposerBar> createState() => _FeedComposerBarState();
}

class _FeedComposerBarState extends ConsumerState<FeedComposerBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final t = _controller.text.trim();
    ref.read(feedNotifierProvider.notifier).addLocalPost(t);
    _controller.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final avatar = auth.valueOrNull?.avatarUrl;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: [
              AppTheme.accent.withValues(alpha: 0.65),
              AppTheme.accentSecondary.withValues(alpha: 0.55),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(1.5),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(20.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.surfaceElevated,
                backgroundImage:
                    avatar != null && avatar.isNotEmpty ? NetworkImage(avatar) : null,
                child: avatar == null || avatar.isEmpty
                    ? const Icon(Icons.person_rounded, color: AppTheme.muted)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _controller,
                      maxLines: 3,
                      minLines: 1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Ne paylaşmak istersin?',
                        hintStyle: TextStyle(
                          color: AppTheme.muted.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Fotoğraf',
                          onPressed: () {},
                          icon: Icon(
                            Icons.image_outlined,
                            color: AppTheme.accentSecondary.withValues(alpha: 0.95),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Canlı',
                          onPressed: () {},
                          icon: Icon(
                            Icons.videocam_outlined,
                            color: AppTheme.accent.withValues(alpha: 0.95),
                          ),
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: _submit,
                          icon: const Icon(Icons.send_rounded, size: 18),
                          label: const Text('Paylaş'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
