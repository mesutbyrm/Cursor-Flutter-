import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_theme_colors.dart';
import '../../../../live_psychics/domain/entities/psychic_entity.dart';
import '../../../../live_psychics/presentation/controllers/psychics_list_controller.dart';
import '../../widgets/premium/profile_glass.dart';
import '../profile_theme.dart';

/// Falcı paneli — onaylı falcı veya başvuru kartı.
class ProfileFortuneTellerCard extends ConsumerWidget {
  const ProfileFortuneTellerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approved = ref.watch(approvedPsychicProvider);
    final profile = approved.profile;

    if (approved.isApprovedTeller && profile != null) {
      return _ApprovedCard(profile: profile);
    }

    if (profile != null) {
      final status = profile.applicationStatus?.trim().toLowerCase() ?? '';
      if (status == 'pending') {
        return _StatusCard(
          title: 'Başvuru inceleniyor',
          subtitle: 'Onay sonrası falcı paneliniz açılır.',
          action: 'Durumu gör',
          onAction: () => context.push('/canli-falcilar/apply'),
        );
      }
      if (status == 'rejected' || status == 'declined') {
        return _StatusCard(
          title: 'Başvuru reddedildi',
          subtitle: 'Destek ile iletişime geçebilirsiniz.',
          action: 'Destek',
          onAction: () => context.push('/profile/help'),
        );
      }
    }

    return _BecomeCard(onApply: () => context.push('/falci-ol'));
  }
}

class _ApprovedCard extends StatelessWidget {
  const _ApprovedCard({required this.profile});

  final PsychicEntity profile;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ProfileSectionTitle(title: 'Falcı Paneli'),
          ProfileGlass(
            padding: const EdgeInsets.all(20),
            borderRadius: ProfilePremiumTheme.radiusLg,
            borderColor: AppThemeColors.accentPurple.withValues(alpha: 0.35),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            AppThemeColors.accentPurple.withValues(alpha: 0.5),
                            AppThemeColors.accentPink.withValues(alpha: 0.3),
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 8,
                                color: profile.isOnline
                                    ? const Color(0xFF00E676)
                                    : Colors.white38,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                profile.isOnline ? 'Çevrimiçi' : 'Çevrimdışı',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _Metric(
                        label: 'Dakika ücreti',
                        value: profile.pricePerMinute > 0
                            ? '${profile.pricePerMinute} J'
                            : '—',
                      ),
                    ),
                    Expanded(
                      child: _Metric(
                        label: 'Puan',
                        value: profile.rating > 0
                            ? profile.rating.toStringAsFixed(1)
                            : '—',
                      ),
                    ),
                    Expanded(
                      child: _Metric(
                        label: 'Toplam fal',
                        value: '${profile.reviewCount}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _Metric(
                  label: 'Bugünkü kazanç',
                  value: '0 J',
                  fullWidth: true,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () =>
                            context.push('/canli-falcilar/dashboard'),
                        icon: const Icon(Icons.dashboard_outlined, size: 18),
                        label: const Text('Panele Git'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppThemeColors.accentPurple,
                          minimumSize: const Size.fromHeight(46),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            context.push('/canli-falcilar/${profile.id}'),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Profili Düzenle'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(delay: 140.ms),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    this.fullWidth = false,
  });

  final String label;
  final String value;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final child = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
      ],
    );
    if (fullWidth) return child;
    return child;
  }
}

class _BecomeCard extends StatelessWidget {
  const _BecomeCard({required this.onApply});

  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ProfileSectionTitle(title: 'Falcı Paneli'),
        ProfileGlass(
          padding: const EdgeInsets.all(20),
          borderRadius: ProfilePremiumTheme.radiusLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Canlı fal hizmeti verin, jeton kazanın',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Colors.white,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onApply,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppThemeColors.accentPurple,
                    minimumSize: const Size.fromHeight(46),
                  ),
                  child: const Text(
                    'Falcı Başvurusu Yap',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.subtitle,
    required this.action,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ProfileSectionTitle(title: 'Falcı Paneli'),
        ProfileGlass(
          padding: const EdgeInsets.all(20),
          borderRadius: ProfilePremiumTheme.radiusLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: onAction, child: Text(action)),
            ],
          ),
        ),
      ],
    );
  }
}
