
import 'package:flutter/material.dart';

import '../network/api_exception.dart';
import '../theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';

/// Kullanıcı dostu hata ekranı — tüm feature'lar için ortak.
class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    required this.message,
    this.title = 'Bir şeyler ters gitti',
    this.icon = Icons.cloud_off_rounded,
    this.onRetry,
    this.compact = false,
  });

  final String message;
  final String title;
  final IconData icon;
  final VoidCallback? onRetry;
  final bool compact;

  factory AppErrorView.fromError(
    Object error, {
    VoidCallback? onRetry,
    bool compact = false,
  }) {
    return AppErrorView(
      message: ApiException.userMessage(error),
      onRetry: onRetry,
      compact: compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final padding = compact
        ? const EdgeInsets.all(16)
        : const EdgeInsets.symmetric(horizontal: 24, vertical: 32);

    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppThemeColors.liveRed.withValues(alpha: 0.12),
            ),
            child: Icon(icon, size: compact ? 32 : 40, color: AppThemeColors.liveRed),
          ),
          SizedBox(height: compact ? 12 : 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: compact ? 15 : 17,
              color: c.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: c.onSurfaceMuted,
              fontSize: compact ? 13 : 14,
              height: 1.45,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Tekrar dene'),
            ),
          ],
        ],
      ),
    );
  }
}

/// SSE yeniden bağlanıyor banner'ı.
class SseReconnectBanner extends StatelessWidget {
  const SseReconnectBanner({super.key, this.attempt});

  final int? attempt;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppThemeColors.warning.withValues(alpha: 0.92),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  attempt != null && attempt! > 1
                      ? 'Bağlantı yenileniyor… (deneme $attempt)'
                      : 'Canlı bağlantı yenileniyor…',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
