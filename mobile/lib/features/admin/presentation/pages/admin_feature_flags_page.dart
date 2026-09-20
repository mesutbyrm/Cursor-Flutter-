import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../providers/staff_access_provider.dart';

/// Admin — Özellik bayrakları (features toggle).
class AdminFeatureFlagsPage extends ConsumerStatefulWidget {
  const AdminFeatureFlagsPage({super.key});

  @override
  ConsumerState<AdminFeatureFlagsPage> createState() => _AdminFeatureFlagsPageState();
}

class _AdminFeatureFlagsPageState extends ConsumerState<AdminFeatureFlagsPage> {
  final Map<String, bool> _flags = {
    'voice_rooms': true,
    'live_streaming': true,
    'gift_system': true,
    'membership_system': true,
    'psychic_fortunes': true,
    'video_chat': true,
    'social_matching': true,
    'user_verification': true,
    'advanced_analytics': false,
    'ab_test_new_ui': true,
    'beta_feature_ai_moderation': false,
    'experimental_payment_methods': false,
  };

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(staffAccessProvider);
    if (!access.isFounder && !access.isSiteAdmin) {
      return Scaffold(
        body: DiscoverBackground(
          child: Center(
            child: DiscoverEmptyState(
              icon: Icons.lock_outline_rounded,
              message: 'Özellik bayrakları yalnızca site admin tarafından yönetilir.',
              actionLabel: 'Geri',
              action: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
      );
    }

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
                    onPressed: () => context.pop(),
                  ),
                  const Expanded(
                    child: DiscoverTabHeader(
                      title: 'Özellik Bayrakları',
                      subtitle: 'Dinamik özellik kontrolü',
                    ),
                  ),
                  DiscoverIconButton(
                    icon: Icons.refresh_rounded,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  const _SectionHeader('Temel Özellikler'),
                  _FlagItem(
                    name: 'voice_rooms',
                    label: 'Sesli Odalar',
                    description: 'Sesli sohbet odaları sistemi',
                    enabled: _flags['voice_rooms']!,
                    onChanged: (v) => setState(() => _flags['voice_rooms'] = v),
                  ),
                  const SizedBox(height: 8),
                  _FlagItem(
                    name: 'live_streaming',
                    label: 'Canlı Yayın',
                    description: 'Gerçek zamanlı yayın özelliği',
                    enabled: _flags['live_streaming']!,
                    onChanged: (v) => setState(() => _flags['live_streaming'] = v),
                  ),
                  const SizedBox(height: 8),
                  _FlagItem(
                    name: 'gift_system',
                    label: 'Hediye Sistemi',
                    description: 'Hediye gönderme ve yönetimi',
                    enabled: _flags['gift_system']!,
                    onChanged: (v) => setState(() => _flags['gift_system'] = v),
                  ),
                  const SizedBox(height: 8),
                  _FlagItem(
                    name: 'membership_system',
                    label: 'Üyelik Sistemi',
                    description: 'VIP ve üyelik seviyeleri',
                    enabled: _flags['membership_system']!,
                    onChanged: (v) => setState(() => _flags['membership_system'] = v),
                  ),
                  const SizedBox(height: 8),
                  _FlagItem(
                    name: 'psychic_fortunes',
                    label: 'Falcılık Hizmetleri',
                    description: 'Fal ve tarot hizmetleri',
                    enabled: _flags['psychic_fortunes']!,
                    onChanged: (v) => setState(() => _flags['psychic_fortunes'] = v),
                  ),
                  const SizedBox(height: 8),
                  _FlagItem(
                    name: 'video_chat',
                    label: 'Video Sohbet',
                    description: 'Bire-bir video konuşması',
                    enabled: _flags['video_chat']!,
                    onChanged: (v) => setState(() => _flags['video_chat'] = v),
                  ),
                  const SizedBox(height: 8),
                  _FlagItem(
                    name: 'social_matching',
                    label: 'Sosyal Eşleştirme',
                    description: 'Kullanıcı eşleştirme sistemi',
                    enabled: _flags['social_matching']!,
                    onChanged: (v) => setState(() => _flags['social_matching'] = v),
                  ),
                  const SizedBox(height: 8),
                  _FlagItem(
                    name: 'user_verification',
                    label: 'Kullanıcı Doğrulama',
                    description: 'Kimlik doğrulama ve onay',
                    enabled: _flags['user_verification']!,
                    onChanged: (v) => setState(() => _flags['user_verification'] = v),
                  ),
                  const SizedBox(height: 20),
                  const _SectionHeader('Gelişmiş Özellikler'),
                  _FlagItem(
                    name: 'advanced_analytics',
                    label: 'Gelişmiş Analitik',
                    description: 'Detaylı kullanım raporları',
                    enabled: _flags['advanced_analytics']!,
                    onChanged: (v) => setState(() => _flags['advanced_analytics'] = v),
                  ),
                  const SizedBox(height: 8),
                  _FlagItem(
                    name: 'ab_test_new_ui',
                    label: 'Yeni UI A/B Testi',
                    description: 'Kullanıcıların %25\'ine yeni arayüz',
                    enabled: _flags['ab_test_new_ui']!,
                    onChanged: (v) => setState(() => _flags['ab_test_new_ui'] = v),
                  ),
                  const SizedBox(height: 20),
                  const _SectionHeader('Beta & Deneysel'),
                  _FlagItem(
                    name: 'beta_feature_ai_moderation',
                    label: 'AI Moderasyon (Beta)',
                    description: 'Yapay zeka destekli içerik moderasyonu',
                    enabled: _flags['beta_feature_ai_moderation']!,
                    onChanged: (v) => setState(() => _flags['beta_feature_ai_moderation'] = v),
                    isBeta: true,
                  ),
                  const SizedBox(height: 8),
                  _FlagItem(
                    name: 'experimental_payment_methods',
                    label: 'Deneysel Ödeme Yöntemleri',
                    description: 'Cryptocurrency ve alternatif ödemeler',
                    enabled: _flags['experimental_payment_methods']!,
                    onChanged: (v) => setState(() => _flags['experimental_payment_methods'] = v),
                    isBeta: true,
                  ),
                  const SizedBox(height: 40),
                  FilledButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Özellik bayrakları kaydedildi'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: const Text('Kaydet'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 14,
          color: AppThemeColors.accentCyan,
        ),
      ),
    );
  }
}

class _FlagItem extends StatelessWidget {
  const _FlagItem({
    required this.name,
    required this.label,
    required this.description,
    required this.enabled,
    required this.onChanged,
    this.isBeta = false,
  });

  final String name;
  final String label;
  final String description;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final bool isBeta;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: enabled
          ? AppThemeColors.accentCyan.withValues(alpha: 0.08)
          : Colors.grey.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                      if (isBeta) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.orange.withValues(alpha: 0.5),
                            ),
                          ),
                          child: const Text(
                            'BETA',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch(
              value: enabled,
              onChanged: onChanged,
              activeColor: AppThemeColors.accentCyan,
            ),
          ],
        ),
      ),
    );
  }
}
