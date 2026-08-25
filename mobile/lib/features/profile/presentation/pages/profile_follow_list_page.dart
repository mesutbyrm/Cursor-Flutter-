import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../presentation/providers/profile_providers.dart';
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
  static const _pageSize = 20;

  final _users = <UserEntity>[];
  var _page = 0;
  var _hasMore = true;
  var _loading = true;
  var _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (_loadingMore) return;
    if (!reset && !_hasMore) return;
    setState(() {
      if (reset) {
        _loading = true;
        _error = null;
      } else {
        _loadingMore = true;
      }
    });
    try {
      final nextPage = reset ? 1 : _page + 1;
      final remote = ref.read(profileRemoteProvider);
      final list = widget.tab == ProfileFollowTab.followers
          ? await remote.followers(
              widget.userId,
              page: nextPage,
              limit: _pageSize,
            )
          : await remote.following(
              widget.userId,
              page: nextPage,
              limit: _pageSize,
            );
      if (!mounted) return;
      setState(() {
        if (reset) _users.clear();
        _users.addAll(list);
        _page = nextPage;
        _hasMore = list.length >= _pageSize;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = ApiException.userMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: widget.tab == ProfileFollowTab.followers
              ? 'Takipçi'
              : 'Takip',
          body: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _users.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _load(reset: true),
              child: const Text('Tekrar dene'),
            ),
          ],
        ),
      );
    }
    if (_users.isEmpty) {
      return const Center(child: Text('Henüz kayıt yok'));
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels >= n.metrics.maxScrollExtent - 240) {
          _load();
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () => _load(reset: true),
        child: ListView.builder(
          itemCount: _users.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= _users.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }
            final u = _users[index];
            return ListTile(
              leading: UserAvatar(url: u.avatarUrl, radius: 22),
              title: Text(u.display, style: Theme.of(context).textTheme.titleSmall),
              subtitle: Text('@${u.username}'),
              onTap: () => context.push('/user/${u.id}'),
            );
          },
        ),
      ),
    );
  }
}
