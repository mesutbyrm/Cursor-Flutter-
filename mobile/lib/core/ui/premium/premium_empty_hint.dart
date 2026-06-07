import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';


/// Bölüm boş / hata durumu — tek satır metin + isteğe bağlı retry.
class PremiumEmptyHint extends StatelessWidget {
  const PremiumEmptyHint({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceMuted,
                  height: 1.35,
                ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('Tekrar dene')),
          ],
        ],
      ),
    );
  }
}
