import 'package:flutter/material.dart';

import '../../data/live_fortune_session_store.dart';
import '../../domain/entities/live_fortune_session_entity.dart';
import '../pages/live_fortune_session_page.dart';
import '../pages/live_fortune_teller_detail_page.dart';
import '../pages/live_fortune_waiting_page.dart';
import 'live_fortune_ad_transition_page.dart';

/// `extra` kaybolunca (izin diyaloğu / process restore) oturumu diskten yükler.
class LiveFortuneSessionRoute extends StatelessWidget {
  const LiveFortuneSessionRoute({
    super.key,
    required this.tellerId,
    this.session,
  });

  final String tellerId;
  final LiveFortuneSessionEntity? session;

  @override
  Widget build(BuildContext context) {
    if (session != null) {
      return LiveFortuneSessionPage(session: session!);
    }
    return FutureBuilder<LiveFortuneSessionEntity?>(
      future: LiveFortuneSessionStore.load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final restored = snapshot.data;
        if (restored != null && restored.sessionId.isNotEmpty) {
          return LiveFortuneSessionPage(session: restored);
        }
        return LiveFortuneTellerDetailPage(tellerId: tellerId);
      },
    );
  }
}

class LiveFortuneWaitingRoute extends StatelessWidget {
  const LiveFortuneWaitingRoute({
    super.key,
    required this.tellerId,
    this.session,
  });

  final String tellerId;
  final LiveFortuneSessionEntity? session;

  @override
  Widget build(BuildContext context) {
    if (session != null) {
      return LiveFortuneWaitingPage(session: session!);
    }
    return FutureBuilder<LiveFortuneSessionEntity?>(
      future: LiveFortuneSessionStore.load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final restored = snapshot.data;
        if (restored != null && restored.sessionId.isNotEmpty) {
          return LiveFortuneWaitingPage(session: restored);
        }
        return LiveFortuneTellerDetailPage(tellerId: tellerId);
      },
    );
  }
}

class LiveFortuneAdTransitionRoute extends StatelessWidget {
  const LiveFortuneAdTransitionRoute({
    super.key,
    required this.tellerId,
    this.session,
  });

  final String tellerId;
  final LiveFortuneSessionEntity? session;

  @override
  Widget build(BuildContext context) {
    if (session != null) {
      return LiveFortuneAdTransitionPage(session: session!);
    }
    return FutureBuilder<LiveFortuneSessionEntity?>(
      future: LiveFortuneSessionStore.load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final restored = snapshot.data;
        if (restored != null && restored.sessionId.isNotEmpty) {
          return LiveFortuneAdTransitionPage(session: restored);
        }
        return LiveFortuneTellerDetailPage(tellerId: tellerId);
      },
    );
  }
}
