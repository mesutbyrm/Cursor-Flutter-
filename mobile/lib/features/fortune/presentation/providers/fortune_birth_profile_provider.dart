import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/domain/entities/profile_extended_entity.dart';
import '../../../profile/presentation/providers/profile_hub_providers.dart';
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

  final local = store.read(me.id);
  if (local != null) return local;

  // Yerel önbellekte yoksa backend profildeki doğum bilgisini kullan; böylece
  // yeniden kurulum / cihaz değişiminde tekrar sorulmaz. Bulunursa yerele de
  // önbelleğe alınır.
  try {
    final ext = await ref.watch(profileExtendedProvider.future);
    final remote = _fromExtended(ext);
    if (remote != null) {
      await store.save(me.id, remote);
      return remote;
    }
  } catch (_) {
    // Profil çekilemezse yerel/prompt akışına düş.
  }
  return null;
});

FortuneBirthProfile? _fromExtended(ProfileExtendedEntity ext) {
  final date = ext.birthDate;
  if (date == null) return null;
  var time = const TimeOfDay(hour: 12, minute: 0);
  final raw = ext.birthTime;
  if (raw != null && raw.contains(':')) {
    final parts = raw.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]) ?? 12;
      final m = int.tryParse(parts[1]) ?? 0;
      time = TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
    }
  }
  return FortuneBirthProfile(birthDate: date, birthTime: time);
}

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
    // Profil "hakkımda" bölümü de taze doğum bilgisini göstersin.
    ref.invalidate(profileExtendedProvider);
  } catch (_) {
    // Yerel kayıt yine geçerli; API desteklemiyorsa sessizce devam.
  }

  ref.invalidate(fortuneBirthProfileProvider);
}

String formatFortuneBirthSummary(FortuneBirthProfile profile) {
  final date = DateFormat('dd.MM.yyyy', 'tr_TR').format(profile.birthDate);
  return '$date · ${profile.birthTimeIso}';
}
