import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/openai_datasource.dart';
import '../../data/datasources/pf_astrology_datasource.dart';
import '../../data/datasources/pf_chat_datasource.dart';
import '../../data/datasources/pf_coffee_datasource.dart';
import '../../data/datasources/pf_dream_datasource.dart';
import '../../data/datasources/pf_firebase_auth_datasource.dart';
import '../../data/datasources/pf_games_datasource.dart';
import '../../data/datasources/pf_live_teller_datasource.dart';
import '../../data/datasources/pf_tarot_datasource.dart';
import '../../data/datasources/pf_wallet_datasource.dart';
import '../../data/repositories/pf_astrology_repository_impl.dart';
import '../../data/repositories/pf_auth_repository_impl.dart';
import '../../data/repositories/pf_chat_repository_impl.dart';
import '../../data/repositories/pf_coffee_repository_impl.dart';
import '../../data/repositories/pf_dream_repository_impl.dart';
import '../../data/repositories/pf_games_repository_impl.dart';
import '../../data/repositories/pf_live_teller_repository_impl.dart';
import '../../data/repositories/pf_tarot_repository_impl.dart';
import '../../data/repositories/pf_wallet_repository_impl.dart';
import '../../domain/entities/pf_user.dart';
import '../../domain/repositories/pf_astrology_repository.dart';
import '../../domain/repositories/pf_auth_repository.dart';
import '../../domain/repositories/pf_chat_repository.dart';
import '../../domain/repositories/pf_coffee_repository.dart';
import '../../domain/repositories/pf_dream_repository.dart';
import '../../domain/repositories/pf_games_repository.dart';
import '../../domain/repositories/pf_live_teller_repository.dart';
import '../../domain/repositories/pf_tarot_repository.dart';
import '../../domain/repositories/pf_wallet_repository.dart';

// Datasources
final openAiDatasourceProvider = Provider((_) => OpenAiDatasource());
final pfFirebaseAuthDatasourceProvider =
    Provider((_) => PfFirebaseAuthDatasource());
final pfCoffeeDatasourceProvider = Provider((ref) => PfCoffeeDatasource(
      openAi: ref.watch(openAiDatasourceProvider),
    ));
final pfTarotDatasourceProvider = Provider((ref) => PfTarotDatasource(
      openAi: ref.watch(openAiDatasourceProvider),
    ));
final pfWalletDatasourceProvider = Provider((_) => PfWalletDatasource());
final pfLiveTellerDatasourceProvider =
    Provider((_) => PfLiveTellerDatasource());
final pfChatDatasourceProvider = Provider((_) => PfChatDatasource());
final pfGamesDatasourceProvider = Provider((_) => PfGamesDatasource());
final pfAstrologyDatasourceProvider = Provider((ref) => PfAstrologyDatasource(
      openAi: ref.watch(openAiDatasourceProvider),
    ));
final pfDreamDatasourceProvider = Provider((ref) => PfDreamDatasource(
      openAi: ref.watch(openAiDatasourceProvider),
    ));

// Repositories
final pfWalletRepositoryProvider = Provider<PfWalletRepository>((ref) {
  return PfWalletRepositoryImpl(ref.watch(pfWalletDatasourceProvider));
});

final pfAuthRepositoryProvider = Provider<PfAuthRepository>((ref) {
  return PfAuthRepositoryImpl(ref.watch(pfFirebaseAuthDatasourceProvider));
});

final pfCoffeeRepositoryProvider = Provider<PfCoffeeRepository>((ref) {
  return PfCoffeeRepositoryImpl(
    ref.watch(pfCoffeeDatasourceProvider),
    ref.watch(pfWalletRepositoryProvider),
  );
});

final pfTarotRepositoryProvider = Provider<PfTarotRepository>((ref) {
  return PfTarotRepositoryImpl(
    ref.watch(pfTarotDatasourceProvider),
    ref.watch(pfWalletRepositoryProvider),
  );
});

final pfLiveTellerRepositoryProvider = Provider<PfLiveTellerRepository>((ref) {
  return PfLiveTellerRepositoryImpl(ref.watch(pfLiveTellerDatasourceProvider));
});

final pfChatRepositoryProvider = Provider<PfChatRepository>((ref) {
  return PfChatRepositoryImpl(ref.watch(pfChatDatasourceProvider));
});

final pfGamesRepositoryProvider = Provider<PfGamesRepository>((ref) {
  return PfGamesRepositoryImpl(
    ref.watch(pfGamesDatasourceProvider),
    ref.watch(pfWalletRepositoryProvider),
  );
});

final pfAstrologyRepositoryProvider = Provider<PfAstrologyRepository>((ref) {
  return PfAstrologyRepositoryImpl(ref.watch(pfAstrologyDatasourceProvider));
});

final pfDreamRepositoryProvider = Provider<PfDreamRepository>((ref) {
  return PfDreamRepositoryImpl(
    ref.watch(pfDreamDatasourceProvider),
    ref.watch(pfWalletRepositoryProvider),
  );
});

// Auth stream
final pfCurrentUserProvider = StreamProvider<PfUser?>((ref) {
  return ref.watch(pfAuthRepositoryProvider).watchCurrentUser();
});

final pfCreditsProvider = StreamProvider.family<int, String>((ref, userId) {
  return ref.watch(pfWalletRepositoryProvider).watchCredits(userId);
});

// Demo guest user (Firebase yokken)
final pfGuestModeProvider = StateProvider<bool>((ref) => false);

final pfDemoUserProvider = Provider<PfUser>((ref) {
  return const PfUser(
    id: 'demo_user',
    email: 'demo@canlifal.com',
    displayName: 'Misafir',
    credits: 50,
    points: 120,
    badges: ['b1'],
  );
});

final pfEffectiveUserProvider = Provider<PfUser?>((ref) {
  final firebaseUser = ref.watch(pfCurrentUserProvider).valueOrNull;
  if (firebaseUser != null) return firebaseUser;
  if (ref.watch(pfGuestModeProvider)) {
    return ref.watch(pfDemoUserProvider);
  }
  return null;
});
