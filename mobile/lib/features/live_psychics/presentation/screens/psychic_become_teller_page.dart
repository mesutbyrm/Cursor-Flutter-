import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/ui/premium_2026/cosmic_galaxy_background.dart';
import 'package:canlifal_social/features/auth/presentation/providers/auth_providers.dart';
import 'package:canlifal_social/features/live_psychics/presentation/controllers/psychics_list_controller.dart';

/// Falcı ol — tanıtım ve başvuru girişi. Onay admin panelinden yapılır.
class PsychicBecomeTellerPage extends ConsumerWidget {
  const PsychicBecomeTellerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authed = ref.watch(authControllerProvider).valueOrNull != null;
    final approved = ref.watch(approvedPsychicProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0618),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Falcı Ol'),
        backgroundColor: Colors.transparent,
      ),
      body: CosmicGalaxyBackground(
        child: SafeArea(
          child: Builder(
            builder: (context) {
              if (!approved.checked && approved.loading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!authed) {
                return _CenterMessage(
                  icon: Icons.login_rounded,
                  title: 'Giriş gerekli',
                  message: 'Falcı başvurusu yapmak için hesabınıza giriş yapın.',
                  actionLabel: 'Giriş Yap',
                  onAction: () => context.push('/auth/login'),
                );
              }

              if (approved.isApprovedTeller) {
                return _CenterMessage(
                  icon: Icons.verified_rounded,
                  iconColor: AppThemeColors.accentCyan,
                  title: 'Onaylı falcısınız',
                  message:
                      'Falcı panelinden çevrimiçi olup gelen talepleri yönetebilirsiniz.',
                  actionLabel: 'Falcı Paneline Git',
                  onAction: () => context.go('/canli-falcilar/dashboard'),
                );
              }

              final status =
                  approved.profile?.applicationStatus?.trim().toLowerCase() ?? '';
              if (status == 'pending') {
                return _CenterMessage(
                  icon: Icons.hourglass_top_rounded,
                  iconColor: AppThemeColors.accentPurple,
                  title: 'Başvurunuz inceleniyor',
                  message:
                      'Başvurunuz yönetici onayına gönderildi. Onaylandığında bildirim alacaksınız.',
                  actionLabel: 'Canlı Falcılara Dön',
                  onAction: () => context.go('/canli-falcilar'),
                );
              }

              if (status == 'rejected' || status == 'declined') {
                return _CenterMessage(
                  icon: Icons.info_outline_rounded,
                  iconColor: const Color(0xFFE53935),
                  title: 'Başvuru reddedildi',
                  message:
                      'Önceki başvurunuz reddedildi. Detay için destek ile iletişime geçin.',
                  actionLabel: 'Destek',
                  onAction: () => context.push('/profile/help'),
                );
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  const _HeroSection(),
                  const SizedBox(height: 28),
                  const _StepsSection(),
                  const SizedBox(height: 24),
                  const _BenefitsSection(),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: () => context.push('/canli-falcilar/apply'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppThemeColors.accentPurple,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Başvuru Formunu Doldur',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Başvurunuz canlifal.com yönetici panelinden incelenir ve onaylanır.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppThemeColors.accentPurple.withValues(alpha: 0.5),
                AppThemeColors.accentPink.withValues(alpha: 0.3),
              ],
            ),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            size: 56,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Canlı Fal Hizmeti Verin',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 26,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Tarot, kahve falı ve daha fazlası — danışanlarla canlı görüntülü seans yapın, jeton kazanın.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}

class _StepsSection extends StatelessWidget {
  const _StepsSection();

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('1', 'Başvuru', 'Formu doldurun, uzmanlık alanlarınızı seçin'),
      ('2', 'Admin onayı', 'Yönetici panelinden başvurunuz incelenir'),
      ('3', 'Canlı fal', 'Onay sonrası falcı panelinden hizmet verin'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nasıl çalışır?',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        const SizedBox(height: 14),
        for (final step in steps)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor:
                      AppThemeColors.accentPurple.withValues(alpha: 0.35),
                  child: Text(
                    step.$1,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.$2,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        step.$3,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Colors.white.withValues(alpha: 0.68),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _BenefitsSection extends StatelessWidget {
  const _BenefitsSection();

  @override
  Widget build(BuildContext context) {
    const benefits = [
      (Icons.videocam_rounded, 'Canlı görüntülü seans'),
      (Icons.monetization_on_rounded, 'Jeton ile kazanç'),
      (Icons.dashboard_outlined, 'Falcı paneli ve çevrimiçi anahtarı'),
      (Icons.notifications_active_outlined, 'Anlık randevu bildirimleri'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Avantajlar',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        const SizedBox(height: 12),
        ...benefits.map(
          (b) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Icon(b.$1, size: 20, color: AppThemeColors.accentCyan),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    b.$2,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CenterMessage extends StatelessWidget {
  const _CenterMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.iconColor,
  });

  final IconData icon;
  final Color? iconColor;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: iconColor ?? Colors.white70),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                height: 1.45,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: AppThemeColors.accentPurple,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
