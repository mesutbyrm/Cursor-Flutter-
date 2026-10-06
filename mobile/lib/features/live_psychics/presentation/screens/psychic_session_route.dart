import 'package:flutter/material.dart';

import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_session_entity.dart';
import 'package:canlifal_social/features/live_psychics/presentation/screens/psychic_ad_screen.dart';
import 'package:canlifal_social/features/live_psychics/presentation/screens/psychic_session_restore_gate.dart';
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
    return PsychicSessionRestoreGate(
      psychicId: psychicId,
      session: session,
      onSession: (s) => PsychicVideoSessionScreen(session: s),
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
    return PsychicSessionRestoreGate(
      psychicId: psychicId,
      session: session,
      onSession: (s) => PsychicWaitingScreen(session: s),
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
    return PsychicSessionRestoreGate(
      psychicId: psychicId,
      session: session,
      onSession: (s) => PsychicAdScreen(session: s),
    );
  }
}
