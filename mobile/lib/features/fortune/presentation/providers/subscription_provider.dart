import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_provider.dart';

// Models
class SubscriptionPlan {
  final String planId;
  final String name;
  final String description;
  final double monthlyPrice;
  final double yearlyPrice;
  final double yearlyDiscount;
  final List<String> features;
  final Map<String, dynamic> limits;

  SubscriptionPlan({
    required this.planId,
    required this.name,
    required this.description,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.yearlyDiscount,
    required this.features,
    required this.limits,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      planId: json['planId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      monthlyPrice: (json['monthlyPrice'] as num).toDouble(),
      yearlyPrice: (json['yearlyPrice'] as num).toDouble(),
      yearlyDiscount: (json['yearlyDiscount'] as num?)?.toDouble() ?? 0,
      features: List<String>.from(json['features'] as List),
      limits: json['limits'] as Map<String, dynamic>? ?? {},
    );
  }
}

class Subscription {
  final String subscriptionId;
  final String userId;
  final String planId;
  final String status;
  final DateTime currentPeriodStart;
  final DateTime currentPeriodEnd;
  final String billingCycle;
  final double price;
  final bool autoRenew;
  final DateTime? nextBillingDate;

  Subscription({
    required this.subscriptionId,
    required this.userId,
    required this.planId,
    required this.status,
    required this.currentPeriodStart,
    required this.currentPeriodEnd,
    required this.billingCycle,
    required this.price,
    required this.autoRenew,
    this.nextBillingDate,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      subscriptionId: json['subscriptionId'] as String,
      userId: json['userId'] as String,
      planId: json['planId'] as String,
      status: json['status'] as String,
      currentPeriodStart: DateTime.parse(json['currentPeriodStart'] as String),
      currentPeriodEnd: DateTime.parse(json['currentPeriodEnd'] as String),
      billingCycle: json['billingCycle'] as String,
      price: (json['price'] as num).toDouble(),
      autoRenew: json['autoRenew'] as bool,
      nextBillingDate: json['nextBillingDate'] != null
        ? DateTime.parse(json['nextBillingDate'] as String)
        : null,
    );
  }
}

// Service
class SubscriptionService {
  final Dio _dio;

  SubscriptionService(this._dio);

  Future<List<SubscriptionPlan>> getPlans() async {
    final response = await _dio.get('/api/subscriptions/plans');
    final plans = (response.data['data']['plans'] as List)
        .map((p) => SubscriptionPlan.fromJson(p as Map<String, dynamic>))
        .toList();
    return plans;
  }

  Future<Subscription?> getCurrentSubscription() async {
    try {
      final response = await _dio.get('/api/subscriptions/current');
      if (response.data['data']['subscription'] == null) {
        return null;
      }
      return Subscription.fromJson(response.data['data']['subscription']);
    } catch (e) {
      return null;
    }
  }

  Future<Subscription> createSubscription({
    required String planId,
    required String billingCycle,
  }) async {
    final response = await _dio.post('/api/subscriptions/create', data: {
      'planId': planId,
      'billingCycle': billingCycle,
    });
    return Subscription.fromJson(response.data['data']);
  }

  Future<void> cancelSubscription() async {
    await _dio.delete('/api/subscriptions/current');
  }
}

// Providers
final subscriptionServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return SubscriptionService(dio);
});

final subscriptionPlansProvider = FutureProvider<List<SubscriptionPlan>>((ref) async {
  final service = ref.watch(subscriptionServiceProvider);
  return service.getPlans();
});

final currentSubscriptionProvider = FutureProvider<Subscription?>((ref) async {
  final service = ref.watch(subscriptionServiceProvider);
  return service.getCurrentSubscription();
});

final billingCycleProvider = StateProvider<String>((ref) => 'monthly');

final selectedPlanProvider = StateProvider<SubscriptionPlan?>((ref) => null);
