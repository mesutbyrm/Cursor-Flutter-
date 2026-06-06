import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/ui/premium_2026/liquid_glass.dart';
import '../../../../core/ui/responsive/responsive_layout.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/entities/search_user_entity.dart';
import '../providers/search_providers.dart';

/// Site `/arama` ile aynı: kullanıcı adı / isim araması.
class GlobalSearchPage extends ConsumerStatefulWidget {
  const GlobalSearchPage({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends ConsumerState<GlobalSearchPage> {
  late final TextEditingController _controller;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focus.requestFocus();
      final q = widget.initialQuery?.trim();
      if (q != null && q.length >= 2) {
        ref.read(userSearchProvider.notifier).setQuery(q);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final results = ref.watch(userSearchProvider);
    final q = _controller.text.trim();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Ara'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: ResponsiveLayout.pagePadding(context).copyWith(top: 8),
            child: LiquidGlass(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              borderRadius: BorderRadius.circular(22),
              blur: palette.isDark ? 18 : 0,
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                onChanged: (v) =>
                    ref.read(userSearchProvider.notifier).setQuery(v),
                style: TextStyle(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Kullanıcı adı veya isim…',
                  hintStyle: TextStyle(color: palette.textMuted),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: palette.textSecondary,
                  ),
                  suffixIcon: q.isEmpty
                      ? null
                      : IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: palette.textSecondary,
                          ),
                          onPressed: () {
                            _controller.clear();
                            ref.read(userSearchProvider.notifier).setQuery('');
                          },
                        ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _buildBody(context, results, q),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncValue<List<SearchUserEntity>> results,
    String q,
  ) {
    final palette = context.palette;

    if (q.length < 2) {
      return Center(
        child: Padding(
          padding: ResponsiveLayout.pagePadding(context),
          child: Text(
            'Aramak için en az 2 karakter yazın.',
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.textMuted, fontSize: 15),
          ),
        ),
      );
    }

    return results.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: ResponsiveLayout.pagePadding(context),
          child: Text(
            ApiException.userMessage(e),
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.textSecondary),
          ),
        ),
      ),
      data: (users) {
        if (users.isEmpty) {
          return Center(
            child: Text(
              'Sonuç bulunamadı.',
              style: TextStyle(color: palette.textMuted),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () =>
              ref.read(userSearchProvider.notifier).refresh(),
          child: ListView.separated(
            padding: ResponsiveLayout.pagePadding(context).copyWith(
              top: 12,
              bottom: 32,
            ),
            itemCount: users.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: palette.divider,
            ),
            itemBuilder: (context, i) {
              final u = users[i];
              return ListTile(
                leading: UserAvatar(url: u.image, radius: 24),
                title: Text(
                  u.name.isNotEmpty ? u.name : u.username,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                subtitle: u.username.isNotEmpty
                    ? Text(
                        '@${u.username}',
                        style: TextStyle(color: palette.textSecondary),
                      )
                    : u.bio != null && u.bio!.isNotEmpty
                        ? Text(
                            u.bio!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: palette.textMuted),
                          )
                        : null,
                onTap: () => context.push('/user/${u.id}'),
              );
            },
          ),
        );
      },
    );
  }
}
