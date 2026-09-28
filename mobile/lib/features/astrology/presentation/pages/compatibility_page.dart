import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/zodiac_sign.dart';
import '../providers/astrology_provider.dart';
import '../widgets/zodiac_selector.dart';
import '../widgets/compatibility_card.dart';
import '../widgets/weekly_compatibility_list.dart';

class CompatibilityPage extends ConsumerWidget {
  const CompatibilityPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPair = ref.watch(selectedZodiacPairProvider);
    final compatibility = ref.watch(currentCompatibilityProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Burç Uyumu'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Zodiac Sign Selectors
            Row(
              children: [
                Expanded(
                  child: ZodiacSelector(
                    label: 'Burç 1',
                    onSelected: (sign) {
                      ref.read(selectedZodiacPairProvider.notifier).state =
                          (sign1: sign, sign2: selectedPair?.sign2 ?? ZodiacSign.aries);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ZodiacSelector(
                    label: 'Burç 2',
                    onSelected: (sign) {
                      ref.read(selectedZodiacPairProvider.notifier).state =
                          (sign1: selectedPair?.sign1 ?? ZodiacSign.aries, sign2: sign);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Compatibility Score
            if (selectedPair != null)
              compatibility.when(
                data: (score) => CompatibilityCard(compatibility: score),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stackTrace) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text('Hata: $error'),
                  ),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'İki burç seçin',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),

            const SizedBox(height: 24),

            // Weekly Compatibility
            if (selectedPair != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bu Haftanın Uyumu',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  WeeklyCompatibilityList(
                    sign1: selectedPair.sign1,
                    sign2: selectedPair.sign2,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
