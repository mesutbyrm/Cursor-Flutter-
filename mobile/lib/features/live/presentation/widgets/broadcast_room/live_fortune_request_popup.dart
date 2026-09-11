import 'package:flutter/material.dart';

import '../../../domain/entities/live_fortune_request_entity.dart';
import 'live_fortune_request_form.dart';

/// Canlı yayın — fal isteği (ekranı kaplamayan, yuvarlatılmış alt panel).
Future<bool?> showLiveFortuneRequestPopup({
  required BuildContext context,
  required int? balance,
  required String? initialFortuneType,
  required Future<bool> Function({
    required String displayName,
    required String question,
    required String fortuneType,
    required LiveFortunePriority priority,
    required int jetonCost,
  }) onSubmit,
  String title = 'Fal isteği',
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (ctx) {
      final viewInsets = MediaQuery.viewInsetsOf(ctx);
      final height = MediaQuery.sizeOf(ctx).height * 0.62;
      return Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: viewInsets.bottom + 12,
        ),
        child: Material(
          color: Colors.transparent,
          child: Container(
            height: height.clamp(340.0, 520.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2A1548),
                  Color(0xFF0F0818),
                ],
              ),
              border: Border.all(
                color: const Color(0xFFB832FF).withValues(alpha: 0.45),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: Color(0xFFCE93D8),
                        size: 26,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Sorunuzu yazın, öncelik ve fal türünü seçin. Yayıncı isteğinizi anında görür.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: LiveFortuneRequestForm(
                      balance: balance,
                      initialFortuneType: initialFortuneType,
                      onSubmit: ({
                        required displayName,
                        required question,
                        required fortuneType,
                        required priority,
                        required jetonCost,
                      }) async {
                        final ok = await onSubmit(
                          displayName: displayName,
                          question: question,
                          fortuneType: fortuneType,
                          priority: priority,
                          jetonCost: jetonCost,
                        );
                        if (ok && ctx.mounted) Navigator.pop(ctx, true);
                        return ok;
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
