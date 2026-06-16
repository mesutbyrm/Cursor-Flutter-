import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/pf_config.dart';
import '../../core/di/pf_providers.dart';
import '../../core/theme/pf_theme.dart';
import '../../domain/entities/pf_dream_reading.dart';
import '../widgets/pf_glass_card.dart';

class PfDreamsPage extends ConsumerStatefulWidget {
  const PfDreamsPage({super.key});

  @override
  ConsumerState<PfDreamsPage> createState() => _PfDreamsPageState();
}

class _PfDreamsPageState extends ConsumerState<PfDreamsPage> {
  final _dreamCtrl = TextEditingController();
  bool _loading = false;
  List<PfDreamReading> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final user = ref.read(pfEffectiveUserProvider);
    if (user == null) return;
    final result = await ref.read(pfDreamRepositoryProvider).getHistory(user.id);
    if (mounted) setState(() => _history = result.valueOrNull ?? []);
  }

  Future<void> _interpret() async {
    final text = _dreamCtrl.text.trim();
    if (text.isEmpty) return;
    final user = ref.read(pfEffectiveUserProvider);
    if (user == null) return;

    setState(() => _loading = true);
    final result = await ref.read(pfDreamRepositoryProvider).interpretDream(
          userId: user.id,
          dreamText: text,
        );
    if (!mounted) return;
    setState(() => _loading = false);

    if (result.isFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.failureOrNull?.message ?? 'Hata')),
      );
      return;
    }
    final reading = result.valueOrNull;
    if (reading != null) {
      context.push('/premium/dreams/result', extra: reading);
      _dreamCtrl.clear();
      _loadHistory();
    }
  }

  @override
  void dispose() {
    _dreamCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Rüya Tabiri')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          PfGlassCard(
            child: Column(
              children: [
                TextField(
                  controller: _dreamCtrl,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    hintText: 'Rüyanızı detaylı anlatın...',
                    border: InputBorder.none,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _interpret,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.bedtime_rounded),
                    label: Text(
                      _loading
                          ? 'Yorumlanıyor...'
                          : 'Yorumla (${PfConfig.dreamReadingCost} kredi)',
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_history.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('Geçmiş',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 8),
            ..._history.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: PfGlassCard(
                  onTap: () =>
                      context.push('/premium/dreams/result', extra: r),
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    r.dreamText.length > 80
                        ? '${r.dreamText.substring(0, 80)}...'
                        : r.dreamText,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PfDreamResultPage extends StatelessWidget {
  const PfDreamResultPage({super.key, required this.reading});

  final PfDreamReading reading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PfTheme.surface,
      appBar: AppBar(title: const Text('Rüya Yorumu')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          PfGlassCard(
            child: Text(reading.dreamText,
                style: const TextStyle(
                    fontStyle: FontStyle.italic, color: Colors.white60)),
          ),
          if (reading.symbols.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              children: reading.symbols
                  .map((s) => Chip(label: Text(s)))
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          PfGlassCard(
            child: Text(
              reading.interpretation,
              style: TextStyle(height: 1.6, color: Colors.white.withValues(alpha: 0.8)),
            ),
          ),
        ],
      ),
    );
  }
}
