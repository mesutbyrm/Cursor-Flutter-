import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../providers/profile_providers.dart';

class ProfileVisitEntity {
  const ProfileVisitEntity({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.username,
    this.visitedAt,
  });

  factory ProfileVisitEntity.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map
        ? json['user'] as Map<String, dynamic>
        : json;
    return ProfileVisitEntity(
      userId: (user['id'] ?? user['userId'] ?? '').toString(),
      displayName: (user['displayName'] ?? user['name'] ?? user['username'] ?? 'Kullanıcı').toString(),
      avatarUrl: (user['avatarUrl'] ?? user['image'] ?? user['photoUrl'])?.toString(),
      username: (user['username'])?.toString(),
      visitedAt: (json['visitedAt'] ?? json['createdAt'] ?? json['timestamp'])?.toString(),
    );
  }

  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String? username;
  final String? visitedAt;

  String get timeAgo {
    if (visitedAt == null) return '';
    try {
      final dt = DateTime.parse(visitedAt!).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}d önce';
      if (diff.inHours < 24) return '${diff.inHours}s önce';
      if (diff.inDays < 7) return '${diff.inDays}g önce';
      return DateFormat('dd MMM', 'tr_TR').format(dt);
    } catch (_) {
      return '';
    }
  }
}

final profileVisitorsProvider =
    FutureProvider.autoDispose<List<ProfileVisitEntity>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final res = await dio.safeGet<dynamic>(ApiEndpoints.meProfileVisitors);
    final data = res.data;
    List<dynamic> list;
    if (data is Map) {
      list = (data['data'] as List?) ?? (data['visitors'] as List?) ?? [];
    } else if (data is List) {
      list = data;
    } else {
      list = const [];
    }
    return list
        .whereType<Map<String, dynamic>>()
        .map(ProfileVisitEntity.fromJson)
        .toList();
  } catch (_) {
    return const [];
  }
});

class ProfileVisitorsPage extends ConsumerWidget {
  const ProfileVisitorsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(profileVisitorsProvider);
    final statsAsync = ref.watch(profileStatsProvider);
    final views = statsAsync.valueOrNull?.profileViews ?? 0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: 'Kim Baktı',
          body: async.when(
            loading: () => const Center(child: DiscoverAccentLoader()),
            error: (e, _) => DiscoverEmptyState(
              icon: Icons.error_outline_rounded,
              message: ApiException.userMessage(e),
            ),
            data: (visitors) => CustomScrollView(
              slivers: [
                if (views > 0)
                  SliverToBoxAdapter(
                    child: _ViewCountBanner(views: views),
                  ),
                if (visitors.isEmpty)
                  SliverFillRemaining(
                    child: DiscoverEmptyState(
                      icon: Icons.visibility_outlined,
                      message: 'Henüz kimse profilini ziyaret etmedi.',
                    ),
                  )
                else
                  SliverList.builder(
                    itemCount: visitors.length,
                    itemBuilder: (context, i) =>
                        _VisitorTile(visitor: visitors[i]),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ViewCountBanner extends StatelessWidget {
  const _ViewCountBanner({required this.views});

  final int views;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary.withValues(alpha: 0.18),
            colors.secondary.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.visibility_rounded, color: colors.primary, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$views',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: colors.primary,
                ),
              ),
              Text(
                'Toplam profil ziyareti',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.onSurfaceMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VisitorTile extends StatelessWidget {
  const _VisitorTile({required this.visitor});

  final ProfileVisitEntity visitor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: context.colors.surfaceElevated,
        backgroundImage: visitor.avatarUrl != null && visitor.avatarUrl!.isNotEmpty
            ? canlifalImageProvider(visitor.avatarUrl!)
            : null,
        child: visitor.avatarUrl == null || visitor.avatarUrl!.isEmpty
            ? Text(
                visitor.displayName.isNotEmpty
                    ? visitor.displayName[0].toUpperCase()
                    : '?',
                style: const TextStyle(fontWeight: FontWeight.w700),
              )
            : null,
      ),
      title: Text(
        visitor.displayName,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
      subtitle: visitor.username != null
          ? Text(
              '@${visitor.username}',
              style: TextStyle(
                color: context.colors.onSurfaceMuted,
                fontSize: 12,
              ),
            )
          : null,
      trailing: visitor.timeAgo.isNotEmpty
          ? Text(
              visitor.timeAgo,
              style: TextStyle(
                color: context.colors.onSurfaceMuted,
                fontSize: 12,
              ),
            )
          : null,
      onTap: () => context.push('/user/${visitor.userId}'),
    );
  }
}
