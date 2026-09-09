import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/economy/presentation/providers/economy_providers.dart';

/// Oda hediye hedefi başlatma — miktar + süre (5/10 dk).
class VoiceGiftGoalStartResult {
  const VoiceGiftGoalStartResult({
    required this.targetAmount,
    required this.durationMinutes,
  });

  final int targetAmount;
  final int durationMinutes;
}

Future<VoiceGiftGoalStartResult?> showVoiceGiftGoalStartModal(
  BuildContext context,
  WidgetRef ref,
) {
  return showModalBottomSheet<VoiceGiftGoalStartResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _VoiceGiftGoalStartSheet(
      jetonLabel: economyCurrencyLabel(ref, key: 'jeton'),
    ),
  );
}

class _VoiceGiftGoalStartSheet extends StatefulWidget {
  const _VoiceGiftGoalStartSheet({required this.jetonLabel});

  final String jetonLabel;

  @override
  State<_VoiceGiftGoalStartSheet> createState() =>
      _VoiceGiftGoalStartSheetState();
}

class _VoiceGiftGoalStartSheetState extends State<_VoiceGiftGoalStartSheet> {
  int _target = 10000;
  int _durationMinutes = 5;

  static const _targets = [10000, 50000, 100000, 500000];
  static const _durations = [5, 10];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, bottom + 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A0F2E), Color(0xFF12082A)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF66E36F).withValues(alpha: 0.35)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '🎯 ODA HEDEFİ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Hedef miktarı (${widget.jetonLabel})',
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in _targets)
                    _chip(
                      label: _fmtCoins(t),
                      selected: _target == t,
                      onTap: () => setState(() => _target = t),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Süre',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final d in _durations)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: d == 5 ? 8 : 0),
                        child: _chip(
                          label: '$d DK',
                          selected: _durationMinutes == d,
                          onTap: () => setState(() => _durationMinutes = d),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pop(
                  context,
                  VoiceGiftGoalStartResult(
                    targetAmount: _target,
                    durationMinutes: _durationMinutes,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF66E36F),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'HEDEFİ BAŞLAT',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected
          ? const Color(0xFF66E36F).withValues(alpha: 0.25)
          : Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? const Color(0xFF66E36F)
                  : Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? const Color(0xFF66E36F) : Colors.white70,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  static String _fmtCoins(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(0)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return '$v';
  }
}
