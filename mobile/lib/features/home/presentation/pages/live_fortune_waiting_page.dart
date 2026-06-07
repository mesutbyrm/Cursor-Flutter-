import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../../domain/entities/live_fortune_session_entity.dart';
import '../providers/home_providers.dart';
import '../theme/home_palette.dart';
import 'live_fortune_session_page.dart';

/// Danışan — falcının kabulünü bekler.
class LiveFortuneWaitingPage extends ConsumerStatefulWidget {
  const LiveFortuneWaitingPage({super.key, required this.session});

  final LiveFortuneSessionEntity session;

  @override
  ConsumerState<LiveFortuneWaitingPage> createState() =>
      _LiveFortuneWaitingPageState();
}

class _LiveFortuneWaitingPageState extends ConsumerState<LiveFortuneWaitingPage> {
  Timer? _poll;
  var _cancelled = false;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => _checkStatus());
    unawaited(_checkStatus());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    if (!mounted || _cancelled) return;
    final status = await ref
        .read(homeRemoteProvider)
        .fetchFortuneSessionStatus(widget.session.sessionId);
    if (!mounted || status == null) return;
    if (status.isRejected) {
      _cancelled = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falcı isteği reddetti')),
      );
      if (context.canPop()) context.pop();
      return;
    }
    if (status.isActive) {
      _cancelled = true;
      ref.read(videoWebrtcSignalServiceProvider).start(
            streamId: widget.session.sessionId,
          );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => LiveFortuneSessionPage(session: widget.session),
        ),
      );
    }
  }

  Future<void> _cancel() async {
    _cancelled = true;
    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final teller = widget.session.teller;
    return Scaffold(
      backgroundColor: HomePalette.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Bağlanıyor'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppThemeColors.accentPink,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                teller.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Falcının kabul etmesi bekleniyor…',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${widget.session.durationMinutes} dk · ${widget.session.totalJeton} jeton',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: _cancel,
                child: const Text('İptal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
