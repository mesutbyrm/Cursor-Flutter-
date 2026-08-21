import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../premium_2026/profile_theme.dart';
import '../providers/profile_hub_providers.dart';

/// Profil API hatası — yalnızca ilgili provider'ları yeniler.
class ProfileHubErrorBanner extends ConsumerWidget {
  const ProfileHubErrorBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = ref.watch(profileExtendedProvider);
    if (!ext.hasError || ext.isLoading) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(ProfilePremiumTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Profil bilgileri yüklenemedi',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => invalidateProfileData(ref),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
