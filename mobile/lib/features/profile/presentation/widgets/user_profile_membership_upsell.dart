import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../premium_2026/profile_membership_helpers.dart';
import '../providers/profile_providers.dart';

/// Ücretli (Gold/Diamond/SVIP) üyeye sahip bir kullanıcının profilinde,
/// ziyaretçiye "sen de bu üyeliği al" çağrısı. Ziyaretçinin kendi profili veya
/// üyesiz kullanıcı profillerinde görünmez.
class UserProfileMembershipUpsell extends ConsumerWidget {
  const UserProfileMembershipUpsell({
    super.key,
    required this.userId,
    required this.isSelf,
  });

  final String userId;
  final bool isSelf;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isSelf) return const SizedBox.shrink();
    final ext = ref.watch(userProfileExtendedProvider(userId)).valueOrNull;
    if (ext == null) return const SizedBox.shrink();
    final info = resolveProfileMembership(rawMembership: ext.vipLevel);
    if (!info.hasPaidTier) return const SizedBox.shrink();

    final label = info.tierLabel;

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => context.push('/premium-membership'),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3A2A00), Color(0xFF7A5A10)],
              ),
              border: Border.all(
                color: const Color(0xFFFFD54F).withValues(alpha: 0.55),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: Color(0xFFFFD54F),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sen de $label üye ol',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$label ayrıcalıklarını keşfet: özel rozet, giriş efekti ve daha fazlası',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD54F),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Üye Ol',
                    style: TextStyle(
                      color: Color(0xFF3A2A00),
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
