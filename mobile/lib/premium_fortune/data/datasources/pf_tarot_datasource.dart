import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/firebase/firebase_bootstrap.dart';
import '../../domain/entities/pf_tarot_reading.dart';
import 'openai_datasource.dart';

class PfTarotDatasource {
  PfTarotDatasource({
    FirebaseFirestore? firestore,
    OpenAiDatasource? openAi,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _openAi = openAi ?? OpenAiDatasource();

  final FirebaseFirestore _firestore;
  final OpenAiDatasource _openAi;
  final _uuid = const Uuid();

  static const deck = [
    PfTarotCard(id: 'fool', name: 'Deli', meaning: 'Yeni başlangıçlar, cesaret'),
    PfTarotCard(id: 'magician', name: 'Büyücü', meaning: 'Güç, yaratıcılık'),
    PfTarotCard(id: 'high_priestess', name: 'Başrahibe', meaning: 'Sezgi, gizem'),
    PfTarotCard(id: 'empress', name: 'İmparatoriçe', meaning: 'Bereket, doğurganlık'),
    PfTarotCard(id: 'emperor', name: 'İmparator', meaning: 'Otorite, yapı'),
    PfTarotCard(id: 'lovers', name: 'Aşıklar', meaning: 'Seçim, uyum'),
    PfTarotCard(id: 'chariot', name: 'Savaş Arabası', meaning: 'Zafer, irade'),
    PfTarotCard(id: 'strength', name: 'Güç', meaning: 'Cesaret, sabır'),
    PfTarotCard(id: 'hermit', name: 'Ermiş', meaning: 'İçe dönüş, bilgelik'),
    PfTarotCard(id: 'wheel', name: 'Kader Çarkı', meaning: 'Değişim, şans'),
    PfTarotCard(id: 'justice', name: 'Adalet', meaning: 'Denge, hakikat'),
    PfTarotCard(id: 'hanged', name: 'Asılan Adam', meaning: 'Teslimiyet, bakış açısı'),
    PfTarotCard(id: 'death', name: 'Ölüm', meaning: 'Dönüşüm, yenilenme'),
    PfTarotCard(id: 'temperance', name: 'Denge', meaning: 'Uyum, sabır'),
    PfTarotCard(id: 'devil', name: 'Şeytan', meaning: 'Bağımlılık, gölge'),
    PfTarotCard(id: 'tower', name: 'Kule', meaning: 'Ani değişim, uyanış'),
    PfTarotCard(id: 'star', name: 'Yıldız', meaning: 'Umut, ilham'),
    PfTarotCard(id: 'moon', name: 'Ay', meaning: 'Hayal, belirsizlik'),
    PfTarotCard(id: 'sun', name: 'Güneş', meaning: 'Neşe, başarı'),
    PfTarotCard(id: 'judgement', name: 'Mahkeme', meaning: 'Yeniden doğuş'),
    PfTarotCard(id: 'world', name: 'Dünya', meaning: 'Tamamlanma, başarı'),
  ];

  List<PfTarotCard> getDeck() => deck;

  Future<List<PfTarotReading>> getHistory(String userId) async {
    if (FirebaseBootstrap.isReady) {
      final snap = await _firestore
          .collection('pf_tarot_readings')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(30)
          .get();
      return snap.docs.map((d) => _fromDoc(d.id, d.data())).toList();
    }
    return _loadLocal(userId);
  }

  Future<PfTarotReading> createReading({
    required String userId,
    required PfTarotMode mode,
    required List<String> selectedCardIds,
  }) async {
    final cards = selectedCardIds
        .map((id) => deck.firstWhere((c) => c.id == id, orElse: () => deck.first))
        .toList();

    final modeLabel = switch (mode) {
      PfTarotMode.daily => 'Günlük',
      PfTarotMode.weekly => 'Haftalık',
      PfTarotMode.custom => 'Özel',
    };

    final interpretation = await _openAi.interpretTarot(
      cardNames: cards.map((c) => c.name).toList(),
      mode: modeLabel,
    );

    final reading = PfTarotReading(
      id: _uuid.v4(),
      userId: userId,
      mode: mode,
      cards: cards,
      interpretation: interpretation,
      createdAt: DateTime.now(),
    );

    if (FirebaseBootstrap.isReady) {
      await _firestore.collection('pf_tarot_readings').doc(reading.id).set({
        'userId': userId,
        'mode': mode.name,
        'cards': cards.map((c) => {'id': c.id, 'name': c.name}).toList(),
        'interpretation': interpretation,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await _saveLocal(userId, reading);
    }

    return reading;
  }

  PfTarotReading _fromDoc(String id, Map<String, dynamic> data) {
    final cardList = (data['cards'] as List? ?? [])
        .map((c) => PfTarotCard(
              id: c['id'] as String? ?? '',
              name: c['name'] as String? ?? '',
              meaning: '',
            ))
        .toList();
    return PfTarotReading(
      id: id,
      userId: data['userId'] as String? ?? '',
      mode: PfTarotMode.values.byName(data['mode'] as String? ?? 'custom'),
      cards: cardList,
      interpretation: data['interpretation'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Future<List<PfTarotReading>> _loadLocal(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('pf_tarot_$userId') ?? [];
    return raw.map((e) {
      final m = jsonDecode(e) as Map<String, dynamic>;
      return PfTarotReading(
        id: m['id'] as String,
        userId: userId,
        mode: PfTarotMode.values.byName(m['mode'] as String? ?? 'custom'),
        cards: (m['cards'] as List? ?? [])
            .map((c) => PfTarotCard(
                  id: c['id'] as String? ?? '',
                  name: c['name'] as String? ?? '',
                  meaning: '',
                ))
            .toList(),
        interpretation: m['interpretation'] as String? ?? '',
        createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
    }).toList();
  }

  Future<void> _saveLocal(String userId, PfTarotReading reading) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'pf_tarot_$userId';
    final list = prefs.getStringList(key) ?? [];
    list.insert(
      0,
      jsonEncode({
        'id': reading.id,
        'mode': reading.mode.name,
        'cards': reading.cards.map((c) => {'id': c.id, 'name': c.name}).toList(),
        'interpretation': reading.interpretation,
        'createdAt': reading.createdAt.toIso8601String(),
      }),
    );
    await prefs.setStringList(key, list.take(30).toList());
  }
}
