import 'package:flutter/material.dart';

import 'package:canlifal_social/features/live_psychics/data/services/psychic_session_store.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_session_entity.dart';
import 'package:canlifal_social/features/live_psychics/presentation/screens/psychic_ad_screen.dart';
import 'package:canlifal_social/features/live_psychics/presentation/screens/psychic_profile_screen.dart';
import 'package:canlifal_social/features/live_psychics/presentation/screens/psychic_video_session_screen.dart';
import 'package:canlifal_social/features/live_psychics/presentation/screens/psychic_waiting_screen.dart';

/// `extra` kaybolunca (izin diyaloğu / process restore) oturumu diskten yükler.
class PsychicSessionRoute extends StatelessWidget {
  const PsychicSessionRoute({
    super.key,
    required this.psychicId,
    this.session,
  });

  final String psychicId;
  final PsychicSessionEntity? session;

  @override
  Widget build(BuildContext context) {
    if (session != null) {
      return PsychicVideoSessionScreen(session: session!);
    }
    return FutureBuilder<PsychicSessionEntity?>(
      future: PsychicSessionStore.load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final restored = snapshot.data;
        if (restored != null && restored.sessionId.isNotEmpty) {
          return PsychicVideoSessionScreen(session: restored);
        }
        return PsychicProfileScreen(psychicId: psychicId);
      },
    );
  }
}

class PsychicWaitingRoute extends StatelessWidget {
  const PsychicWaitingRoute({
    super.key,
    required this.psychicId,
    this.session,
  });

  final String psychicId;
  final PsychicSessionEntity? session;

  @override
  Widget build(BuildContext context) {
    if (session != null) {
      return PsychicWaitingScreen(session: session!);
    }
    return FutureBuilder<PsychicSessionEntity?>(
      future: PsychicSessionStore.load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final restored = snapshot.data;
        if (restored != null && restored.sessionId.isNotEmpty) {
          return PsychicWaitingScreen(session: restored);
        }
        return PsychicProfileScreen(psychicId: psychicId);
      },
    );
  }
}

class PsychicAdTransitionRoute extends StatelessWidget {
  const PsychicAdTransitionRoute({
    super.key,
    required this.psychicId,
    this.session,
  });

  final String psychicId;
  final PsychicSessionEntity? session;

  @override
  Widget build(BuildContext context) {
    if (session != null) {
      return PsychicAdScreen(session: session!);
    }
    return FutureBuilder<PsychicSessionEntity?>(
      future: PsychicSessionStore.load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final restored = snapshot.data;
        if (restored != null && restored.sessionId.isNotEmpty) {
          return PsychicAdScreen(session: restored);
        }
        return PsychicProfileScreen(psychicId: psychicId);
      },
    );
  }
}
