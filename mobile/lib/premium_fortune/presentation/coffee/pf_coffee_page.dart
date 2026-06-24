import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/config/pf_config.dart';
import '../../core/theme/pf_theme.dart';
import '../../domain/entities/pf_coffee_reading.dart';
import '../coffee/pf_coffee_view_model.dart';
import '../widgets/pf_glass_card.dart';
import '../widgets/pf_section_header.dart';

class PfCoffeePage extends ConsumerStatefulWidget {
  const PfCoffeePage({super.key});

  @override
  ConsumerState<PfCoffeePage> createState() => _PfCoffeePageState();
}

class _PfCoffeePageState extends ConsumerState<PfCoffeePage> {
  String? _localImagePath;
  bool _analyzing = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file != null) {
      setState(() => _localImagePath = file.path);
    }
  }

  Future<void> _analyze() async {
    if (_localImagePath == null) return;
    setState(() => _analyzing = true);
    final result = await ref
        .read(pfCoffeeViewModelProvider.notifier)
        .analyzePhoto(_localImagePath!);
    if (!mounted) return;
    setState(() => _analyzing = false);

    if (result.error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.error!)));
      return;
    }
    if (result.reading != null) {
      context.push('/premium/coffee/result', extra: result.reading);
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(pfCoffeeViewModelProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Kahve Falı')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: PfGlassCard(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: PfTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: PfTheme.purple.withValues(alpha: 0.3),
                          width: 2,
                          strokeAlign: BorderSide.strokeAlignInside,
                        ),
                        image: _localImagePath != null
                            ? DecorationImage(
                                image: FileImage(File(_localImagePath!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _localImagePath == null
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_rounded,
                                    size: 48, color: Colors.white38),
                                SizedBox(height: 8),
                                Text('Fincan fotoğrafı yükle',
                                    style: TextStyle(color: Colors.white54)),
                              ],
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'AI fincanınızı analiz edecek — aşk, para, kariyer ve sağlık',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white60,
                        ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _localImagePath == null || _analyzing
                          ? null
                          : _analyze,
                      icon: _analyzing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome_rounded),
                      label: Text(
                        _analyzing
                            ? 'Analiz ediliyor...'
                            : 'Falıma Bak (${PfConfig.coffeeReadingCost} kredi)',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const PfSectionHeader(title: 'Geçmiş', subtitle: 'Son fal okumalarınız'),
          history.when(
            data: (items) => items.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Henüz fal geçmişiniz yok',
                        style: TextStyle(color: Colors.white54)),
                  )
                : Column(
                    children: items
                        .map((r) => _HistoryTile(reading: r))
                        .toList(),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(20),
              child: Text('$e'),
            ),
          ),
        ],
      ),
    );
  }
}

class PfCoffeeResultPage extends StatelessWidget {
  const PfCoffeeResultPage({super.key, required this.reading});

  final PfCoffeeReading reading;

  @override
  Widget build(BuildContext context) {
    final sections = [
      ('Özet', reading.summary, Icons.auto_awesome_rounded),
      ('Aşk', reading.love, Icons.favorite_rounded),
      ('Para', reading.money, Icons.payments_rounded),
      ('Kariyer', reading.career, Icons.work_rounded),
      ('Sağlık', reading.health, Icons.favorite_border_rounded),
    ];

    return Scaffold(
      backgroundColor: PfTheme.surface,
      appBar: AppBar(title: const Text('Fal Sonucu')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (reading.imageUrl.isNotEmpty && !reading.imageUrl.startsWith('/'))
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                reading.imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          const SizedBox(height: 16),
          ...sections.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PfGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(s.$3, color: PfTheme.gold, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          s.$1,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.$2,
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.reading});

  final PfCoffeeReading reading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: PfGlassCard(
        onTap: () => context.push('/premium/coffee/result', extra: reading),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.coffee_rounded, color: PfTheme.gold),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reading.summary.length > 60
                        ? '${reading.summary.substring(0, 60)}...'
                        : reading.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _formatDate(reading.createdAt),
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day}.${d.month}.${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
}
