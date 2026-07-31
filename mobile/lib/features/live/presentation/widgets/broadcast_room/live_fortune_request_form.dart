import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../domain/entities/live_fortune_request_entity.dart';
import '../../../../live_psychics/presentation/widgets/psychic_fortune_types.dart';

/// İzleyici — canlı fal isteği formu + jeton onayı.
class LiveFortuneRequestForm extends StatefulWidget {
  const LiveFortuneRequestForm({
    super.key,
    required this.onSubmit,
    this.initialFortuneType,
    this.balance,
  });

  final Future<bool> Function({
    required String displayName,
    required String question,
    required String fortuneType,
    required LiveFortunePriority priority,
    required int jetonCost,
  }) onSubmit;

  final String? initialFortuneType;
  final int? balance;

  @override
  State<LiveFortuneRequestForm> createState() => _LiveFortuneRequestFormState();
}

class _LiveFortuneRequestFormState extends State<LiveFortuneRequestForm> {
  final _displayName = TextEditingController();
  final _question = TextEditingController();
  var _fortuneType = 'tarot';
  var _priority = LiveFortunePriority.standard;
  var _jetonAmount = 100.0; // 20-1000 serbest miktar
  var _loading = false;

  @override
  void initState() {
    super.initState();
    _fortuneType = widget.initialFortuneType ?? 'tarot';
  }

  @override
  void dispose() {
    _displayName.dispose();
    _question.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final name = _displayName.text.trim();
    final q = _question.text.trim();
    if (name.length < 2) {
      _snack('Görünecek isim en az 2 karakter olmalı');
      return;
    }
    if (q.length < 5) {
      _snack('Fal sorusu en az 5 karakter olmalı');
      return;
    }

    final cost = _jetonAmount.round();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Jeton onayı'),
        content: Text(
          '$cost Jeton düşülecek. Onaylıyor musunuz?\n\n'
          'Gerçek kullanıcı adınız yayıncıya gösterilmez.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Onayla'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _loading = true);
    HapticFeedback.mediumImpact();
    try {
      final success = await widget.onSubmit(
        displayName: name,
        question: q,
        fortuneType: _fortuneType,
        priority: _priority,
        jetonCost: cost,
      );
      if (!mounted) return;
      if (success) {
        _snack('Fal isteğiniz gönderildi');
        _question.clear();
      } else if (mounted) {
        _snack('Fal isteği gönderilemedi. Lütfen tekrar deneyin.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final types = psychicFortuneTypes;
    final balance = widget.balance;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Fal İsteği',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              _field(_displayName, 'Görünecek İsim', 'Örn: MaviKelebek'),
              const SizedBox(height: 8),
              _field(_question, 'Fal Sorusu', 'Sorunuzu yazın…', maxLines: 3),
              const SizedBox(height: 8),
              Text(
                'Fal Türü Seçin',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              _FortuneTypeGrid(
                types: types,
                selected: _fortuneType,
                onSelected: (key) => setState(() => _fortuneType = key),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<LiveFortunePriority>(
                initialValue: _priority,
                dropdownColor: const Color(0xFF1A1030),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: _decoration('Öncelik Türü'),
                items: const [
                  LiveFortunePriority.standard,
                  LiveFortunePriority.priority,
                  LiveFortunePriority.urgent,
                  LiveFortunePriority.vip,
                  LiveFortunePriority.superFal,
                ]
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(p.label),
                      ),
                    )
                    .toList(),
                onChanged: (v) =>
                    setState(() => _priority = v ?? LiveFortunePriority.standard),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'İstek Jetonu',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_jetonAmount.round()} Jeton',
                    style: const TextStyle(
                      color: Color(0xFFFFD54F),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _jetonAmount,
                min: 20,
                max: 1000,
                divisions: 98, // 20'şer adım (20,30,...1000 ≈ 10'luk)
                activeColor: const Color(0xFF7C3AED),
                label: '${_jetonAmount.round()} Jeton',
                onChanged: (v) => setState(() => _jetonAmount = v),
              ),
              Text(
                'Daha yüksek jeton, falının yayıncı sırasında öne çıkmasını sağlar (20-1000).',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 10,
                ),
              ),
              if (balance != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Bakiyeniz: $balance Jeton',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 11,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loading ? null : _send,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Gönder',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05, end: 0);
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
      );

  Widget _field(
    TextEditingController c,
    String label,
    String hint, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: _decoration(label).copyWith(hintText: hint),
    );
  }
}

class _FortuneTypeGrid extends StatelessWidget {
  const _FortuneTypeGrid({
    required this.types,
    required this.selected,
    required this.onSelected,
  });

  final List<PsychicFortuneType> types;
  final String selected;
  final ValueChanged<String> onSelected;

  static IconData _iconFor(String key) => switch (key) {
        'coffee' => Icons.coffee_rounded,
        'tarot' => Icons.style_rounded,
        'astrology' => Icons.nightlight_round,
        'palmistry' => Icons.back_hand_rounded,
        'numerology' => Icons.pin_rounded,
        _ => Icons.auto_awesome_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final t in types)
          GestureDetector(
            onTap: () => onSelected(t.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 96,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: selected == t.key
                    ? const LinearGradient(
                        colors: [Color(0xFF9C27FF), Color(0xFF7C4DFF)],
                      )
                    : null,
                color: selected == t.key
                    ? null
                    : Colors.white.withValues(alpha: 0.06),
                border: Border.all(
                  color: selected == t.key
                      ? const Color(0xFFB832FF)
                      : Colors.white.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _iconFor(t.key),
                    size: 22,
                    color: selected == t.key
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: selected == t.key
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
