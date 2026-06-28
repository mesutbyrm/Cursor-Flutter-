import 'package:flutter/material.dart';

import 'package:canlifal_social/features/live_psychics/data/services/psychic_session_store.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_session_entity.dart';
import 'package:canlifal_social/features/live_psychics/presentation/screens/psychic_ad_screen.dart';
import 'package:canlifal_social/features/live_psychics/presentation/screens/psychic_profile_screen.dart';
import 'package:canlifal_social/features/live_psychics/presentation/screens/psychic_video_session_screen.dart';
import 'package:canlifal_social/features/live_psychics/presentation/screens/psychic_waiting_screen.dart';

/// Diskten oturum yükler — FutureBuilder yerine tek rebuild.
class _PsychicSessionRestoreGate extends StatefulWidget {
  const _PsychicSessionRestoreGate({
    required this.psychicId,
    this.session,
    required this.onSession,
  });

  final String psychicId;
  final PsychicSessionEntity? session;
  final Widget Function(PsychicSessionEntity session) onSession;

  @override
  State<_PsychicSessionRestoreGate> createState() =>
      _PsychicSessionRestoreGateState();
}

class _PsychicSessionRestoreGateState extends State<_PsychicSessionRestoreGate> {
  PsychicSessionEntity? _restored;
  var _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.session != null) return;
    _loading = true;
    PsychicSessionStore.load().then((value) {
      if (!mounted) return;
      setState(() {
        _restored = value;
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final direct = widget.session;
    if (direct != null) return widget.onSession(direct);
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final restored = _restored;
    if (restored != null && restored.sessionId.isNotEmpty) {
      return widget.onSession(restored);
    }
    return PsychicProfileScreen(psychicId: widget.psychicId);
  }
}

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
    return _PsychicSessionRestoreGate(
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
    return _PsychicSessionRestoreGate(
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
    return _PsychicSessionRestoreGate(
      psychicId: psychicId,
      session: session,
      onSession: (s) => PsychicAdScreen(session: s),
    );
  }
}
