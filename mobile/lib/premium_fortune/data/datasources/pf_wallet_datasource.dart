import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/firebase/firebase_bootstrap.dart';
import '../../core/config/pf_config.dart';
import '../../core/errors/pf_failure.dart';
import '../../domain/entities/pf_wallet.dart';

class PfWalletDatasource {
  PfWalletDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  static const packages = [
    PfCreditPackage(
      id: 'starter',
      credits: 100,
      priceLabel: '₺49,99',
      priceCents: 4999,
    ),
    PfCreditPackage(
      id: 'popular',
      credits: 250,
      priceLabel: '₺99,99',
      priceCents: 9999,
      bonusCredits: 50,
      isPopular: true,
    ),
    PfCreditPackage(
      id: 'premium',
      credits: 600,
      priceLabel: '₺199,99',
      priceCents: 19999,
      bonusCredits: 150,
    ),
    PfCreditPackage(
      id: 'mega',
      credits: 1500,
      priceLabel: '₺449,99',
      priceCents: 44999,
      bonusCredits: 500,
    ),
  ];

  static const coupons = {
    'HOSGELDIN': 50,
    'FAL2026': 30,
    'PREMIUM': 100,
  };

  List<PfCreditPackage> getPackages() => packages;

  Stream<int> watchCredits(String userId) {
    if (FirebaseBootstrap.isReady) {
      return _firestore
          .collection('pf_users')
          .doc(userId)
          .snapshots()
          .map((s) => (s.data()?['credits'] as num?)?.toInt() ?? 0);
    }
    return Stream.fromFuture(_localCredits(userId));
  }

  Future<List<PfWalletTransaction>> getTransactions(String userId) async {
    if (FirebaseBootstrap.isReady) {
      final snap = await _firestore
          .collection('pf_transactions')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      return snap.docs.map((d) => _txFromDoc(d.id, d.data())).toList();
    }
    return _loadLocalTx(userId);
  }

  Future<int> spendCredits({
    required String userId,
    required int amount,
    required String description,
    String? referenceId,
  }) async {
    if (amount <= 0) return await _getCredits(userId);

    if (FirebaseBootstrap.isReady) {
      return _firestore.runTransaction<int>((tx) async {
        final ref = _firestore.collection('pf_users').doc(userId);
        final snap = await tx.get(ref);
        final current = (snap.data()?['credits'] as num?)?.toInt() ?? 0;
        if (current < amount) {
          throw const PfInsufficientCreditsFailure();
        }
        final next = current - amount;
        tx.update(ref, {'credits': next});
        final txRef = _firestore.collection('pf_transactions').doc();
        tx.set(txRef, {
          'userId': userId,
          'type': PfTransactionType.spend.name,
          'amount': -amount,
          'balanceAfter': next,
          'description': description,
          'referenceId': referenceId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return next;
      });
    }

    final current = await _localCredits(userId);
    if (current < amount) throw const PfInsufficientCreditsFailure();
    final next = current - amount;
    await _setLocalCredits(userId, next);
    await _addLocalTx(
      userId,
      PfWalletTransaction(
        id: _uuid.v4(),
        userId: userId,
        type: PfTransactionType.spend,
        amount: -amount,
        balanceAfter: next,
        description: description,
        referenceId: referenceId,
        createdAt: DateTime.now(),
      ),
    );
    return next;
  }

  Future<int> addCredits({
    required String userId,
    required int amount,
    required PfTransactionType type,
    required String description,
    String? referenceId,
  }) async {
    if (FirebaseBootstrap.isReady) {
      return _firestore.runTransaction<int>((tx) async {
        final ref = _firestore.collection('pf_users').doc(userId);
        final snap = await tx.get(ref);
        final current = (snap.data()?['credits'] as num?)?.toInt() ?? 0;
        final next = current + amount;
        tx.update(ref, {'credits': next});
        final txRef = _firestore.collection('pf_transactions').doc();
        tx.set(txRef, {
          'userId': userId,
          'type': type.name,
          'amount': amount,
          'balanceAfter': next,
          'description': description,
          'referenceId': referenceId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return next;
      });
    }

    final current = await _localCredits(userId);
    final next = current + amount;
    await _setLocalCredits(userId, next);
    await _addLocalTx(
      userId,
      PfWalletTransaction(
        id: _uuid.v4(),
        userId: userId,
        type: type,
        amount: amount,
        balanceAfter: next,
        description: description,
        referenceId: referenceId,
        createdAt: DateTime.now(),
      ),
    );
    return next;
  }

  Future<int> redeemCoupon(String userId, String code) async {
    final upper = code.trim().toUpperCase();
    final reward = coupons[upper];
    if (reward == null) {
      throw const PfPaymentFailure('Geçersiz kupon kodu.');
    }
    return addCredits(
      userId: userId,
      amount: reward,
      type: PfTransactionType.coupon,
      description: 'Kupon: $upper',
      referenceId: upper,
    );
  }

  Future<void> purchasePackage({
    required String userId,
    required PfCreditPackage package,
    required String paymentProvider,
  }) async {
    // Production: Stripe PaymentIntent / Iyzico checkout callback.
    // Demo: doğrudan kredi ekle.
    await addCredits(
      userId: userId,
      amount: package.totalCredits,
      type: PfTransactionType.purchase,
      description: '${package.credits} kredi ($paymentProvider)',
      referenceId: package.id,
    );
  }

  Future<int> _getCredits(String userId) async {
    if (FirebaseBootstrap.isReady) {
      final snap = await _firestore.collection('pf_users').doc(userId).get();
      return (snap.data()?['credits'] as num?)?.toInt() ?? 0;
    }
    return _localCredits(userId);
  }

  Future<int> _localCredits(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('pf_credits_$userId') ?? PfConfig.welcomeCredits;
  }

  Future<void> _setLocalCredits(String userId, int credits) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pf_credits_$userId', credits);
  }

  PfWalletTransaction _txFromDoc(String id, Map<String, dynamic> data) {
    return PfWalletTransaction(
      id: id,
      userId: data['userId'] as String? ?? '',
      type: PfTransactionType.values.byName(data['type'] as String? ?? 'purchase'),
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      balanceAfter: (data['balanceAfter'] as num?)?.toInt() ?? 0,
      description: data['description'] as String? ?? '',
      referenceId: data['referenceId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Future<List<PfWalletTransaction>> _loadLocalTx(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('pf_tx_$userId') ?? [];
    return raw.map((e) {
      final m = jsonDecode(e) as Map<String, dynamic>;
      return PfWalletTransaction(
        id: m['id'] as String,
        userId: userId,
        type: PfTransactionType.values.byName(m['type'] as String? ?? 'purchase'),
        amount: m['amount'] as int? ?? 0,
        balanceAfter: m['balanceAfter'] as int? ?? 0,
        description: m['description'] as String? ?? '',
        referenceId: m['referenceId'] as String?,
        createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
    }).toList();
  }

  Future<void> _addLocalTx(String userId, PfWalletTransaction tx) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'pf_tx_$userId';
    final list = prefs.getStringList(key) ?? [];
    list.insert(
      0,
      jsonEncode({
        'id': tx.id,
        'type': tx.type.name,
        'amount': tx.amount,
        'balanceAfter': tx.balanceAfter,
        'description': tx.description,
        'referenceId': tx.referenceId,
        'createdAt': tx.createdAt.toIso8601String(),
      }),
    );
    await prefs.setStringList(key, list.take(50).toList());
  }
}
