import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../providers/admin_system_config_providers.dart';
import '../providers/staff_access_provider.dart';

/// Sistem yapılandırması - ayarlar ve özellik bayrakları.
class AdminSystemConfigPage extends ConsumerWidget {
  const AdminSystemConfigPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(staffAccessProvider);
    if (!access.isFounder) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: DiscoverBackground(
          child: Center(
            child: DiscoverEmptyState(
              icon: Icons.lock_outline_rounded,
              message: 'Sistem yapılandırma yetkisi gerekli.',
              actionLabel: 'Geri',
              action: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
      );
    }

    final configAsync = ref.watch(adminSystemConfigProvider);
    final flagsAsync = ref.watch(adminFeatureFlagsProvider);
    final keysAsync = ref.watch(adminApiKeysProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: Column(
          children: [
            SizedBox(height: MediaQuery.paddingOf(context).top + 4),
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 12),
              child: Row(
                children: [
                  DiscoverIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: DiscoverTabHeader(
                      title: 'Sistem Yapılandırması',
                      subtitle: 'Ayarlar ve özellikler',
                    ),
                  ),
                  DiscoverIconButton(
                    icon: Icons.refresh_rounded,
                    onPressed: () {
                      ref.invalidate(adminSystemConfigProvider);
                      ref.invalidate(adminFeatureFlagsProvider);
                      ref.invalidate(adminApiKeysProvider);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppThemeColors.accentPink,
                onRefresh: () async {
                  ref.invalidate(adminSystemConfigProvider);
                  ref.invalidate(adminFeatureFlagsProvider);
                  ref.invalidate(adminApiKeysProvider);
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    // Genel Ayarlar
                    _SectionTitle('Genel Ayarlar'),
                    configAsync.when(
                      data: (config) => Column(
                        children: [
                          _ConfigToggle(
                            label: 'Bakım Modu',
                            value: config.maintenanceMode,
                            description: 'Sitede bakım yapılıyor',
                          ),
                          _ConfigToggle(
                            label: 'Yeni Kayıtlar',
                            value: config.newRegistrationsEnabled,
                            description: 'Yeni kullanıcı kaydı aktif',
                          ),
                          _ConfigToggle(
                            label: 'Email Doğrulama',
                            value: config.emailVerificationRequired,
                            description: 'Email doğrulaması zorunlu',
                          ),
                          _ConfigToggle(
                            label: 'İki Faktörlü Auth',
                            value: config.twoFactorAuthRequired,
                            description: 'İki faktörlü kimlik doğrulama',
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                      loading: () => const SizedBox(
                        height: 100,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      error: (e, _) => SizedBox.shrink(),
                    ),

                    // Güvenlik Ayarları
                    _SectionTitle('Güvenlik Ayarları'),
                    configAsync.when(
                      data: (config) => Column(
                        children: [
                          _ConfigValue(
                            label: 'Max Giriş Denemesi',
                            value: '${config.maxLoginAttempts}',
                            icon: Icons.lock_rounded,
                          ),
                          _ConfigValue(
                            label: 'Oturum Zaman Aşımı',
                            value: '${config.sessionTimeoutMinutes} dakika',
                            icon: Icons.timer_rounded,
                          ),
                          _ConfigValue(
                            label: 'Rate Limit',
                            value: '${config.rateLimit} istek/dakika',
                            icon: Icons.speed_rounded,
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (e, _) => const SizedBox.shrink(),
                    ),

                    // Para Çekme Limitleri
                    _SectionTitle('Para Çekme Limitleri'),
                    configAsync.when(
                      data: (config) => Column(
                        children: [
                          _ConfigValue(
                            label: 'Minimum Para Çekme',
                            value: '₺${config.minimumWithdrawalAmount}',
                            icon: Icons.trending_down_rounded,
                          ),
                          _ConfigValue(
                            label: 'Maksimum Para Çekme',
                            value: '₺${config.maximumWithdrawalAmount}',
                            icon: Icons.trending_up_rounded,
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (e, _) => const SizedBox.shrink(),
                    ),

                    // Özellik Bayrakları
                    _SectionTitle('Özellik Bayrakları'),
                    flagsAsync.when(
                      data: (flags) {
                        if (flags.isEmpty) {
                          return Center(
                            child: DiscoverEmptyState(
                              icon: Icons.flag_rounded,
                              message: 'Özellik bayrağı yok',
                            ),
                          );
                        }
                        return Column(
                          children: flags.map((flag) {
                            return _FeatureFlagCard(flag: flag);
                          }).toList(),
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (e, _) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 24),

                    // API Anahtarları
                    _SectionTitle('API Anahtarları'),
                    keysAsync.when(
                      data: (keys) {
                        if (keys.isEmpty) {
                          return Center(
                            child: DiscoverEmptyState(
                              icon: Icons.vpn_key_rounded,
                              message: 'API anahtarı yok',
                            ),
                          );
                        }
                        return Column(
                          children: keys.map((key) {
                            return _ApiKeyCard(apiKey: key);
                          }).toList(),
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (e, _) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 15,
          color: context.colors.onSurface,
        ),
      ),
    );
  }
}

class _ConfigToggle extends StatelessWidget {
  const _ConfigToggle({
    required this.label,
    required this.value,
    required this.description,
  });

  final String label;
  final bool value;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        border: Border.all(
          color: AppThemeColors.accentPink.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: context.colors.onSurface,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 10,
                    color: context.colors.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (val) {},
            activeColor: AppThemeColors.accentCyan,
          ),
        ],
      ),
    );
  }
}

class _ConfigValue extends StatelessWidget {
  const _ConfigValue({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        border: Border.all(
          color: AppThemeColors.accentCyan.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppThemeColors.accentCyan, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: context.colors.onSurfaceMuted,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: context.colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureFlagCard extends StatelessWidget {
  const _FeatureFlagCard({required this.flag});

  final Map<String, dynamic> flag;

  @override
  Widget build(BuildContext context) {
    final name = flag['name'] as String?;
    final description = flag['description'] as String?;
    final enabled = flag['enabled'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        border: Border.all(
          color: AppThemeColors.accentPink.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name ?? 'Unknown',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: context.colors.onSurface,
                  ),
                ),
                if (description != null && description.isNotEmpty)
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 10,
                      color: context.colors.onSurfaceMuted,
                    ),
                  ),
              ],
            ),
          ),
          Chip(
            label: Text(
              enabled ? 'AÇIK' : 'KAPAL',
              style: const TextStyle(fontSize: 9),
            ),
            backgroundColor: enabled
                ? Colors.green.withValues(alpha: 0.2)
                : Colors.red.withValues(alpha: 0.2),
            labelStyle: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: enabled ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApiKeyCard extends StatelessWidget {
  const _ApiKeyCard({required this.apiKey});

  final Map<String, dynamic> apiKey;

  @override
  Widget build(BuildContext context) {
    final name = apiKey['name'] as String?;
    final keyId = apiKey['key_id'] as String?;
    final createdAt = apiKey['created_at'] as String?;
    final lastUsed = apiKey['last_used'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        border: Border.all(
          color: AppThemeColors.accentCyan.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.vpn_key_rounded,
                  color: AppThemeColors.accentCyan, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name ?? 'Unknown',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: context.colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'ID: ${keyId?.substring(0, 8)}...',
            style: TextStyle(
              fontSize: 10,
              color: context.colors.onSurfaceMuted,
              fontFamily: 'monospace',
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (createdAt != null)
                Text(
                  'Oluşturuldu: $createdAt',
                  style: TextStyle(
                    fontSize: 9,
                    color: context.colors.onSurfaceMuted,
                  ),
                ),
              if (lastUsed != null)
                Text(
                  'Son kullanım: $lastUsed',
                  style: TextStyle(
                    fontSize: 9,
                    color: context.colors.onSurfaceMuted,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
