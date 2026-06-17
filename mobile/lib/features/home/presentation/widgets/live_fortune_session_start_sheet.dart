import 'package:flutter/material.dart';

/// Falcı — kabul sonrası seansı başlatma popup'ı.
class LiveFortuneSessionStartChoice {
  const LiveFortuneSessionStartChoice({
    required this.durationMinutes,
    required this.totalJeton,
  });

  final int durationMinutes;
  final int totalJeton;

  static const now = LiveFortuneSessionStartChoice(
    durationMinutes: 0,
    totalJeton: 0,
  );
}

const _presetDurations = [
  LiveFortuneSessionStartChoice(durationMinutes: 5, totalJeton: 50),
  LiveFortuneSessionStartChoice(durationMinutes: 10, totalJeton: 100),
  LiveFortuneSessionStartChoice(durationMinutes: 15, totalJeton: 150),
];

Future<LiveFortuneSessionStartChoice?> showLiveFortuneSessionStartSheet(
  BuildContext context, {
  required String clientName,
  required int clientJetonBalance,
}) {
  return showGeneralDialog<LiveFortuneSessionStartChoice>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Seansı başlat',
    barrierColor: Colors.black.withValues(alpha: 0.72),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (ctx, _, __) => Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Material(
          color: Colors.transparent,
          child: _LiveFortuneSessionStartSheet(
            clientName: clientName,
            clientJetonBalance: clientJetonBalance,
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

class _LiveFortuneSessionStartSheet extends StatelessWidget {
  const _LiveFortuneSessionStartSheet({
    required this.clientName,
    required this.clientJetonBalance,
  });

  final String clientName;
  final int clientJetonBalance;

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
              color: Color(0xFF00C853),
            ),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 14),
          const Text(
            'Seansı Başlat',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$clientName bağlandı. Süreyi başlatmak için aşağıdaki butona tıklayın veya önce süre seçin.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kullanıcının jetonu: $clientJetonBalance',
            style: const TextStyle(
              color: Color(0xFFFFB300),
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.pop(
                context,
                LiveFortuneSessionStartChoice.now,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00C853),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text(
                'Şimdi Başlat',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'veya önce süre ekleyin:',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final preset in _presetDurations) ...[
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: preset == _presetDurations.last ? 0 : 8,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(context, preset),
                        borderRadius: BorderRadius.circular(12),
                        child: Ink(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C4DFF).withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Text(
                            '${preset.durationMinutes} dk\n${preset.totalJeton} jeton',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
