import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/post_entity.dart';

/// Üst hikâye halkaları — fal / tarot içerikli yazarlar hariç (yalnızca normal hikâyeler).
class FeedStoryStrip extends StatelessWidget {
  const FeedStoryStrip({super.key, required this.posts});

  final List<PostEntity> posts;

  List<_StoryUser> _users() {
    final seen = <String>{};
    final out = <_StoryUser>[];
    for (final p in posts) {
      if (p.isFortuneContent) continue;
      if (seen.add(p.author.id)) {
        out.add(_StoryUser(p.author.display, p.author.avatarUrl));
      }
    }
    if (out.isEmpty) {
      return const [
        _StoryUser('Canlifal', null),
        _StoryUser('Özge', 'https://i.pravatar.cc/100?u=oz'),
        _StoryUser('Ela', 'https://i.pravatar.cc/100?u=el'),
        _StoryUser('Arda', 'https://i.pravatar.cc/100?u=ar'),
      ];
    }
    return out.take(16).toList();
  }

  @override
  Widget build(BuildContext context) {
    final users = _users();
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        cacheExtent: 400,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        itemCount: users.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final u = users[i];
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accent.withValues(alpha: 0.95),
                      AppTheme.accentSecondary.withValues(alpha: 0.9),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accent.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.surface,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: ClipOval(
                    child: u.avatarUrl != null && u.avatarUrl!.isNotEmpty
                        ? Image.network(
                            u.avatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _fallbackAvatar(u.name),
                          )
                        : _fallbackAvatar(u.name),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 72,
                child: Text(
                  u.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.muted,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _fallbackAvatar(String name) {
    return ColoredBox(
      color: AppTheme.surfaceElevated,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _StoryUser {
  const _StoryUser(this.name, this.avatarUrl);
  final String name;
  final String? avatarUrl;
}
