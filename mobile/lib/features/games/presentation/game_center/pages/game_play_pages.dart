import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../core/theme/app_theme_extensions.dart';
import '../../../../../core/widgets/discover_tab_layout.dart';
import '../../../domain/game_center_models.dart';
import '../providers/game_center_providers.dart';

// ─── Kader Çarkı ───────────────────────────────────────────────────────────

class WheelOfFortunePage extends ConsumerStatefulWidget {
  const WheelOfFortunePage({super.key});

  @override
  ConsumerState<WheelOfFortunePage> createState() => _WheelOfFortunePageState();
}

class _WheelOfFortunePageState extends ConsumerState<WheelOfFortunePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;
  final _prizes = const [5, 10, 25, 50, 100, 0, 15, 30];
  String? _result;
  bool _spinning = false;
  bool _freeUsed = false;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  Future<void> _doSpin({required bool paid}) async {
    if (_spinning) return;
    if (paid) {
      final balance = await ref.read(gameCenterJetonProvider.future);
      if (!mounted) return;
      if (balance < 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('10 jeton gerekli')),
        );
        return;
      }
    } else if (_freeUsed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ücretsiz çevirme hakkın bitti')),
      );
      return;
    }

    setState(() {
      _spinning = true;
      _result = null;
      if (!paid) _freeUsed = true;
    });

    final index = Random().nextInt(_prizes.length);
    final turns = 4 + Random().nextDouble();
    final target = turns + (index / _prizes.length);

    _spin.reset();
    await _spin.animateTo(target, curve: Curves.easeOutCubic);

    final won = _prizes[index];
    setState(() {
      _spinning = false;
      _result = won > 0 ? '$won Jeton kazandın!' : 'Bir dahaki sefere!';
    });

    await recordGameCenterResult(
      ref,
      GameResultPayload(
        gameId: 'kader-carki',
        score: won,
        won: won > 0,
        jetonDelta: won,
        metadata: {'paid': paid},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DiscoverSubPage(
      title: 'Kader Çarkı',
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RotationTransition(
              turns: _spin,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const SweepGradient(
                    colors: [
                      Color(0xFFF59E0B),
                      Color(0xFFEC4899),
                      Color(0xFF8B5CF6),
                      Color(0xFF0EA5E9),
                      Color(0xFF10B981),
                      Color(0xFFF59E0B),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: context.colors.primary.withValues(alpha: 0.4),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: const Icon(Icons.star_rounded, size: 64, color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),
            if (_result != null)
              Text(
                _result!,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: context.coinGold,
                ),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _spinning ? null : () => _doSpin(paid: false),
              child: const Text('ÜCRETSİZ ÇEVİR'),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: _spinning ? null : () => _doSpin(paid: true),
              child: const Text('10 JETON İLE ÇEVİR'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bilgi Yarışması ───────────────────────────────────────────────────────

class QuizGamePage extends ConsumerStatefulWidget {
  const QuizGamePage({super.key});

  @override
  ConsumerState<QuizGamePage> createState() => _QuizGamePageState();
}

class _QuizGamePageState extends ConsumerState<QuizGamePage> {
  static const _questions = [
    _QuizQ('Türkiye\'nin başkenti?', ['İstanbul', 'Ankara', 'İzmir', 'Bursa'], 1),
    _QuizQ('Ay\'a ilk ayak basan?', ['Armstrong', 'Aldrin', 'Gagarin', 'Collins'], 0),
    _QuizQ('Pi sayısının ilk iki basamağı?', ['3.12', '3.14', '3.16', '3.18'], 1),
    _QuizQ('Osmanlı\'nın kurucusu?', ['Fatih', 'Kanuni', 'Osman Bey', 'Yavuz'], 2),
  ];

  int _index = 0;
  int _score = 0;

  void _answer(int i) {
    if (i == _questions[_index].correct) _score += 100;
    if (_index + 1 >= _questions.length) {
      _finish();
      return;
    }
    setState(() => _index++);
  }

  Future<void> _finish() async {
    await recordGameCenterResult(
      ref,
      GameResultPayload(gameId: 'quiz', score: _score, won: _score >= 200),
    );
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yarışma bitti'),
        content: Text('Skorun: $_score'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_index];
    return DiscoverSubPage(
      title: 'Bilgi Yarışması',
      subtitle: 'Soru ${_index + 1}/${_questions.length}',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(value: (_index + 1) / _questions.length),
          const SizedBox(height: 24),
          Text(
            q.text,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 20),
          ...List.generate(q.options.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FilledButton.tonal(
                onPressed: () => _answer(i),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(q.options[i]),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _QuizQ {
  const _QuizQ(this.text, this.options, this.correct);
  final String text;
  final List<String> options;
  final int correct;
}

// ─── Kelime Düellosu ───────────────────────────────────────────────────────

class WordDuelPage extends ConsumerStatefulWidget {
  const WordDuelPage({super.key});

  @override
  ConsumerState<WordDuelPage> createState() => _WordDuelPageState();
}

class _WordDuelPageState extends ConsumerState<WordDuelPage> {
  static const _target = 'PANDA';
  final _letters = List.filled(5, '');
  int _cursor = 0;
  static const _keys = [
    ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
    ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
    ['Z', 'X', 'C', 'V', 'B', 'N', 'M'],
  ];

  void _tap(String ch) {
    if (_cursor >= 5) return;
    setState(() {
      _letters[_cursor] = ch;
      _cursor++;
    });
  }

  void _backspace() {
    if (_cursor == 0) return;
    setState(() {
      _cursor--;
      _letters[_cursor] = '';
    });
  }

  Future<void> _submit() async {
    final guess = _letters.join();
    if (guess.length < 5) return;
    final won = guess == _target;
    final score = won ? 500 : 50;
    await recordGameCenterResult(
      ref,
      GameResultPayload(gameId: 'kelime-duellosu', score: score, won: won),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(won ? 'Doğru! +$score puan' : 'Kelime: $_target'),
      ),
    );
    if (won) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return DiscoverSubPage(
      title: 'Kelime Düellosu',
      subtitle: '01:25',
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              return Container(
                width: 48,
                height: 48,
                margin: const EdgeInsets.all(4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: context.colors.primary, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _letters[i],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              );
            }),
          ),
          const Spacer(),
          for (final row in _keys)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 4,
                children: row
                    .map(
                      (k) => ActionChip(
                        label: Text(k),
                        onPressed: () => _tap(k),
                      ),
                    )
                    .toList(),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _backspace,
                  child: const Text('Sil'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: _submit,
                  child: const Text('Gönder'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Aşk Uyumu ─────────────────────────────────────────────────────────────

class LoveMatchPage extends ConsumerStatefulWidget {
  const LoveMatchPage({super.key});

  @override
  ConsumerState<LoveMatchPage> createState() => _LoveMatchPageState();
}

class _LoveMatchPageState extends ConsumerState<LoveMatchPage> {
  final _a = TextEditingController();
  final _b = TextEditingController();
  int? _percent;

  Future<void> _calc() async {
    final seed = '${_a.text.trim()}_${_b.text.trim()}'.hashCode.abs();
    final pct = 55 + (seed % 46);
    setState(() => _percent = pct);
    await recordGameCenterResult(
      ref,
      GameResultPayload(
        gameId: 'ask-uyumu',
        score: pct,
        metadata: {'pair': '${_a.text}|${_b.text}'},
      ),
    );
  }

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DiscoverSubPage(
      title: 'Aşk Uyumu',
      body: Column(
        children: [
          TextField(
            controller: _a,
            decoration: const InputDecoration(labelText: 'Sen'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _b,
            decoration: const InputDecoration(labelText: 'Partner'),
          ),
          const SizedBox(height: 24),
          if (_percent != null) ...[
            Icon(Icons.favorite_rounded, size: 64, color: context.accentPink),
            Text(
              '%$_percent Harika Bir Uyum!',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _percent = null),
                    child: const Text('Tekrar Dene'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Share.share(
                      '${_a.text} & ${_b.text} — %$_percent uyum! #Canlifal',
                    ),
                    child: const Text('Paylaş'),
                  ),
                ),
              ],
            ),
          ] else
            FilledButton(
              onPressed: _calc,
              child: const Text('Uyumu Hesapla'),
            ),
        ],
      ),
    );
  }
}

// ─── Tavla ───────────────────────────────────────────────────────────────────

class BackgammonPage extends ConsumerWidget {
  const BackgammonPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DiscoverSubPage(
      title: 'Tavla',
      body: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF92400E).withValues(alpha: 0.6),
                    const Color(0xFF78350F).withValues(alpha: 0.4),
                  ],
                ),
              ),
              child: const Center(
                child: Icon(Icons.grid_on_rounded, size: 120, color: Colors.white24),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _DiceFace(value: 3),
              SizedBox(width: 12),
              _DiceFace(value: 5),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () async {
              final room = await ref
                  .read(gameCenterRepositoryProvider)
                  .createLiveRoom('tavla');
              if (!context.mounted) return;
              if (room != null) {
                context.push(
                  '/games-room/${room.id}?title=${Uri.encodeComponent(room.title)}',
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Oda oluşturulamadı')),
                );
              }
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Çok Oyunculu Oda Aç'),
          ),
        ],
      ),
    );
  }
}

class _DiceFace extends StatelessWidget {
  const _DiceFace({required this.value});
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          '$value',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}

// ─── Canlı oyunlar ─────────────────────────────────────────────────────────

class LiveQuizRoomPage extends ConsumerWidget {
  const LiveQuizRoomPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _LiveRoomLauncher(
      title: 'Oda Bilgi Yarışması',
      gameId: 'quiz-1v1',
      prizeLabel: '500 Jeton ödül',
    );
  }
}

class PkPredictionPage extends ConsumerWidget {
  const PkPredictionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _LiveRoomLauncher(
      title: 'PK Tahmin Oyunu',
      gameId: 'pk-tahmin',
      prizeLabel: 'PK skorunu tahmin et',
    );
  }
}

class LiveBingoPage extends ConsumerWidget {
  const LiveBingoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _LiveRoomLauncher(
      title: 'Canlı Tombala',
      gameId: 'tombala',
      prizeLabel: 'Çok oyunculu tombala',
    );
  }
}

class _LiveRoomLauncher extends ConsumerWidget {
  const _LiveRoomLauncher({
    required this.title,
    required this.gameId,
    required this.prizeLabel,
  });

  final String title;
  final String gameId;
  final String prizeLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms = ref.watch(gameCenterLiveRoomsProvider);
    return DiscoverSubPage(
      title: title,
      subtitle: prizeLabel,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: () async {
              final room = await ref
                  .read(gameCenterRepositoryProvider)
                  .createLiveRoom(gameId);
              if (!context.mounted) return;
              if (room != null) {
                context.push(
                  '/games-room/${room.id}?title=${Uri.encodeComponent(room.title)}',
                );
              }
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Oda Oluştur'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final room = await ref
                  .read(gameCenterRepositoryProvider)
                  .createLiveRoom(gameId);
              if (!context.mounted) return;
              if (room != null) {
                context.push(
                  '/games-room/${room.id}?title=${Uri.encodeComponent(room.title)}',
                );
              }
            },
            icon: const Icon(Icons.shuffle_rounded),
            label: const Text('Otomatik Eşleş'),
          ),
          const SizedBox(height: 20),
          const Text('Açık odalar', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Expanded(
            child: rooms.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Odalar yüklenemedi')),
              data: (list) {
                final filtered = list
                    .where((r) => r.gameId.contains(gameId.split('-').first))
                    .toList();
                if (filtered.isEmpty) {
                  return const Center(child: Text('Henüz açık oda yok'));
                }
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final room = filtered[i];
                    return Card(
                      child: ListTile(
                        title: Text(room.title),
                        subtitle: Text(
                          '${room.playerCount}/${room.maxPlayers} oyuncu',
                        ),
                        trailing: const Text('Katıl'),
                        onTap: () async {
                          await ref
                              .read(gameCenterRepositoryProvider)
                              .joinLiveRoom(room.id);
                          if (!context.mounted) return;
                          context.push(
                            '/games-room/${room.id}?title=${Uri.encodeComponent(room.title)}',
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Ödüllü oyunlar ────────────────────────────────────────────────────────

class TreasureChestPage extends ConsumerStatefulWidget {
  const TreasureChestPage({super.key});

  @override
  ConsumerState<TreasureChestPage> createState() => _TreasureChestPageState();
}

class _TreasureChestPageState extends ConsumerState<TreasureChestPage> {
  bool _opened = false;
  int _reward = 0;

  Future<void> _open() async {
    if (_opened) return;
    _reward = 20 + Random().nextInt(81);
    setState(() => _opened = true);
    await recordGameCenterResult(
      ref,
      GameResultPayload(
        gameId: 'hazine-sandigi',
        score: _reward,
        won: true,
        jetonDelta: _reward,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DiscoverSubPage(
      title: 'Günlük Hazine Sandığı',
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _opened ? Icons.lock_open_rounded : Icons.inventory_2_rounded,
              size: 100,
              color: context.coinGold,
            ),
            const SizedBox(height: 20),
            Text(
              _opened ? '$_reward Jeton kazandın!' : 'Sandığı aç ve ödülünü al',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _opened ? null : _open,
              child: Text(_opened ? 'Yarın tekrar gel' : 'Sandığı Aç'),
            ),
          ],
        ),
      ),
    );
  }
}

class LuckyDicePage extends ConsumerStatefulWidget {
  const LuckyDicePage({super.key});

  @override
  ConsumerState<LuckyDicePage> createState() => _LuckyDicePageState();
}

class _LuckyDicePageState extends ConsumerState<LuckyDicePage> {
  int? _d1;
  int? _d2;

  Future<void> _roll() async {
    final balance = await ref.read(gameCenterJetonProvider.future);
    if (!mounted) return;
    if (balance < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('5 jeton gerekli')),
      );
      return;
    }
    final a = 1 + Random().nextInt(6);
    final b = 1 + Random().nextInt(6);
    final win = (a + b) * 5;
    setState(() {
      _d1 = a;
      _d2 = b;
    });
    await recordGameCenterResult(
      ref,
      GameResultPayload(
        gameId: 'sansli-zar',
        score: win,
        jetonDelta: win - 5,
        metadata: {'dice': [a, b]},
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('+$win jeton (5 jeton harcandı)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DiscoverSubPage(
      title: 'Şanslı Zar',
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _DiceFace(value: _d1 ?? 1),
                const SizedBox(width: 16),
                _DiceFace(value: _d2 ?? 1),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _roll,
              child: const Text('Zar At (5 Jeton)'),
            ),
          ],
        ),
      ),
    );
  }
}
