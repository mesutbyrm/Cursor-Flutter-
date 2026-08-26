import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/home_zodiac_signs.dart';
import '../providers/home_providers.dart';
import '../theme/home_approved_design.dart';

/// Burç chip dokunuşunda günlük yorum — `POST /api/horoscope/daily`.
Future<void> showHomeHoroscopeDailySheet(
  BuildContext context,
  WidgetRef ref, {
  required String signName,
  required String glyph,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: HomeApprovedDesign.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return _HoroscopeSheet(
        signName: signName,
        glyph: glyph,
        apiSign: HomeZodiacSigns.apiValueFor(signName),
      );
    },
  );
}

class _HoroscopeSheet extends ConsumerStatefulWidget {
  const _HoroscopeSheet({
    required this.signName,
    required this.glyph,
    required this.apiSign,
  });

  final String signName;
  final String glyph;
  final String apiSign;

  @override
  ConsumerState<_HoroscopeSheet> createState() => _HoroscopeSheetState();
}

class _HoroscopeSheetState extends ConsumerState<_HoroscopeSheet> {
  late Future<String?> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<String?> _fetch() {
    return ref.read(homeRemoteProvider).fetchDailyHoroscope(widget.apiSign);
  }

  void _retry() {
    setState(() {
      _future = _fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: HomeApprovedDesign.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(widget.glyph, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${widget.signName} — Günlük Burç',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: HomeApprovedDesign.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<String?>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final text = snap.data?.trim();
                if (snap.hasError || text == null || text.isEmpty) {
                  return Column(
                    children: [
                      const Text(
                        'Günlük yorum şu an yüklenemedi. Detaylı burç falına geçebilirsin.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: HomeApprovedDesign.textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: _retry,
                        child: const Text('Tekrar dene'),
                      ),
                    ],
                  );
                }
                return Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: HomeApprovedDesign.textPrimary,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/fortune/yildiz-haritasi');
              },
              child: const Text('Detaylı Yıldızname'),
            ),
          ],
        ),
      ),
    );
  }
}
