import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/psychic_session_store.dart';
import '../../domain/entities/psychic_session_entity.dart';
import '../providers/live_psychics_providers.dart';
import 'psychic_profile_screen.dart';

/// Diskten oturum yükler; bitmiş seansı TRTC'ye sokmadan temizler.
class PsychicSessionRestoreGate extends ConsumerStatefulWidget {
  const PsychicSessionRestoreGate({
    super.key,
    required this.psychicId,
    this.session,
    required this.onSession,
  });

  final String psychicId;
  final PsychicSessionEntity? session;
  final Widget Function(PsychicSessionEntity session) onSession;

  @override
  ConsumerState<PsychicSessionRestoreGate> createState() =>
      _PsychicSessionRestoreGateState();
}

class _PsychicSessionRestoreGateState
    extends ConsumerState<PsychicSessionRestoreGate> {
  PsychicSessionEntity? _restored;
  var _loading = false;

  @override
  void initState() {
    super.initState();
    _loading = true;
    unawaited(_resolveSession());
  }

  Future<void> _resolveSession() async {
    final candidate = widget.session ?? await PsychicSessionStore.load();
    if (!mounted) return;
    if (candidate == null || candidate.sessionId.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    final repo = ref.read(livePsychicsRepositoryProvider);
    final lookup = await repo.fetchSessionStatusLookup(candidate.sessionId);
    if (!mounted) return;
    if (lookup.isFailed) {
      setState(() {
        _restored = candidate;
        _loading = false;
      });
      return;
    }
    final status = lookup.status;
    if (status == null || status.status.isTerminal) {
      await PsychicSessionStore.clear();
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _restored = candidate;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final session = _restored;
    if (session != null && session.sessionId.isNotEmpty) {
      return widget.onSession(session);
    }
    return PsychicProfileScreen(psychicId: widget.psychicId);
  }
}
