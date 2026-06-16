import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/pf_providers.dart';
import '../../core/theme/pf_theme.dart';
import '../../data/datasources/pf_astrology_datasource.dart';
import '../../domain/entities/pf_astrology.dart';
import '../widgets/pf_glass_card.dart';
import '../widgets/pf_section_header.dart';

final pfSelectedSignProvider = StateProvider<String>((_) => 'Koç');

final pfHoroscopeProvider =
    FutureProvider.family<PfHoroscopeReading?, String>((ref, sign) async {
  final result = await ref.read(pfAstrologyRepositoryProvider).getHoroscope(sign);
  return result.valueOrNull;
});

class PfAstrologyPage extends ConsumerWidget {
  const PfAstrologyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sign = ref.watch(pfSelectedSignProvider);
    final horoscope = ref.watch(pfHoroscopeProvider(sign));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Astroloji')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: PfAstrologyDatasource.signs.length,
              itemBuilder: (context, i) {
                final s = PfAstrologyDatasource.signs[i];
                final selected = s == sign;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(s),
                    selected: selected,
                    onSelected: (_) =>
                        ref.read(pfSelectedSignProvider.notifier).state = s,
                    selectedColor: PfTheme.purple,
                  ),
                );
              },
            ),
          ),
          horoscope.when(
            data: (h) {
              if (h == null) return const SizedBox.shrink();
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: PfGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$sign — Günlük',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(h.daily,
                              style: const TextStyle(
                                  color: Colors.white70, height: 1.5)),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: PfGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Haftalık Yorum',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(h.weekly,
                              style: const TextStyle(
                                  color: Colors.white70, height: 1.5)),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('$e'),
          ),
          const PfSectionHeader(title: 'Doğum Haritası'),
          const _BirthChartForm(),
        ],
      ),
    );
  }
}

class _BirthChartForm extends ConsumerStatefulWidget {
  const _BirthChartForm();

  @override
  ConsumerState<_BirthChartForm> createState() => _BirthChartFormState();
}

class _BirthChartFormState extends ConsumerState<_BirthChartForm> {
  final _placeCtrl = TextEditingController();
  DateTime _birthDate = DateTime(1995, 6, 15);
  PfBirthChart? _chart;
  bool _loading = false;

  @override
  void dispose() {
    _placeCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final user = ref.read(pfEffectiveUserProvider);
    if (user == null) return;
    setState(() => _loading = true);
    final result = await ref.read(pfAstrologyRepositoryProvider).createBirthChart(
          userId: user.id,
          birthDate: _birthDate,
          birthPlace: _placeCtrl.text.isEmpty ? 'İstanbul' : _placeCtrl.text,
          latitude: 41.0,
          longitude: 29.0,
        );
    if (mounted) {
      setState(() {
        _loading = false;
        _chart = result.valueOrNull;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: PfGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Doğum Tarihi'),
              subtitle: Text(
                '${_birthDate.day}.${_birthDate.month}.${_birthDate.year}',
              ),
              trailing: const Icon(Icons.calendar_today_rounded),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _birthDate,
                  firstDate: DateTime(1920),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _birthDate = picked);
              },
            ),
            TextField(
              controller: _placeCtrl,
              decoration: const InputDecoration(
                labelText: 'Doğum Yeri',
                prefixIcon: Icon(Icons.place_outlined),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _create,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Haritamı Oluştur'),
              ),
            ),
            if (_chart != null) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SignChip('☀️ ${_chart!.sunSign}'),
                  _SignChip('🌙 ${_chart!.moonSign}'),
                  _SignChip('⬆️ ${_chart!.risingSign}'),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _chart!.interpretation,
                style: const TextStyle(color: Colors.white70, height: 1.5),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SignChip extends StatelessWidget {
  const _SignChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: PfTheme.purple.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
