import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/fortune_birth_profile_store.dart';

final fortuneBirthProfileStoreProvider =
    FutureProvider<FortuneBirthProfileStore>((ref) async {
  return FortuneBirthProfileStore.create();
});

final fortuneBirthProfileProvider =
    FutureProvider<FortuneBirthProfile?>((ref) async {
  final me = ref.watch(authControllerProvider).valueOrNull;
  if (me == null) return null;
  final store = await ref.watch(fortuneBirthProfileStoreProvider.future);
  return store.read(me.id);
});

Future<void> saveFortuneBirthProfile(
  WidgetRef ref, {
  required DateTime birthDate,
  required TimeOfDay birthTime,
}) async {
  final me = ref.read(authControllerProvider).valueOrNull;
  if (me == null) return;

  final profile = FortuneBirthProfile(
    birthDate: birthDate,
    birthTime: birthTime,
  );
  final store = await ref.read(fortuneBirthProfileStoreProvider.future);
  await store.save(me.id, profile);

  try {
    await ref.read(profileRepositoryProvider).updateMe(
          birthDate: profile.birthDateIso,
          birthTime: profile.birthTimeIso,
        );
  } catch (_) {
    // Yerel kayıt yine geçerli; API desteklemiyorsa sessizce devam.
  }

  ref.invalidate(fortuneBirthProfileProvider);
}

String formatFortuneBirthSummary(FortuneBirthProfile profile) {
  final date = DateFormat('dd.MM.yyyy', 'tr_TR').format(profile.birthDate);
  return '$date · ${profile.birthTimeIso}';
}
