import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// GirLive Bot yasaklı kelime belleği.
///
/// * Liste internetten (açık kaynak LDNOOBW Türkçe listesi, CC BY 4.0) çekilir,
///   **bellekte** tutulur ve cihazda önbelleğe alınır (haftada bir tazelenir).
/// * İnternet yoksa önbellek, o da yoksa küçük yerleşik yedek liste kullanılır.
/// * Odanın kendi (admin / yönetici tarafından eklenen) kelimeleri eşleştirme
///   sırasında [extra] olarak eklenir; yani admin kelime ekleyip çıkarınca bot
///   bunu hemen uygular.
class GirLiveWordBank {
  GirLiveWordBank._();

  static final GirLiveWordBank instance = GirLiveWordBank._();

  /// Kaynak: https://github.com/LDNOOBW/List-of-Dirty-Naughty-Obscene-and-Otherwise-Bad-Words
  /// (Creative Commons BY 4.0).
  static const sourceUrl =
      'https://raw.githubusercontent.com/LDNOOBW/List-of-Dirty-Naughty-Obscene-and-Otherwise-Bad-Words/master/tr';

  static const _prefsWords = 'girlive_wordbank_words_v1';
  static const _prefsAt = 'girlive_wordbank_at_v1';
  static const refreshEvery = Duration(days: 7);
  static const _maxWords = 5000;

  /// Çevrimdışı yedek (yalnızca en yaygın ifadeler).
  static const _seed = <String>[
    'amk', 'aq', 'sik', 'siktir', 'sikeyim', 'sikik', 'orospu',
    'orospu çocuğu', 'piç', 'yarrak', 'amcık', 'göt', 'götveren', 'ibne',
    'pezevenk', 'kahpe', 'gavat', 'puşt', 'oç', 'ananı', 'amına',
  ];

  /// Yanlış pozitif vermemesi için güvenli kelimeler (normalize biçimde).
  static const _safe = <String>{'sikayet', 'sikke', 'sikici'};

  final Set<String> _remote = <String>{};
  Set<String> _normalized = _variants(_seed);
  bool _prepared = false;
  Future<void>? _loading;

  /// Bellekteki (internet + önbellek) kelime sayısı.
  int get remoteCount => _remote.length;

  /// Türkçe'ye duyarlı normalizasyon: İ/I düzeltmesi, aksan katlama, tekrar eden
  /// harfleri teke indirme («siiiktir» → «siktir»).
  ///
  /// Noktasız «ı» metinde KORUNUR (aksi hâlde yaygın «sık sık» yasaklı «sik»
  /// sayılırdı); liste kelimeleri ise hem «ı» hem «i» biçimiyle eklenir
  /// ([_variants]).
  @visibleForTesting
  static String normalize(String input) {
    var s = input.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();
    const map = {
      'ç': 'c', 'ğ': 'g', 'ö': 'o', 'ş': 's', 'ü': 'u', 'â': 'a',
      'î': 'i', 'û': 'u',
    };
    final b = StringBuffer();
    String? prev;
    for (final r in s.runes) {
      var ch = String.fromCharCode(r);
      ch = map[ch] ?? ch;
      if (ch == prev) continue;
      b.write(ch);
      prev = ch;
    }
    s = b.toString().trim();
    return s;
  }

  /// Önbelleği yükler; liste eskiyse / boşsa arka planda internetten tazeler.
  /// Çoklu çağrı güvenlidir.
  Future<void> ensureLoaded() {
    return _loading ??= _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getStringList(_prefsWords) ?? const <String>[];
      if (cached.isNotEmpty) _apply(cached);
      final atMs = prefs.getInt(_prefsAt) ?? 0;
      final age = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(atMs));
      if (cached.isEmpty || age > refreshEvery) {
        unawaited(refresh());
      }
    } catch (_) {
      unawaited(refresh());
    } finally {
      _prepared = true;
    }
  }

  /// Listeyi internetten çekip belleğe + önbelleğe yazar. Başarısızsa mevcut
  /// liste korunur.
  Future<bool> refresh({Dio? client}) async {
    final dio = client ??
        Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 12),
          responseType: ResponseType.plain,
        ));
    try {
      final res = await dio.get<String>(sourceUrl);
      final body = res.data ?? '';
      final words = parseList(body);
      if (words.isEmpty) return false;
      _apply(words);
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(_prefsWords, words);
        await prefs.setInt(_prefsAt, DateTime.now().millisecondsSinceEpoch);
      } catch (_) {}
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Satır satır liste → temiz kelime dizisi.
  @visibleForTesting
  static List<String> parseList(String body) {
    final out = <String>[];
    final seen = <String>{};
    for (final line in body.split(RegExp(r'\r?\n'))) {
      final w = line.trim();
      if (w.isEmpty || w.startsWith('#') || w.length > 40) continue;
      final n = normalize(w);
      if (n.length < 2 || !seen.add(n)) continue;
      out.add(w);
      if (out.length >= _maxWords) break;
    }
    return out;
  }

  /// Liste kelimesi → normalize + «ı→i» biçimi (kullanıcı «amcık» yerine
  /// «amcik» yazsa da yakalansın).
  static Set<String> _variants(Iterable<String> words) {
    final out = <String>{};
    for (final w in words) {
      final n = normalize(w);
      if (n.length < 2) continue;
      out
        ..add(n)
        ..add(n.replaceAll('ı', 'i'));
    }
    return out;
  }

  void _apply(List<String> words) {
    _remote
      ..clear()
      ..addAll(words);
    _normalized = _variants([..._seed, ...words]);
  }

  /// Hazır mı? (İlk `ensureLoaded` bitti mi.)
  bool get isPrepared => _prepared;

  /// Mesajdaki ilk yasaklı kelime; yoksa `null`.
  ///
  /// Kelime sınırlarında eşleşir: 4+ harfli yasak kelimeler ekli hâlleriyle de
  /// yakalanır («orospusu»); kısa olanlar yalnız tam kelime olarak.
  String? firstMatch(String text, {Iterable<String> extra = const []}) {
    final norm = normalize(text);
    if (norm.isEmpty) return null;
    final tokens = norm
        .split(RegExp(r'[^a-z0-9ı]+'))
        .where((t) => t.isNotEmpty)
        .toList(growable: false);
    if (tokens.isEmpty) return null;
    final joined = ' ${tokens.join(' ')} ';

    final all = <String>{..._normalized, ..._variants(extra)};

    for (final bad in all) {
      if (_safe.contains(bad)) continue;
      if (bad.contains(' ')) {
        if (joined.contains(' $bad ')) return bad;
        continue;
      }
      for (final t in tokens) {
        if (_safe.contains(t)) continue;
        if (t == bad) return bad;
        if (bad.length >= 4 && t.startsWith(bad)) return bad;
      }
    }
    return null;
  }

  bool containsBanned(String text, {Iterable<String> extra = const []}) =>
      firstMatch(text, extra: extra) != null;
}
