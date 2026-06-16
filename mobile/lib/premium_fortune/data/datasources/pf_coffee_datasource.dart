import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/firebase/firebase_bootstrap.dart';
import '../../domain/entities/pf_coffee_reading.dart';
import 'openai_datasource.dart';

/// Kahve falı — Firestore + Storage + OpenAI (offline demo destekli).
class PfCoffeeDatasource {
  PfCoffeeDatasource({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    OpenAiDatasource? openAi,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _openAi = openAi ?? OpenAiDatasource();

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final OpenAiDatasource _openAi;
  final _uuid = const Uuid();

  bool get _useFirebase => FirebaseBootstrap.isReady;

  Future<List<PfCoffeeReading>> getHistory(String userId) async {
    if (_useFirebase) {
      final snap = await _firestore
          .collection('pf_coffee_readings')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(30)
          .get();
      return snap.docs.map((d) => _fromDoc(d.id, d.data())).toList();
    }
    return _loadLocalHistory(userId);
  }

  Future<PfCoffeeReading> analyzePhoto({
    required String userId,
    required String localImagePath,
  }) async {
    String imageUrl = localImagePath;
    String? base64;

    if (_useFirebase) {
      final ref = _storage.ref().child(
            'pf_coffee/$userId/${_uuid.v4()}.jpg',
          );
      await ref.putFile(File(localImagePath));
      imageUrl = await ref.getDownloadURL();
    } else {
      final bytes = await File(localImagePath).readAsBytes();
      base64 = base64Encode(bytes);
    }

    final analysis = await _openAi.analyzeCoffeeCup(
      imageUrl: imageUrl,
      imageBase64: base64,
    );

    final reading = PfCoffeeReading(
      id: _uuid.v4(),
      userId: userId,
      imageUrl: imageUrl,
      love: analysis['love'] ?? '',
      money: analysis['money'] ?? '',
      career: analysis['career'] ?? '',
      health: analysis['health'] ?? '',
      summary: analysis['summary'] ?? '',
      createdAt: DateTime.now(),
    );

    if (_useFirebase) {
      await _firestore.collection('pf_coffee_readings').doc(reading.id).set({
        'userId': userId,
        'imageUrl': imageUrl,
        'love': reading.love,
        'money': reading.money,
        'career': reading.career,
        'health': reading.health,
        'summary': reading.summary,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await _saveLocalHistory(userId, reading);
    }

    return reading;
  }

  PfCoffeeReading _fromDoc(String id, Map<String, dynamic> data) {
    return PfCoffeeReading(
      id: id,
      userId: data['userId'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      love: data['love'] as String? ?? '',
      money: data['money'] as String? ?? '',
      career: data['career'] as String? ?? '',
      health: data['health'] as String? ?? '',
      summary: data['summary'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Future<List<PfCoffeeReading>> _loadLocalHistory(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('pf_coffee_$userId') ?? [];
    return raw.map((e) {
      final m = jsonDecode(e) as Map<String, dynamic>;
      return PfCoffeeReading(
        id: m['id'] as String,
        userId: userId,
        imageUrl: m['imageUrl'] as String? ?? '',
        love: m['love'] as String? ?? '',
        money: m['money'] as String? ?? '',
        career: m['career'] as String? ?? '',
        health: m['health'] as String? ?? '',
        summary: m['summary'] as String? ?? '',
        createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
    }).toList();
  }

  Future<void> _saveLocalHistory(String userId, PfCoffeeReading reading) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'pf_coffee_$userId';
    final list = prefs.getStringList(key) ?? [];
    list.insert(
      0,
      jsonEncode({
        'id': reading.id,
        'imageUrl': reading.imageUrl,
        'love': reading.love,
        'money': reading.money,
        'career': reading.career,
        'health': reading.health,
        'summary': reading.summary,
        'createdAt': reading.createdAt.toIso8601String(),
      }),
    );
    await prefs.setStringList(key, list.take(30).toList());
  }
}
