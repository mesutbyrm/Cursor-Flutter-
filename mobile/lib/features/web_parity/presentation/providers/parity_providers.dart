import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/parity_api.dart';
import '../../domain/parity_models.dart';

final parityApiProvider = Provider<ParityApi>(
  (ref) => ParityApi(ref.watch(dioProvider)),
);

final supportTicketsProvider =
    FutureProvider.autoDispose<List<SupportTicket>>(
  (ref) => ref.watch(parityApiProvider).supportTickets(),
);

final supportTicketProvider =
    FutureProvider.autoDispose.family<SupportTicket, String>(
  (ref, id) => ref.watch(parityApiProvider).supportTicket(id),
);

final refundsProvider = FutureProvider.autoDispose<List<RefundRequest>>(
  (ref) => ref.watch(parityApiProvider).refunds(),
);

final membershipPlansProvider =
    FutureProvider.autoDispose<List<MembershipPlanInfo>>(
  (ref) => ref.watch(parityApiProvider).membershipPlans(),
);

final membershipComparisonProvider =
    FutureProvider.autoDispose<MembershipComparison>(
  (ref) => ref.watch(parityApiProvider).membershipComparison(),
);

/// `(scope, period)` — scope: voice_room | live_stream; period: hourly|daily|weekly|monthly.
final top100Provider = FutureProvider.autoDispose
    .family<LeaderboardResult, (String, String)>(
  (ref, key) => ref.watch(parityApiProvider).top100(scope: key.$1, period: key.$2),
);

final vipLeaderboardProvider =
    FutureProvider.autoDispose<LeaderboardResult>(
  (ref) => ref.watch(parityApiProvider).vipLeaderboard(),
);

final mySupporterLevelsProvider =
    FutureProvider.autoDispose<List<SupporterLevelRow>>(
  (ref) => ref.watch(parityApiProvider).mySupporterLevels(),
);

/// Ham harita döndüren GET uçları (falcı paneli, ajans büyüme…).
final parityMapProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>(
  (ref, path) => ref.watch(parityApiProvider).rawMap(path),
);

final parityListProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
  (ref, path) => ref.watch(parityApiProvider).rawList(path),
);
