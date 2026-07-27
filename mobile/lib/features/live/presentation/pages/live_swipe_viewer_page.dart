import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/performance/live_entry_perf.dart';
import '../../domain/entities/live_broadcast_session.dart';
import '../../domain/entities/live_swipe_feed_args.dart';
import 'live_broadcast_room_page.dart';

/// TikTok tarzı dikey swipe — yayınlar arası geçiş.
class LiveSwipeViewerPage extends ConsumerStatefulWidget {
  const LiveSwipeViewerPage({super.key, required this.args});

  final LiveSwipeFeedArgs args;

  @override
  ConsumerState<LiveSwipeViewerPage> createState() =>
      _LiveSwipeViewerPageState();
}

class _LiveSwipeViewerPageState extends ConsumerState<LiveSwipeViewerPage> {
  late PageController _pageCtrl;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.args.initialIndex.clamp(0, widget.args.streams.length - 1);
    _pageCtrl = PageController(initialPage: _index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prewarmAdjacent(_index);
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _prewarmAdjacent(int i) {
    final streams = widget.args.streams;
    for (final j in [i - 1, i, i + 1]) {
      if (j < 0 || j >= streams.length) continue;
      LiveEntryPerf.prewarmOnStreamTap(ref, streams[j]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final streams = widget.args.streams;
    if (streams.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text('Canlı yayın yok')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageCtrl,
        scrollDirection: Axis.vertical,
        itemCount: streams.length,
        onPageChanged: (i) {
          setState(() => _index = i);
          _prewarmAdjacent(i);
        },
        itemBuilder: (context, i) {
          if ((i - _index).abs() > 1) {
            return const ColoredBox(color: Colors.black);
          }
          final stream = streams[i];
          return LiveBroadcastRoomPage(
            key: ValueKey(stream.id),
            session: LiveBroadcastSession.fromStream(stream),
            embeddedInSwipe: true,
            active: i == _index,
            onSwipeClose: () => context.pop(),
            onAdvanceToNextStream: () {
              if (_index < streams.length - 1) {
                _pageCtrl.nextPage(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                );
              } else if (context.mounted) {
                context.pop();
              }
            },
          );
        },
      ),
    );
  }
}
