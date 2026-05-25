import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/live_swipe_feed_args.dart';
import 'live_broadcast_room_page.dart';
import '../utils/open_live_stream.dart';
import '../../domain/entities/live_broadcast_session.dart';

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
  final _sessions = <LiveBroadcastSession?>[];

  @override
  void initState() {
    super.initState();
    _index = widget.args.initialIndex.clamp(0, widget.args.streams.length - 1);
    _pageCtrl = PageController(initialPage: _index);
    _sessions.addAll(List.filled(widget.args.streams.length, null));
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSession(_index));
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSession(int i) async {
    if (_sessions[i] != null) return;
    final stream = widget.args.streams[i];
    final session = await buildLiveSessionForStream(ref, stream);
    if (!mounted) return;
    setState(() => _sessions[i] = session);
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
          _loadSession(i);
          if (i + 1 < streams.length) _loadSession(i + 1);
        },
        itemBuilder: (context, i) {
          if ((i - _index).abs() > 1) {
            return const ColoredBox(color: Colors.black);
          }
          final session = _sessions[i];
          if (session == null) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white54),
            );
          }
          return LiveBroadcastRoomPage(
            session: session,
            embeddedInSwipe: true,
            onSwipeClose: () => context.pop(),
          );
        },
      ),
    );
  }
}
