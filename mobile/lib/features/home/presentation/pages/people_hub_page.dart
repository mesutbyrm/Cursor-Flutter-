import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/home_user_liker_entity.dart';
import '../providers/home_providers.dart';

enum PeopleHubKind { online, likers }

/// Çevrimiçi / beğenenler — kılavuz `GET /api/users/online` ve `GET /api/user/likers`.
class PeopleHubPage extends ConsumerWidget {
  const PeopleHubPage({super.key, required this.kind});

  final PeopleHubKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authed = ref.watch(authControllerProvider).valueOrNull;
    final isOnline = kind == PeopleHubKind.online;
    return DiscoverSubPage(
      title: isOnline ? 'Çevrimiçi' : 'Seni beğenenler',
      subtitle: isOnline
          ? 'Şu anda sitede olanlar'
          : 'Profilini beğenen kullanıcılar',
      onRefresh: authed == null
          ? null
          : () async {
              if (isOnline) {
                ref.invalidate(onlineUsersHubProvider);
                await ref.read(onlineUsersHubProvider.future);
              } else {
                ref.invalidate(likersHubProvider);
                await ref.read(likersHubProvider.future);
              }
            },
      body: authed == null
          ? DiscoverEmptyState(
              icon: Icons.lock_outline_rounded,
              message: 'Bu liste için giriş yapman gerekiyor.',
              action: () => exitGuestToLogin(ref),
              actionLabel: 'Giriş yap',
            )
          : _PeopleList(kind: kind),
    );
  }
}

class _PeopleList extends ConsumerWidget {
  const _PeopleList({required this.kind});

  final PeopleHubKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = kind == PeopleHubKind.online
        ? ref.watch(onlineUsersHubProvider)
        : ref.watch(likersHubProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => DiscoverEmptyState(
        icon: Icons.error_outline_rounded,
        message: ApiException.userMessage(e),
        action: () => kind == PeopleHubKind.online
            ? ref.invalidate(onlineUsersHubProvider)
            : ref.invalidate(likersHubProvider),
        actionLabel: 'Tekrar dene',
      ),
      data: (items) {
        if (items.isEmpty) {
          return DiscoverEmptyState(
            icon: kind == PeopleHubKind.online
                ? Icons.groups_outlined
                : Icons.favorite_border_rounded,
            message: kind == PeopleHubKind.online
                ? 'Şu an çevrimiçi kimse yok.'
                : 'Henüz beğeni yok.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _PersonTile(
            person: items[i],
            online: kind == PeopleHubKind.online,
          ),
        );
      },
    );
  }
}

class _PersonTile extends StatelessWidget {
  const _PersonTile({required this.person, required this.online});

  final HomeUserLikerEntity person;
  final bool online;

  @override
  Widget build(BuildContext context) {
    final time = person.timeLabel?.trim();
    final subtitle = (time != null && time.isNotEmpty)
        ? time
        : (online ? 'Çevrimiçi' : null);
    return Card(
      child: ListTile(
        leading: UserAvatar(url: person.avatarUrl, radius: 22),
        title: Text(
          person.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: subtitle == null ? null : Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => context.push('/user/${person.id}'),
      ),
    );
  }
}
