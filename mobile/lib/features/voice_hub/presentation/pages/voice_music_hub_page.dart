import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/voice_music_recent_store.dart';
import '../../domain/entities/chat_room_dj_state.dart';
import '../../domain/entities/music_queue_item.dart';
import '../../domain/entities/popular_music_suggestion.dart';
import '../providers/chat_room_providers.dart';
import '../theme/voice_room_tokens.dart';
import '../utils/voice_music_access.dart';
import '../utils/voice_room_permissions.dart';
import '../widgets/premium/voice_glass.dart';

/// Web ile aynı: oda üstünde blur’lu modal (sayfa değişmez).
Future<void> showVoiceMusicHubPage(
  BuildContext context,
  WidgetRef ref, {
  required VoiceRoomEntity room,
  required VoiceRoomPermissions perms,
  required bool isOwner,
}) {
  final container = ProviderScope.containerOf(context);
  final size = MediaQuery.sizeOf(context);
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'YouTube Müzik',
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, animation, secondaryAnimation) {
      return Stack(
        fit: StackFit.expand,
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: const SizedBox.expand(),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Material(
                color: Colors.transparent,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 420,
                    maxHeight: size.height * 0.86,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: UncontrolledProviderScope(
                      container: container,
                      child: VoiceMusicHubPage(
                        room: room,
                        perms: perms,
                        isOwner: isOwner,
                        embeddedInDialog: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
    transitionBuilder: (ctx, anim, _, child) {
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      );
    },
  );
}

class VoiceMusicHubPage extends ConsumerStatefulWidget {
  const VoiceMusicHubPage({
    super.key,
    required this.room,
    required this.perms,
    required this.isOwner,
    this.embeddedInDialog = false,
  });

  final VoiceRoomEntity room;
  final VoiceRoomPermissions perms;
  final bool isOwner;
  final bool embeddedInDialog;

  @override
  ConsumerState<VoiceMusicHubPage> createState() => _VoiceMusicHubPageState();
}

class _VoiceMusicHubPageState extends ConsumerState<VoiceMusicHubPage>
    with SingleTickerProviderStateMixin {
  final _queryCtrl = TextEditingController();
  final _giftCtrl = TextEditingController();
  final _recentStore = VoiceMusicRecentStore();
  late final TabController _tabs;

  Timer? _debounce;
  var _searching = false;
  var _submitting = false;
  var _giftMode = false;
  List<YoutubeSearchHit> _hits = const [];
  List<String> _recent = const [];
  List<PopularMusicSuggestion> _popular = const [];
  List<MusicQueueItem> _queue = const [];
  YoutubeSearchHit? _selected;
  String? _error;
  int _cost = 10;
  int _maxQueue = 20;
  var _tabIndex = 0;
  ProviderSubscription<VoiceRoomLiveState>? _liveSub;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (!_tabs.indexIsChanging) {
          setState(() => _tabIndex = _tabs.index);
        }
      });
    _bootstrap();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _liveSub = ref.listenManual(
        voiceRoomLiveProvider(widget.room),
        (prev, next) {
          if (prev?.dj.musicQueue.length != next.dj.musicQueue.length ||
              prev?.dj.playing != next.dj.playing ||
              prev?.dj.nowPlaying?.id != next.dj.nowPlaying?.id) {
            unawaited(_reloadQueue());
          }
        },
      );
    });
  }

  Future<void> _bootstrap() async {
    final recent = await _recentStore.load();
    final popular = await ref
        .read(voiceRoomLiveProvider(widget.room).notifier)
        .fetchPopularMusic();
    await _reloadQueue();
    if (mounted) {
      setState(() {
        _recent = recent;
        _popular = popular;
      });
    }
  }

  Future<void> _reloadQueue() async {
    try {
      final data = await ref
          .read(voiceRoomLiveProvider(widget.room).notifier)
          .fetchMusicQueue();
      if (mounted) {
        setState(() {
          _queue = data.queue;
          _cost = data.cost;
          _maxQueue = data.maxMusicQueue;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _liveSub?.close();
    _debounce?.cancel();
    _tabs.dispose();
    _queryCtrl.dispose();
    _giftCtrl.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      setState(() {
        _hits = const [];
        _selected = null;
        _searching = false;
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(trimmed));
  }

  Future<void> _search(String q) async {
    setState(() {
      _searching = true;
      _error = null;
      _selected = null;
    });
    try {
      final hits = await ref
          .read(voiceRoomLiveProvider(widget.room).notifier)
          .searchYoutube(q);
      if (mounted) {
        setState(() {
          _hits = hits;
          _searching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searching = false;
          _error = ApiException.userMessage(e);
        });
      }
    }
  }

  Future<void> _submit() async {
    final hit = _selected;
    if (hit == null || _submitting) return;
    final balances = ref.read(walletBalancesProvider).valueOrNull;
    final jeton = VoiceMusicAccess.jetonFromBalances(balances);
    final djState = ref.read(voiceRoomLiveProvider(widget.room)).dj;
    if (!VoiceMusicAccess.canRequestSongs(
      dj: djState,
      perms: widget.perms,
      jetonBalance: jeton,
    )) {
      setState(() => _error = 'Bu şarkıyı istemek için en az $_cost jeton gerekli.');
      return;
    }
    if (jeton < _cost && !widget.perms.canManageDj && !djState.canPlayMusic) {
      setState(() => _error = 'Bu şarkıyı istemek için en az $_cost jeton gerekli.');
      return;
    }

    setState(() => _submitting = true);
    await _recentStore.add(_queryCtrl.text.trim().isNotEmpty
        ? _queryCtrl.text.trim()
        : hit.title);
    final isDjFree = widget.perms.canManageDj || djState.canPlayMusic;
    final queueHint = await ref
        .read(voiceRoomLiveProvider(widget.room).notifier)
        .requestMusic(
          title: hit.title,
          youtubeUrl: hit.url,
          thumbUrl: hit.thumbUrl,
          videoId: hit.videoId,
          giftTo: _giftMode ? _giftCtrl.text.trim() : null,
          priority: !isDjFree,
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (queueHint != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(queueHint)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şarkı kuyruğa eklendi')),
      );
    }
    await _reloadQueue();
    if (mounted) setState(() => _tabIndex = 1);
    _tabs.animateTo(1);
  }

  Future<void> _openHostSettings() async {
    final live = ref.read(voiceRoomLiveProvider(widget.room));
    var enabled = live.dj.musicEnabled;
    var cost = live.dj.musicRequestCost;
    var maxQ = live.dj.maxMusicQueue;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: const Color(0xFF1A0F2E),
          title: const Text('Müzik ayarları', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('DJ sistemi', style: TextStyle(color: Colors.white70)),
                value: enabled,
                onChanged: (v) => setLocal(() => enabled = v),
              ),
              ListTile(
                title: const Text('İstek ücreti (jeton)', style: TextStyle(color: Colors.white70)),
                subtitle: Text('$cost', style: const TextStyle(color: Colors.white)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => setLocal(() => cost = (cost - 1).clamp(1, 500)),
                      icon: const Icon(Icons.remove, color: Colors.white),
                    ),
                    IconButton(
                      onPressed: () => setLocal(() => cost = (cost + 1).clamp(1, 500)),
                      icon: const Icon(Icons.add, color: Colors.white),
                    ),
                  ],
                ),
              ),
              ListTile(
                title: const Text('Maks. kuyruk', style: TextStyle(color: Colors.white70)),
                subtitle: Text('$maxQ', style: const TextStyle(color: Colors.white)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => setLocal(() => maxQ = (maxQ - 1).clamp(1, 50)),
                      icon: const Icon(Icons.remove, color: Colors.white),
                    ),
                    IconButton(
                      onPressed: () => setLocal(() => maxQ = (maxQ + 1).clamp(1, 50)),
                      icon: const Icon(Icons.add, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final err = await ref
                    .read(voiceRoomLiveProvider(widget.room).notifier)
                    .updateMusicSettings(
                      musicEnabled: enabled,
                      musicRequestCost: cost,
                      maxMusicQueue: maxQ,
                    );
                if (err != null && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balances = ref.watch(walletBalancesProvider).valueOrNull;
    final jeton = VoiceMusicAccess.jetonFromBalances(balances);
    final live = ref.watch(voiceRoomLiveProvider(widget.room));
    final canMod = widget.perms.canModerate || widget.isOwner;

    return PopScope(
      canPop: true,
      child: Scaffold(
      backgroundColor: VoiceRoomTokens.bgDeep,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'YouTube Müzik',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
        ),
        actions: [
          if (widget.isOwner)
            IconButton(
              icon: const Icon(Icons.tune_rounded, color: Colors.white70),
              onPressed: _openHostSettings,
            ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppThemeColors.accentPink,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Ara'),
            Tab(text: 'Kuyruk'),
          ],
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  VoiceRoomTokens.bgDeep,
                  AppThemeColors.accentPurple.withValues(alpha: 0.35),
                  VoiceRoomTokens.bgDeep,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                top: kToolbarHeight + 32,
                bottom: _tabIndex == 0 ? 88 : 0,
              ),
              child: _tabIndex == 0 ? _buildSearchTab(jeton, live.dj) : _buildQueueTab(canMod),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _tabIndex == 0
          ? VoiceMusicHubSubmitBar(
              cost: _cost,
              enabled: _selected != null,
              loading: _submitting,
              onSubmit: _submit,
            )
          : null,
    ),
    );
  }

  Widget _buildSearchTab(int jeton, ChatRoomDjState dj) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        VoiceGlass(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: TextField(
            controller: _queryCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Şarkı, sanatçı veya albüm ara…',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
              border: InputBorder.none,
              icon: const Icon(Icons.search_rounded, color: Colors.white54),
              suffixIcon: _searching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
            onChanged: _onQueryChanged,
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: AppThemeColors.liveRed, fontSize: 12)),
        ],
        if (_recent.isNotEmpty) ...[
          const SizedBox(height: 16),
          _sectionTitle('Son aramalar'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recent
                .map(
                  (q) => ActionChip(
                    label: Text(q, style: const TextStyle(fontSize: 11)),
                    onPressed: () {
                      _queryCtrl.text = q;
                      _search(q);
                    },
                  ),
                )
                .toList(),
          ),
        ],
        const SizedBox(height: 16),
        _sectionTitle('Popüler şarkılar'),
        SizedBox(
          height: 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _popular.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final p = _popular[i];
              return GestureDetector(
                onTap: () {
                  _queryCtrl.text = p.query;
                  _search(p.query);
                },
                child: VoiceGlass(
                  borderRadius: 14,
                  padding: const EdgeInsets.all(10),
                  child: SizedBox(
                    width: 140,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.trending_up_rounded, color: AppThemeColors.coinGold, size: 18),
                        const Spacer(),
                        Text(
                          p.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          p.artist,
                          maxLines: 1,
                          style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (_hits.isNotEmpty) ...[
          const SizedBox(height: 16),
          _sectionTitle('Sonuçlar'),
          ..._hits.map(_hitTile),
        ],
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Tüm odaya armağan', style: TextStyle(color: Colors.white)),
          value: _giftMode,
          onChanged: (v) => setState(() => _giftMode = v),
        ),
        if (_giftMode)
          VoiceGlass(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _giftCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Alıcı kullanıcı adı (opsiyonel)',
                border: InputBorder.none,
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          'Bakiye: $jeton Jeton · İstek: $_cost 💎 · Kuyruk: ${_queue.length}/$_maxQueue',
          style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.55)),
        ),
      ],
    );
  }

  Widget _hitTile(YoutubeSearchHit hit) {
    final selected = _selected?.videoId == hit.videoId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: VoiceGlass(
        borderRadius: 14,
        borderColor: selected ? AppThemeColors.accentPink : null,
        onTap: () => setState(() => _selected = hit),
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 56,
                height: 56,
                child: hit.thumbUrl != null
                    ? CachedNetworkImage(
                        imageUrl: hit.thumbUrl!,
                        fit: BoxFit.cover,
                        memCacheWidth: 112,
                        memCacheHeight: 112,
                      )
                    : const ColoredBox(color: Colors.white12),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hit.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                  if (hit.subtitleLine.isNotEmpty)
                    Text(
                      hit.subtitleLine,
                      style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.65)),
                    ),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle_rounded, color: AppThemeColors.accentPink),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueTab(bool canMod) {
    return Column(
      children: [
        if (canMod)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () async {
                    final err = await ref
                        .read(voiceRoomLiveProvider(widget.room).notifier)
                        .skipMusic();
                    if (err != null && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                    }
                    await _reloadQueue();
                  },
                  icon: const Icon(Icons.skip_next_rounded, color: Colors.white),
                  label: const Text('Atla', style: TextStyle(color: Colors.white)),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final err = await ref
                        .read(voiceRoomLiveProvider(widget.room).notifier)
                        .clearMusicQueue();
                    if (err != null && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                    }
                    await _reloadQueue();
                  },
                  icon: const Icon(Icons.clear_all_rounded, color: Colors.white),
                  label: const Text('Temizle', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        Expanded(
          child: _queue.isEmpty
              ? Center(
                  child: Text(
                    'Kuyruk boş',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _queue.length,
                  itemBuilder: (context, i) {
                    final item = _queue[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: VoiceGlass(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            Text(
                              '#${i + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: AppThemeColors.coinGold,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    item.requestedBy?.displayName ?? '—',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (canMod)
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.white54),
                                onPressed: () async {
                                  await ref
                                      .read(voiceRoomLiveProvider(widget.room).notifier)
                                      .removeQueueItem(item.id);
                                  await _reloadQueue();
                                },
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          t,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: Colors.white,
          ),
        ),
      );
}

/// Alt sabit istek butonu overlay
class VoiceMusicHubSubmitBar extends StatelessWidget {
  const VoiceMusicHubSubmitBar({
    super.key,
    required this.cost,
    required this.enabled,
    required this.loading,
    required this.onSubmit,
  });

  final int cost;
  final bool enabled;
  final bool loading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.paddingOf(context).bottom + 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
          ),
          child: FilledButton(
            onPressed: enabled && !loading ? onSubmit : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: AppThemeColors.accentPurple,
            ),
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text('İstek Gönder ($cost 💎)', style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ),
      ),
    );
  }
}
