import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/ui/pro_glass/pro_glass.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../../core/widgets/lazy_paginated_list_view.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';

enum ProfileFollowTab { followers, following }

class ProfileFollowListPage extends ConsumerStatefulWidget {
  const ProfileFollowListPage({
    super.key,
    required this.userId,
    required this.tab,
  });

  final String userId;
  final ProfileFollowTab tab;

  @override
  ConsumerState<ProfileFollowListPage> createState() =>
      _ProfileFollowListPageState();
}

class _ProfileFollowListPageState extends ConsumerState<ProfileFollowListPage> {
  List<UserEntity>? _users;
  Object? _error;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ds = ProfileRemoteDataSource(ref.read(dioProvider));
      final list = widget.tab == ProfileFollowTab.followers
          ? await ds.followers(widget.userId)
          : await ds.following(widget.userId);
      if (!mounted) return;
      setState(() {
        _users = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: widget.tab == ProfileFollowTab.followers ? 'Takipçi' : 'Takip',
          body: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: DiscoverAccentLoader());
    }
    if (_error != null) {
      return DiscoverEmptyState(
        icon: Icons.error_outline_rounded,
        message: ApiException.userMessage(_error!),
      );
    }
    final users = _users ?? const [];
    if (users.isEmpty) {
      return DiscoverEmptyState(
        icon: Icons.people_outline_rounded,
        message: widget.tab == ProfileFollowTab.followers
            ? 'Henüz takipçi yok.'
            : 'Henüz kimseyi takip etmiyorsun.',
      );
    }
    return LazyPaginatedListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      itemCount: users.length,
      itemBuilder: (context, i) {
        final u = users[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ProGlassListTile(
            onTap: () => context.push('/user/${u.id}'),
            child: Row(
              children: [
                UserAvatar(url: u.avatarUrl, radius: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u.display,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '@${u.username}',
                        style: TextStyle(
                          color: context.colors.onSurfaceMuted
                              .withValues(alpha: 0.85),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: context.colors.onSurfaceMuted.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
