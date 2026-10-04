import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/util/json_util.dart';
import '../../../../core/widgets/mock_ui_kit.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../providers/parity_providers.dart';
import '../widgets/parity_widgets.dart';

/// Rüya trendleri (en çok bakılan / konuşulan, anahtar kelimeler, ruh hâlleri).
class DreamTrendsPage extends ConsumerStatefulWidget {
  const DreamTrendsPage({super.key});

  @override
  ConsumerState<DreamTrendsPage> createState() => _DreamTrendsPageState();
}

class _DreamTrendsPageState extends ConsumerState<DreamTrendsPage> {
  String _period = '7';

  String get _path => '${ApiEndpoints.dreamsTrends}?period=$_period';

  @override
  Widget build(BuildContext context) {
    final v = ref.watch(parityMapProvider(_path));
    return MockScaffold(
      title: 'Rüya Trendleri',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: '1', label: Text('Bugün')),
                ButtonSegment(value: '7', label: Text('7 gün')),
                ButtonSegment(value: '30', label: Text('30 gün')),
              ],
              selected: {_period},
              onSelectionChanged: (s) => setState(() => _period = s.first),
            ),
          ),
          Expanded(
            child: ParityAsync<Map<String, dynamic>>(
              value: v,
              onRetry: () => ref.invalidate(parityMapProvider(_path)),
              builder: (d) {
                final trending = asJsonList(d['trendingDreams']);
                final discussed = asJsonList(d['mostDiscussed']);
                final keywords = asJsonList(d['trendingKeywords']);
                final moods = asJsonList(d['moodStats']);
                final exp = asJsonMap(d['experienceStats']);
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(parityMapProvider(_path)),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 32),
                    children: [
                      _title('🔥 En çok bakılanlar'),
                      for (final e in trending)
                        _DreamTile(e, trailing: '${asInt(e['recentViews'])} görüntülenme'),
                      if (discussed.isNotEmpty) _title('💬 En çok konuşulanlar'),
                      for (final e in discussed)
                        _DreamTile(e, trailing: '${asInt(e['commentCount'])} yorum'),
                      if (keywords.isNotEmpty) ...[
                        _title('🔑 Popüler semboller'),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final k in keywords)
                              ParityChip('${k['keyword']} · ${asInt(k['count'])}'),
                          ],
                        ),
                      ],
                      if (moods.isNotEmpty) ...[
                        _title('😴 Günlük ruh halleri'),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final m in moods)
                              ParityChip('${m['mood']} · ${asInt(m['count'])}'),
                          ],
                        ),
                      ],
                      _title('✅ Deneyimler'),
                      ParityCard(
                        child: Text(
                          '${asInt(exp['totalExperiences'])} deneyim · '
                          '${asInt(exp['cameTrue'])} çıktı · '
                          '${asInt(exp['didNotComeTrue'])} çıkmadı',
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _title(String t) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 8),
        child: Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
      );
}

