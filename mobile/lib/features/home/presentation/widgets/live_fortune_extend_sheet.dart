import 'package:flutter/material.dart';

/// Süre uzatma paketleri — dakika ve jeton.
class LiveFortuneExtendOption {
  const LiveFortuneExtendOption({
    required this.minutes,
    required this.jeton,
  });

  final int minutes;
  final int jeton;
}

const liveFortuneExtendOptions = [
  LiveFortuneExtendOption(minutes: 5, jeton: 50),
  LiveFortuneExtendOption(minutes: 10, jeton: 100),
  LiveFortuneExtendOption(minutes: 15, jeton: 150),
  LiveFortuneExtendOption(minutes: 20, jeton: 200),
  LiveFortuneExtendOption(minutes: 25, jeton: 250),
  LiveFortuneExtendOption(minutes: 30, jeton: 300),
];

/// Danışan — seans süresi uzatma popup'ı.
Future<LiveFortuneExtendOption?> showLiveFortuneExtendSheet(
  BuildContext context, {
  required int jetonBalance,
  int jetonPerMinute = 10,
}) {
  return showGeneralDialog<LiveFortuneExtendOption>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Süre ekle',
    barrierColor: Colors.black.withValues(alpha: 0.72),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (ctx, _, __) => Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Material(
          color: Colors.transparent,
          child: _LiveFortuneExtendSheet(
            jetonBalance: jetonBalance,
            jetonPerMinute: jetonPerMinute,
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

class _LiveFortuneExtendSheet extends StatelessWidget {
  const _LiveFortuneExtendSheet({
    required this.jetonBalance,
    required this.jetonPerMinute,
  });

  final int jetonBalance;
  final int jetonPerMinute;

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
              color: Color(0xFFFFD54F),
            ),
            child: const Icon(Icons.add_rounded, color: Colors.black87, size: 32),
          ),
          const SizedBox(height: 14),
          const Text(
            'Süre Ekle',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Seansa ek süre ekleyin',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '💰 Jetonunuz: $jetonBalance ($jetonPerMinute jeton/dk)',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFFFD54F),
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.55,
            ),
            itemCount: liveFortuneExtendOptions.length,
            itemBuilder: (_, i) {
              final opt = liveFortuneExtendOptions[i];
              final affordable = jetonBalance >= opt.jeton;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: affordable
                      ? () => Navigator.pop(context, opt)
                      : null,
                  borderRadius: BorderRadius.circular(14),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: affordable
                          ? const Color(0xFFFFD54F)
                          : Colors.white12,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${opt.minutes} dakika',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            color: affordable ? Colors.black87 : Colors.white38,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${opt.jeton}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: affordable ? Colors.black87 : Colors.white38,
                              ),
                            ),
                            Icon(
                              Icons.monetization_on_rounded,
                              size: 14,
                              color: affordable ? Colors.black54 : Colors.white24,
                            ),
                          ],
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
