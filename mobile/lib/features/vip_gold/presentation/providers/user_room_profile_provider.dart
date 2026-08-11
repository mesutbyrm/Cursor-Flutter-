import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profile/presentation/providers/profile_hub_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/entrance_theme.dart';
import '../../domain/vip_tier.dart';
import 'vip_membership_provider.dart';

/// Profil + cüzdan tek kaynak — oda giriş banner'ı ve VIP tier.
class UserRoomProfile extends Equatable {
  const UserRoomProfile({
    required this.tier,
    this.membership,
    required this.entranceTheme,
    this.favoriteTeam,
  });

  static const empty = UserRoomProfile(
    tier: VipTier.basic,
    entranceTheme: EntranceTheme.turkey,
  );

  final VipTier tier;
  final String? membership;
  final EntranceTheme entranceTheme;
  final String? favoriteTeam;

  bool get hasGoldEntrance => tier.hasEntranceFx;

  @override
  List<Object?> get props => [tier, membership, entranceTheme, favoriteTeam];
}

/// Oturum açmış kullanıcı — üyelik + takım renkleri (profil PATCH sonrası invalidate).
final userRoomProfileProvider = Provider<UserRoomProfile>((ref) {
  final balances = ref.watch(walletBalancesProvider).valueOrNull;
  final ext = ref.watch(profileExtendedProvider).valueOrNull;

  final membership = balances?.membership ?? ext?.vipLevel;
  final tier = VipTier.fromMembership(membership);
  final favoriteTeam = ext?.favoriteTeam ?? balances?.favoriteTeam;
  final teamRaw = ext?.teamRaw ?? balances?.teamRaw;

  final theme = TeamCatalog.resolve(
    favoriteTeam: favoriteTeam,
    teamJson: teamRaw,
  );

  return UserRoomProfile(
    tier: tier,
    membership: membership,
    entranceTheme: theme,
    favoriteTeam: favoriteTeam,
  );
});

/// Kısayol — giriş animasyonu / banner renkleri.
final myEntranceThemeProvider = Provider<EntranceTheme>((ref) {
  return ref.watch(userRoomProfileProvider).entranceTheme;
});
