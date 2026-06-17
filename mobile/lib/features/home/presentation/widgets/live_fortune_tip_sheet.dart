import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';

/// Bahşiş tutarları (jeton).
const liveFortuneTipAmounts = [50, 100, 150, 200, 250, 300, 350, 400, 450, 500];

/// Danışan — falcıya bahşiş gönderme popup'ı.
Future<int?> showLiveFortuneTipSheet(
  BuildContext context, {
  required String tellerName,
  required int jetonBalance,
}) {
  return showGeneralDialog<int>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Bahşiş ver',
    barrierColor: Colors.black.withValues(alpha: 0.72),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (ctx, _, __) => Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Material(
          color: Colors.transparent,
          child: _LiveFortuneTipSheet(
            tellerName: tellerName,
            jetonBalance: jetonBalance,
          ),
        ),
      ),
    ),
    transitionBuilder: (ctx, anim, _, child) => FadeTransition(
      opacity: anim,
      child: ScaleTransition(scale: anim, child: child),
    ),
  );
}

class _LiveFortuneTipSheet extends StatelessWidget {
  const _LiveFortuneTipSheet({
    required this.tellerName,
    required this.jetonBalance,
  });

  final String tellerName;
  final int jetonBalance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A1450), Color(0xFF120A24)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppThemeColors.accentPink,
            ),
            child: const Icon(Icons.card_giftcard_rounded, color: Colors.white),
          ),
          const SizedBox(height: 14),
          const Text(
            '💝 Bahşiş Ver',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$tellerName falcıya bahşiş gönderin',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '💰 Jetonunuz: $jetonBalance',
            style: const TextStyle(
              color: Color(0xFFFFD54F),
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.85,
            ),
            itemCount: liveFortuneTipAmounts.length,
            itemBuilder: (_, i) {
              final amount = liveFortuneTipAmounts[i];
              final affordable = jetonBalance >= amount;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: affordable
                      ? () => Navigator.pop(context, amount)
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: affordable
                          ? AppThemeColors.accentPink.withValues(alpha: 0.85)
                          : Colors.white12,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$amount',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: affordable ? Colors.white : Colors.white38,
                          ),
                        ),
                        const Icon(
                          Icons.monetization_on_rounded,
                          size: 14,
                          color: Color(0xFFFFD54F),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white12,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('İptal', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
