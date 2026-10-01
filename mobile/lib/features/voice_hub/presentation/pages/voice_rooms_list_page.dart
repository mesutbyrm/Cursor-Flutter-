import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../../../vip_gold/presentation/utils/open_voice_room_vip.dart';
import '../performance/voice_rooms_perf.dart';
import '../providers/voice_rooms_discover_providers.dart';
import '../widgets/voice_rooms_ui/voice_rooms_ui.dart';
import 'voice_rooms_page.dart' show VoiceRoomsStaticBackground;

/// Oda listesi — Yakındaki / Yeni / Arkadaşların odaları (dikey, sayfalı).
class VoiceRoomsListPage extends ConsumerStatefulWidget {
  const VoiceRoomsListPage({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<VoiceRoomsListPage> createState() => _VoiceRoomsListPageState();
}

class _VoiceRoomsListPageState extends ConsumerState<VoiceRoomsListPage> {
  final _scroll = ScrollController();
  final _query = TextEditingController();
  var _searching = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    final tab = VoiceRoomsNearbyTab.values[widget.initialTab.clamp(0, 2)];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(voiceRoomsDiscoverProvider.notifier);
      if (ref.read(voiceRoomsDiscoverProvider).nearbyTab != tab) {
        notifier.selectNearbyTab(tab);
      }
    });
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _query.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels < pos.maxScrollExtent - VoiceRoomsPerf.scrollPreloadPx) {
      return;
    }
    ref.read(voiceRoomsDiscoverProvider.notifier).loadMoreNearby();
  }

  Future<void> _showFilterSheet() async {
    final cats = ref.read(voiceRoomsDiscoverProvider).categories;
    final selected = ref.read(voiceRoomsDiscoverProvider).categoryIndex;
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: const Color(0xFF12081F),
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.7,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Kategori',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              for (var i = 0; i < cats.length; i++)
                ListTile(
                  dense: true,
                  title: Text(
                    cats[i].label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: i == selected
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: VoiceRoomsUiTokens.purpleGlow,
                        )
                      : null,
                  onTap: () => Navigator.pop(ctx, i),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked != null && mounted) {
      ref.read(voiceRoomsDiscoverProvider.notifier).selectCategory(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bootstrapping = ref.watch(
      voiceRoomsDiscoverProvider.select(
        (s) => s.isBootstrapping && s.nearbyRooms.isEmpty,
      ),
    );
    final items = ref.watch(
      voiceRoomsDiscoverProvider.select((s) => s.nearbyRooms),
    );
    final all = ref.watch(voiceRoomsDiscoverProvider.select((s) => s.allRooms));
    final loadingMore = ref.watch(
      voiceRoomsDiscoverProvider.select((s) => s.isLoadingMore),
    );

    final q = _query.text.trim().toLowerCase();
    final rooms = <VoiceRoomEntity>[];
    for (final it in items) {
      final r = voiceRoomById(all, it.id);
      if (r == null) continue;
      if (q.isNotEmpty &&
          !'${r.displayTitle} ${r.descTr ?? ''} ${r.ownerName ?? ''}'
              .toLowerCase()
              .contains(q)) {
        continue;
      }
      rooms.add(r);
    }

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: VoiceRoomsUiTokens.bgAmoled,
      ),
      child: Scaffold(
        backgroundColor: VoiceRoomsUiTokens.bgAmoled,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const VoiceRoomsStaticBackground(),
            SafeArea(
              bottom: false,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    children: [
                      VoiceRoomsHeaderBar(
                        showBack: true,
                        subtitle: null,
                        onSearch: () => setState(() {
                          _searching = !_searching;
                          if (!_searching) _query.clear();
                        }),
                        onFilter: _showFilterSheet,
                      ),
                      if (_searching)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            VoiceRoomsUiTokens.padScreenH,
                            4,
                            VoiceRoomsUiTokens.padScreenH,
                            8,
                          ),
                          child: TextField(
                            controller: _query,
                            autofocus: true,
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Oda ara…',
                              hintStyle: const TextStyle(
                                color: VoiceRoomsUiTokens.textMuted,
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.07),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: VoiceRoomsUiTokens.textSecondary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                      const VoiceRoomsNearbyTabsSection(),
                      const SizedBox(height: VoiceRoomsUiTokens.gapMd),
                      Expanded(
                        child: RefreshIndicator(
                          color: VoiceRoomsUiTokens.purpleGlow,
                          backgroundColor: VoiceRoomsUiTokens.bgAmoled,
                          onRefresh: () async {
                            invalidateDiscoverVoiceRooms(ref);
                            await ref.read(voiceRoomsProvider.future);
                            await ref
                                .read(voiceRoomsDiscoverProvider.notifier)
                                .refresh();
                          },
                          child: bootstrapping
                              ? ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  children: const [VoiceRoomsNearbySkeleton()],
                                )
                              : rooms.isEmpty
                                  ? _EmptyRooms(searching: q.isNotEmpty)
                                  : ListView.builder(
                                      controller: _scroll,
                                      physics: VoiceRoomsPerf.scrollPhysics,
                                      padding: const EdgeInsets.fromLTRB(
                                        VoiceRoomsUiTokens.padScreenH,
                                        0,
                                        VoiceRoomsUiTokens.padScreenH,
                                        24,
                                      ),
                                      itemCount:
                                          rooms.length + (loadingMore ? 1 : 0),
                                      itemBuilder: (context, i) {
                                        if (i >= rooms.length) {
                                          return const Padding(
                                            padding: EdgeInsets.all(16),
                                            child: Center(
                                              child: SizedBox(
                                                width: 22,
                                                height: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                        final room = rooms[i];
                                        return VoiceRoomListCard(
                                          key: ValueKey('list_${room.id}'),
                                          room: room,
                                          rank: i < 3 ? i + 1 : null,
                                          onJoin: () => openVoiceRoomWithVipGate(
                                            context,
                                            ref,
                                            room,
                                          ),
                                        );
                                      },
                                    ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyRooms extends ConsumerWidget {
  const _EmptyRooms({required this.searching});

  final bool searching;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 40),
        const Icon(
          Icons.mic_off_rounded,
          size: 56,
          color: VoiceRoomsUiTokens.textMuted,
        ),
        const SizedBox(height: 16),
        Text(
          searching ? 'Aramana uygun oda yok' : 'Şu an açık oda yok',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'İlk odayı sen aç, insanlar katılsın.',
          textAlign: TextAlign.center,
          style: TextStyle(color: VoiceRoomsUiTokens.textSecondary),
        ),
      ],
    );
  }
}
