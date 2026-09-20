import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../providers/staff_access_provider.dart';

/// Admin — Güvenlik izleme panosu (uyarılar, tehditler, IP engelleme).
class AdminSecurityDashboardPage extends ConsumerWidget {
  const AdminSecurityDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(staffAccessProvider);
    if (!access.canManagePayments && !access.isFounder) {
      return Scaffold(
        body: DiscoverBackground(
          child: Center(
            child: DiscoverEmptyState(
              icon: Icons.lock_outline_rounded,
              message: 'Güvenlik panosu yalnızca yöneticiler tarafından erişilir.',
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
                      title: 'Güvenlik Panosu',
                      subtitle: 'Tehdit ve uyarı izlemesi',
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
                  // Durum özeti
                  _StatusSection(),
                  const SizedBox(height: 20),

                  // Aktif uyarılar
                  _SectionTitle('🔴 Aktif Uyarılar'),
                  _AlertCard(
                    title: 'Anormal giriş etkinliği',
                    description: 'Aynı IP\'den 10 + başarısız giriş denemesi',
                    severity: 'Yüksek',
                    ipAddress: '203.0.113.45',
                    count: 15,
                  ),
                  const SizedBox(height: 10),
                  _AlertCard(
                    title: 'SQL Injection girişimi',
                    description: 'Şüpheli sorgu parametreleri tespit edildi',
                    severity: 'Kritik',
                    ipAddress: '198.51.100.89',
                    count: 3,
                  ),
                  const SizedBox(height: 10),
                  _AlertCard(
                    title: 'Hız sınırı aşıldı',
                    description: 'API uç noktası dakikada 1000+ istek',
                    severity: 'Orta',
                    ipAddress: '192.0.2.33',
                    count: 2500,
                  ),
                  const SizedBox(height: 20),

                  // IP Engelleme listesi
                  _SectionTitle('🚫 Engellenen IP\'ler'),
                  _BlockedIPItem(ip: '203.0.113.45', reason: 'Brute force'),
                  const SizedBox(height: 8),
                  _BlockedIPItem(ip: '198.51.100.89', reason: 'SQL injection'),
                  const SizedBox(height: 8),
                  _BlockedIPItem(ip: '192.0.2.33', reason: 'DDoS'),
                  const SizedBox(height: 20),

                  // İstatistikler
                  _SectionTitle('📊 24 Saatlik İstatistikler'),
                  _StatGridItem(label: 'Başarısız Giriş', value: '247', color: AppThemeColors.liveRed),
                  const SizedBox(height: 8),
                  _StatGridItem(label: 'Engellenen İstekler', value: '891', color: Colors.orange),
                  const SizedBox(height: 8),
                  _StatGridItem(label: 'Algılanan Tehditler', value: '12', color: AppThemeColors.liveRed),
                  const SizedBox(height: 8),
                  _StatGridItem(label: 'Aşırı Oran', value: '5', color: Colors.orange),
                  const SizedBox(height: 20),

                  // Güvenlik önerileri
                  _SectionTitle('💡 Öneriler'),
                  _RecommendationCard(
                    title: '2FA Zorunlu Kılma',
                    description: 'Admin hesapları için iki faktörlü kimlik doğrulamayı zorunlu kılın',
                    action: 'Ayarla',
                  ),
                  const SizedBox(height: 8),
                  _RecommendationCard(
                    title: 'IP Whitelist Oluştur',
                    description: 'Admin panelinin sadece belirli IP\'lerden erişilmesini sağlayın',
                    action: 'Ayarla',
                  ),
                  const SizedBox(height: 8),
                  _RecommendationCard(
                    title: 'SSL Sertifikası Kontrol',
                    description: 'SSL sertifikasının geçerliliğini ve güvenliğini doğrulayın',
                    action: 'Kontrol Et',
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

class _StatusSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.green.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Sistem Güvenli',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                ),
                const Icon(Icons.shield_rounded, color: Colors.green, size: 24),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Hiçbir kritik tehdit algılanmamıştır. 3 aktif uyarı kontrol edilmektedir.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
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
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 14,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.title,
    required this.description,
    required this.severity,
    required this.ipAddress,
    required this.count,
  });

  final String title;
  final String description;
  final String severity;
  final String ipAddress;
  final int count;

  Color _getSeverityColor(String severity) {
    if (severity == 'Kritik') return AppThemeColors.liveRed;
    if (severity == 'Yüksek') return Colors.orange;
    return Colors.yellow;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _getSeverityColor(severity).withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(severity),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    severity,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '×$count',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _getSeverityColor(severity),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'IP: $ipAddress',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.5),
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlockedIPItem extends StatelessWidget {
  const _BlockedIPItem({required this.ip, required this.reason});

  final String ip;
  final String reason;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            const Icon(Icons.block_rounded, color: Colors.red, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ip,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    reason,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.clear_rounded, size: 18),
              onPressed: () {},
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatGridItem extends StatelessWidget {
  const _StatGridItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.title,
    required this.description,
    required this.action,
  });

  final String title;
  final String description;
  final String action;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppThemeColors.accentCyan.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(action),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
