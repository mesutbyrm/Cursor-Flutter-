import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_theme_colors.dart';
import '../../../../live_psychics/domain/entities/psychic_entity.dart';
import '../../../../live_psychics/presentation/controllers/psychics_list_controller.dart';
import 'profile_glass.dart';

/// Profil — onaylı falcı paneli veya «Falcı Ol» başvuru kartı.
class ProfileFortuneTellerPanel extends ConsumerWidget {
  const ProfileFortuneTellerPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approved = ref.watch(approvedPsychicProvider);
    final profile = approved.profile;

    if (approved.isApprovedTeller && profile != null) {
      return _ApprovedPanel(profile: profile);
    }

    if (profile != null) {
      final status = profile.applicationStatus?.trim().toLowerCase() ?? '';
      if (status == 'pending') {
        return _StatusPanel(
          icon: Icons.hourglass_top_rounded,
          iconColor: AppThemeColors.accentPurple,
          title: 'Falcı başvurunuz inceleniyor',
          subtitle:
              'Yönetici onayından sonra falcı paneliniz açılır. Bildirim alacaksınız.',
          actionLabel: 'Başvuru durumu',
          onAction: () => context.push('/canli-falcilar/apply'),
        );
      }
      if (status == 'rejected' || status == 'declined') {
        return _StatusPanel(
          icon: Icons.info_outline_rounded,
          iconColor: const Color(0xFFE53935),
          title: 'Falcı başvurunuz reddedildi',
          subtitle: 'Detay için destek ile iletişime geçebilirsiniz.',
          actionLabel: 'Destek',
          onAction: () => context.push('/profile/help'),
        );
      }
    }

    return _BecomeTellerPanel(
      onApply: () => context.push('/falci-ol'),
    );
  }
}

class _ApprovedPanel extends StatelessWidget {
  const _ApprovedPanel({required this.profile});

  final PsychicEntity profile;

  @override
  Widget build(BuildContext context) {
    final name = profile.name;
    final isOnline = profile.isOnline;
    final rating = profile.rating;
    final price = profile.pricePerMinute;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ProfileSectionTitle(title: 'Falcı Paneli'),
        ProfileGlass(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        colors: [
                          AppThemeColors.accentPurple.withValues(alpha: 0.45),
                          AppThemeColors.accentPink.withValues(alpha: 0.25),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.circle,
                              size: 8,
                              color: isOnline
                                  ? const Color(0xFF00E676)
                                  : Colors.white38,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isOnline ? 'Çevrimiçi' : 'Çevrimdışı',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                            if (rating > 0) ...[
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: Color(0xFFFFD54F),
                              ),
                              Text(
                                ' ${rating.toStringAsFixed(1)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (price > 0) ...[
                const SizedBox(height: 12),
                Text(
                  '$price jeton / dk',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => context.push('/canli-falcilar/dashboard'),
                      icon: const Icon(Icons.dashboard_outlined, size: 18),
                      label: const Text('Panele Git'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppThemeColors.accentPurple,
                        minimumSize: const Size.fromHeight(44),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          context.push('/canli-falcilar/${profile.id}'),
                      icon: const Icon(Icons.person_outline_rounded, size: 18),
                      label: const Text('Profilim'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
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
        ),
      ],
    );
  }
}

class _BecomeTellerPanel extends StatelessWidget {
  const _BecomeTellerPanel({required this.onApply});

  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ProfileSectionTitle(title: 'Falcı Ol'),
        ProfileGlass(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: AppThemeColors.accentPurple.withValues(alpha: 0.2),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: AppThemeColors.accentCyan,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Canlı fal hizmeti verin, jeton kazanın',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.92),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _bullet('Başvurunuz admin panelinden onaylanır'),
              _bullet('Onay sonrası falcı panelinden çevrimiçi olun'),
              _bullet('Gelen randevu taleplerini kabul edin'),
              const SizedBox(height: 16),
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

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 16,
            color: AppThemeColors.accentCyan.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Colors.white.withValues(alpha: 0.72),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ProfileSectionTitle(title: 'Falcı Başvurusu'),
        ProfileGlass(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: onAction,
                child: Text(actionLabel),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
