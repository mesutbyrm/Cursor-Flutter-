import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_colors.dart';

class PsychicAsyncBody extends StatelessWidget {
  const PsychicAsyncBody({
    super.key,
    required this.async,
    required this.builder,
    this.onRetry,
    this.emptyMessage = 'Kayıt bulunamadı',
  });

  final AsyncValue<dynamic> async;
  final Widget Function(BuildContext context) builder;
  final VoidCallback? onRetry;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return async.when(
      loading: () => const PsychicLoadingView(),
      error: (e, _) => PsychicErrorView(
        message: ApiException.userMessage(e),
        onRetry: onRetry,
      ),
      data: (_) => builder(context),
    );
  }
}

class PsychicLoadingView extends StatelessWidget {
  const PsychicLoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(message!, style: const TextStyle(color: Colors.white70)),
          ],
        ],
      ),
    );
  }
}

class PsychicErrorView extends StatelessWidget {
  const PsychicErrorView({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white54, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Tekrar dene')),
            ],
          ],
        ),
      ),
    );
  }
}

class PsychicEmptyView extends StatelessWidget {
  const PsychicEmptyView({super.key, required this.message, this.onAction, this.actionLabel});

  final String message;
  final VoidCallback? onAction;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.psychology_outlined, color: Colors.white.withValues(alpha: 0.4), size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class PsychicOfflineBanner extends StatelessWidget {
  const PsychicOfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppThemeColors.accentPink.withValues(alpha: 0.9),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.cloud_off, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Bağlantı yok — yeniden denenecek',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
