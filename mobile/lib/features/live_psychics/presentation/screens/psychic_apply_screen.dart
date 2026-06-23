import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:canlifal_social/core/network/api_exception.dart';
import 'package:canlifal_social/core/network/loading_timeout.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/ui/premium_2026/cosmic_galaxy_background.dart';
import 'package:canlifal_social/features/auth/presentation/providers/auth_providers.dart';
import 'package:canlifal_social/features/live_psychics/presentation/controllers/psychics_list_controller.dart';
import 'package:canlifal_social/features/live_psychics/presentation/providers/live_psychics_providers.dart';
import 'package:canlifal_social/features/live_psychics/presentation/widgets/psychic_fortune_types.dart';

enum _ApplyPhase { form, pending, approved, rejected }

/// Falcı başvurusu — `POST /api/fortune-tellers/apply` (PDF §4).
class PsychicApplyScreen extends ConsumerStatefulWidget {
  const PsychicApplyScreen({super.key});

  @override
  ConsumerState<PsychicApplyScreen> createState() => _PsychicApplyScreenState();
}

class _PsychicApplyScreenState extends ConsumerState<PsychicApplyScreen> {
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _selected = <String>{};
  var _submitting = false;
  var _submitted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authControllerProvider).valueOrNull;
      if (_nameCtrl.text.trim().isEmpty) {
        _nameCtrl.text = user?.displayName ?? '';
      }
      unawaited(_bootstrapProfile());
    });
  }

  Future<void> _bootstrapProfile() async {
    try {
      await LoadingTimeout.run(
        ref.read(approvedPsychicProvider.notifier).refresh(),
        timeout: const Duration(seconds: 12),
        message: 'Falcı profili kontrol edilemedi',
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  _ApplyPhase _phaseFromProfile(ApprovedPsychicState? state) {
    if (_submitted) return _ApplyPhase.pending;
    final profile = state?.profile;
    if (profile == null) return _ApplyPhase.form;
    if (profile.isUsable) return _ApplyPhase.approved;
    final status = profile.applicationStatus?.trim().toLowerCase() ?? '';
    if (status == 'rejected' || status == 'declined') {
      return _ApplyPhase.rejected;
    }
    return _ApplyPhase.pending;
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _snack('Görünen ad zorunludur');
      return;
    }
    if (_selected.isEmpty) {
      _snack('En az bir uzmanlık alanı seçin');
      return;
    }

    final user = ref.read(authControllerProvider).valueOrNull;
    if (user != null) {
      final existing = await LoadingTimeout.run(
        ref
            .read(livePsychicsRepositoryProvider)
            .findApprovedTellerForUser(user.id, username: user.username),
        timeout: const Duration(seconds: 8),
        message: 'Falcı profili kontrol edilemedi',
      );
      if (!mounted) return;
      if (existing != null && existing.isUsable) {
        ref.read(approvedPsychicProvider.notifier).adoptProfile(existing);
        _snack('Zaten onaylı falcısınız — panele yönlendiriliyorsunuz');
        context.go('/canli-falcilar/dashboard');
        return;
      }
    }

    setState(() => _submitting = true);
    try {
      final applied = await LoadingTimeout.run(
        ref.read(livePsychicsRepositoryProvider).applyAsTeller(
              displayName: name,
              specialties: _selected.toList(growable: false),
              bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
              applicationNote:
                  _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
            ),
        timeout: const Duration(seconds: 22),
        message: 'Başvuru zaman aşımına uğradı — tekrar deneyin',
      );
      if (!mounted) return;
      setState(() => _submitted = true);
      if (applied != null) {
        ref.read(approvedPsychicProvider.notifier).adoptProfile(applied);
      }
      _snack('Başvurunuz alındı — onay bekleniyor');
      unawaited(ref.read(approvedPsychicProvider.notifier).refresh());
    } on ApiException catch (e) {
      if (!mounted) return;
      final msg = e.message.toLowerCase();
      if (msg.contains('zaten') ||
          msg.contains('already') ||
          msg.contains('onaylı') ||
          msg.contains('approved')) {
        await ref.read(approvedPsychicProvider.notifier).refresh();
        if (!mounted) return;
        if (ref.read(approvedPsychicProvider).isApprovedTeller) {
          context.go('/canli-falcilar/dashboard');
          return;
        }
      }
      _snack(e.message);
    } catch (e) {
      if (!mounted) return;
      _snack(ApiException.userMessage(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final approved = ref.watch(approvedPsychicProvider);
    final authed = ref.watch(authControllerProvider).valueOrNull != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0618),
      appBar: AppBar(
        title: const Text('Falcı Başvurusu'),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: CosmicGalaxyBackground(
        child: SafeArea(
          child: Builder(
            builder: (context) {
              if (!authed) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Falcı başvurusu için giriş yapın.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              final phase = _phaseFromProfile(approved);
              return switch (phase) {
                _ApplyPhase.approved => _StatusCard(
                    icon: Icons.verified_rounded,
                    iconColor: AppThemeColors.accentCyan,
                    title: 'Onaylı falcısınız',
                    message:
                        'Falcı panelinden çevrimiçi olup gelen talepleri yönetebilirsiniz.',
                    actionLabel: 'Falcı Paneline Git',
                    onAction: () => context.go('/canli-falcilar/dashboard'),
                  ),
                _ApplyPhase.pending => _StatusCard(
                    icon: Icons.hourglass_top_rounded,
                    iconColor: AppThemeColors.accentPurple,
                    title: 'Başvurunuz inceleniyor',
                    message:
                        'Başvurunuz yönetici onayına gönderildi. Onaylandığında bildirim alacaksınız.',
                    actionLabel: 'Canlı Falcılara Dön',
                    onAction: () => context.go('/canli-falcilar'),
                  ),
                _ApplyPhase.rejected => _StatusCard(
                    icon: Icons.info_outline_rounded,
                    iconColor: const Color(0xFFE53935),
                    title: 'Başvuru reddedildi',
                    message:
                        'Önceki başvurunuz reddedildi. Detay için destek ile iletişime geçin.',
                    actionLabel: 'Geri',
                    onAction: () => context.pop(),
                  ),
                _ApplyPhase.form => _buildForm(context),
              };
            },
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(
          'Canlı fal hizmeti vermek için başvurunuzu doldurun.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            height: 1.45,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _nameCtrl,
          decoration: _inputDecoration('Görünen ad *'),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _bioCtrl,
          decoration: _inputDecoration('Biyografi (isteğe bağlı)'),
          maxLines: 4,
          minLines: 3,
        ),
        const SizedBox(height: 18),
        Text(
          'Uzmanlık alanları *',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: psychicFortuneTypes.map((t) {
            final selected = _selected.contains(t.key);
            return FilterChip(
              label: Text(t.label),
              selected: selected,
              onSelected: (v) {
                setState(() {
                  if (v) {
                    _selected.add(t.key);
                  } else {
                    _selected.remove(t.key);
                  }
                });
              },
              selectedColor: AppThemeColors.accentPurple.withValues(alpha: 0.35),
              checkmarkColor: Colors.white,
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _noteCtrl,
          decoration: _inputDecoration('Başvuru notu (isteğe bağlı)'),
          maxLines: 3,
          minLines: 2,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _submitting ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppThemeColors.accentPurple,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Başvuruyu Gönder',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppThemeColors.accentPurple.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 52, color: iconColor),
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
              const SizedBox(height: 22),
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
      ),
    );
  }
}
