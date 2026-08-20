import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/speak_request_status.dart';
import '../providers/voice_speak_request_signal_provider.dart';
import '../utils/voice_speak_request_dialog_helper.dart';

/// Host konuşma isteği popup — SSE `voice_request` / `hand_raised`.
class VoiceSpeakRequestListener extends ConsumerStatefulWidget {
  const VoiceSpeakRequestListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<VoiceSpeakRequestListener> createState() =>
      _VoiceSpeakRequestListenerState();
}

class _VoiceSpeakRequestListenerState
    extends ConsumerState<VoiceSpeakRequestListener> {
  var _showing = false;

  Future<void> _tryShowNext() async {
    if (!mounted || _showing) return;
    final queue = ref.read(voiceSpeakRequestQueueProvider);
    if (queue.isEmpty) return;

    final request = queue.first;
    if (!canModerateSpeakRequests(ref, request.roomKey)) {
      ref
          .read(voiceSpeakRequestQueueProvider.notifier)
          .removeForRequest(request.roomKey, request.requestId);
      return;
    }

    final room = resolveSpeakRequestRoom(ref, request.roomKey);
    if (room == null) {
      ref
          .read(voiceSpeakRequestQueueProvider.notifier)
          .removeForRequest(request.roomKey, request.requestId);
      return;
    }

    _showing = true;
    try {
      await showVoiceSpeakRequestDialog(
        context,
        ref,
        request: request,
        room: room,
      );
    } finally {
      _showing = false;
      if (mounted) unawaited(_tryShowNext());
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<List<VoiceSpeakRequestIncoming>>(
      voiceSpeakRequestQueueProvider,
      (_, __) => unawaited(_tryShowNext()),
    );
    ref.listen<int>(voiceSpeakRequestSignalProvider, (_, __) {
      unawaited(_tryShowNext());
    });
    ref.listen<VoiceSpeakRequestUserNotice?>(
      voiceSpeakRequestUserNoticeProvider,
      (_, next) {
        if (next == null || !mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message)),
        );
        ref.read(voiceSpeakRequestUserNoticeProvider.notifier).state = null;
      },
    );
    return widget.child;
  }
}
