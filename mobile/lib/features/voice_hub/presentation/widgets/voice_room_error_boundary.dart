import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/discover/discover_empty_state.dart';
import '../../data/services/voice_room_debug_log.dart';
import '../providers/voice_room_diagnostic_provider.dart';
import '../theme/voice_room_tokens.dart';

/// Sesli oda — build hatalarında gri ErrorWidget yerine anlamlı hata ekranı.
class VoiceRoomErrorBoundary extends ConsumerStatefulWidget {
  const VoiceRoomErrorBoundary({
    super.key,
    required this.roomId,
    required this.child,
  });

  final String roomId;
  final Widget child;

  @override
  ConsumerState<VoiceRoomErrorBoundary> createState() =>
      _VoiceRoomErrorBoundaryState();
}

class _VoiceRoomErrorBoundaryState extends ConsumerState<VoiceRoomErrorBoundary> {
  ErrorWidgetBuilder? _previousBuilder;
  String? _capturedError;

  @override
  void initState() {
    super.initState();
    _previousBuilder = ErrorWidget.builder;
    ErrorWidget.builder = _buildErrorWidget;
    VoiceRoomDebugLog.routeEnter(roomId: widget.roomId, source: 'error_boundary');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(voiceRoomDiagnosticProvider.notifier).resetForRoom(widget.roomId);
    });
  }

  @override
  void dispose() {
    if (_previousBuilder != null) {
      ErrorWidget.builder = _previousBuilder!;
    }
    super.dispose();
  }

  Widget _buildErrorWidget(FlutterErrorDetails details) {
    final message = details.exceptionAsString();
    VoiceRoomDebugLog.log('ui.error_widget', {'error': message});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(voiceRoomDiagnosticProvider.notifier).setUiBuildError(message);
      setState(() => _capturedError = message);
    });
    return VoiceRoomInlineError(message: message, compact: true);
  }

  @override
  Widget build(BuildContext context) {
    if (_capturedError != null) {
      return VoiceRoomFatalErrorScreen(
        roomId: widget.roomId,
        message: _capturedError!,
        diagnostic: ref.watch(voiceRoomDiagnosticProvider),
        onRetry: () {
          ref.read(voiceRoomDiagnosticProvider.notifier).setUiBuildError(null);
          setState(() => _capturedError = null);
        },
        onLeave: () => context.go('/voice-rooms'),
      );
    }
    return widget.child;
  }
}

/// Tam ekran hata — gri ekran yerine.
class VoiceRoomFatalErrorScreen extends StatelessWidget {
  const VoiceRoomFatalErrorScreen({
    super.key,
    required this.roomId,
    required this.message,
    this.diagnostic,
    this.onRetry,
    this.onLeave,
  });

  final String roomId;
  final String message;
  final VoiceRoomDiagnosticState? diagnostic;
  final VoidCallback? onRetry;
  final VoidCallback? onLeave;

  @override
  Widget build(BuildContext context) {
    final d = diagnostic;
    return Scaffold(
      backgroundColor: VoiceRoomTokens.bgDeep,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.headset_off_rounded,
                size: 48,
                color: VoiceRoomTokens.neonPink,
              ),
              const SizedBox(height: 16),
              const Text(
                'Sesli oda arayüzü yüklenemedi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.75),
                  height: 1.35,
                ),
              ),
              if (d != null) ...[
                const SizedBox(height: 16),
                VoiceRoomDiagnosticCard(state: d),
              ],
              const Spacer(),
              if (onRetry != null)
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Tekrar dene'),
                ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: onLeave ?? () => context.go('/voice-rooms'),
                child: const Text('Oda listesine dön'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VoiceRoomInlineError extends StatelessWidget {
  const VoiceRoomInlineError({
    super.key,
    required this.message,
    this.compact = false,
  });

  final String message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: VoiceRoomTokens.bgDeep,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: VoiceRoomTokens.neonPink),
              const SizedBox(height: 8),
              Text(
                compact ? 'Bileşen hatası' : 'Sesli oda hatası',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message,
                textAlign: TextAlign.center,
                maxLines: compact ? 2 : 6,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VoiceRoomDiagnosticCard extends StatelessWidget {
  const VoiceRoomDiagnosticCard({super.key, required this.state});

  final VoiceRoomDiagnosticState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bağlantı durumu',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          _row('Oda', state.roomId.isEmpty ? '—' : state.roomId),
          _row('JWT', state.hasJwt ? 'gönderildi' : 'yok'),
          _row('Presence', state.presenceJoined ? '${state.presenceCount} kişi' : 'hayır'),
          _row('SSE', state.sseConnected ? 'bağlı' : 'bekliyor'),
          _row('Socket', state.socketConnected ? 'bağlı' : 'bekliyor'),
          _row(
            'TRTC',
            state.trtcEntered
                ? 'oda=${state.trtcRoomId} sonuç=${state.trtcResult}'
                : 'bekliyor',
          ),
          if (state.lastApiPath != null)
            _row('Son API', '${state.lastApiPath} (${state.lastApiStatus})'),
          if (kDebugMode && state.lastError != null)
            _row('Hata', state.lastError!),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 10, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}

/// Route yüklenirken / API hata — FutureBuilder benzeri boş ekran yerine.
class VoiceRoomLoadErrorView extends StatelessWidget {
  const VoiceRoomLoadErrorView({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
    this.onBack,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VoiceRoomTokens.bgDeep,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: DiscoverEmptyState(
                  icon: Icons.headset_off_rounded,
                  message: '$title\n$message',
                  actionLabel: onBack != null ? 'Geri' : null,
                  action: onBack,
                ),
              ),
              if (onRetry != null)
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Tekrar dene'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
