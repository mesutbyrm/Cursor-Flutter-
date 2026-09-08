import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_colors.dart';

/// Yerel örnek katalog / önizleme sayfaları için uyarı şeridi.
class AdminLocalPreviewBanner extends StatelessWidget {
  const AdminLocalPreviewBanner({
    super.key,
    this.message =
        'Yerel önizleme — üretim API’si bağlı değil. Canlı veri için web admin kullanın.',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppThemeColors.coinGold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppThemeColors.coinGold.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppThemeColors.coinGold,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