class _DreamTile extends StatelessWidget {
  const _DreamTile(this.d, {required this.trailing});
  final Map<String, dynamic> d;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final slug = d['slug']?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ParityCard(
        onTap: slug.isEmpty ? null : () => context.push('/ruya/$slug/yorumlar'),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d['title']?.toString() ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  if ((d['summary']?.toString() ?? '').isNotEmpty)
                    Text(d['summary'].toString(),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(trailing, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

/// Yorumlar + deneyimler (rüya slug'ına göre).
class DreamCommentsPage extends ConsumerStatefulWidget {
  const DreamCommentsPage({super.key, required this.slug});
  final String slug;

  @override
  ConsumerState<DreamCommentsPage> createState() => _DreamCommentsPageState();
}

class _DreamCommentsPageState extends ConsumerState<DreamCommentsPage> {
  final _ctl = TextEditingController();
  String _type = 'yorum';
  bool? _cameTrue;
  bool _busy = false;

  String get _path => ApiEndpoints.dreamComments(widget.slug);

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctl.text.trim();
    if (text.length < 3) {
      parityToast(context, 'Yorum en az 3 karakter olmalı');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(parityApiProvider).rawPost(_path, {
        'content': text,
        'experienceType': _type,
        if (_type == 'deneyim' && _cameTrue != null) 'didComeTrue': _cameTrue,
      });
      _ctl.clear();
      ref.invalidate(parityMapProvider(_path));
    } catch (e) {
      if (mounted) parityToast(context, ApiException.userMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = ref.watch(parityMapProvider(_path));
    return MockScaffold(
      title: 'Rüya Yorumları',
      body: Column(
        children: [
          Expanded(
            child: ParityAsync<Map<String, dynamic>>(
              value: v,
              onRetry: () => ref.invalidate(parityMapProvider(_path)),
              builder: (d) {
                final list = asJsonList(d['comments']);
                if (list.isEmpty) {
                  return const ParityMessage(
                    icon: Icons.chat_bubble_outline_rounded,
                    text: 'İlk yorumu sen yaz',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final c = list[i];
                    final u = asJsonMap(c['user']);
                    return ParityCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          UserAvatar(url: u['image']?.toString(), radius: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(u['name']?.toString() ?? 'Kullanıcı',
                                    style: const TextStyle(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text(c['content']?.toString() ?? ''),
                                if (c['experienceType'] == 'deneyim')
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      c['didComeTrue'] == true
                                          ? '✅ Gerçek oldu'
                                          : c['didComeTrue'] == false
                                              ? '❌ Gerçek olmadı'
                                              : 'Deneyim',
                                      style: TextStyle(color: context.colors.onSurfaceMuted),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Yorum'),
                        selected: _type == 'yorum',
                        onSelected: (_) => setState(() => _type = 'yorum'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Deneyim'),
                        selected: _type == 'deneyim',
                        onSelected: (_) => setState(() => _type = 'deneyim'),
                      ),
                      if (_type == 'deneyim') ...[
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Çıktı'),
                          selected: _cameTrue == true,
                          onSelected: (_) => setState(() => _cameTrue = true),
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: const Text('Çıkmadı'),
                          selected: _cameTrue == false,
                          onSelected: (_) => setState(() => _cameTrue = false),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ctl,
                          minLines: 1,
                          maxLines: 4,
                          maxLength: 1000,
                          decoration: const InputDecoration(
                            hintText: 'Yorum yaz…',
                            border: OutlineInputBorder(),
                            isDense: true,
                            counterText: '',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _busy ? null : _send,
                        icon: const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Yapay zekâ ile yeni rüya sembolü yorumu üret.
class DreamGeneratePage extends ConsumerStatefulWidget {
  const DreamGeneratePage({super.key});

  @override
  ConsumerState<DreamGeneratePage> createState() => _DreamGeneratePageState();
}

class _DreamGeneratePageState extends ConsumerState<DreamGeneratePage> {
  final _ctl = TextEditingController();
  bool _busy = false;
  Map<String, dynamic>? _dream;

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    final q = _ctl.text.trim();
    if (q.length < 2) return;
    setState(() {
      _busy = true;
      _dream = null;
    });
    try {
      final res = await ref.read(parityApiProvider).rawPostResult(
        ApiEndpoints.dreamsGenerate,
        {'query': q},
      );
      setState(() => _dream = asJsonMap(res['dream']));
    } catch (e) {
      if (mounted) parityToast(context, ApiException.userMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _dream;
    return MockScaffold(
      title: 'Rüya Yorumu Üret',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 32),
        children: [
          TextField(
            controller: _ctl,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _go(),
            decoration: const InputDecoration(
              labelText: 'Rüyada gördüğün şey (ör. yılan, uçmak)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _busy ? null : _go,
            icon: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome_rounded),
            label: const Text('Yorumla'),
          ),
          if (d != null) ...[
            const SizedBox(height: 16),
            ParityCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d['title']?.toString() ?? '',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(d['summary']?.toString() ?? ''),
                  if ((d['content']?.toString() ?? '').isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(d['content'].toString()),
                  ],
                  if ((d['slug']?.toString() ?? '').isNotEmpty)
                    TextButton(
                      onPressed: () => context.push('/ruya/${d['slug']}/yorumlar'),
                      child: const Text('Yorumları gör'),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
