import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';

/// Başarı Metrikleri — Yanıt hızı, tamamlanma oranı, iptal, hizmet skoru
class PsychicMetricsScreen extends ConsumerWidget {
  const PsychicMetricsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                      title: 'Başarı Metrikleri',
                      subtitle: 'Performans KPI\'ları',
                    ),
                  ),
                  DiscoverIconButton(
                    icon: Icons.trending_up_rounded,
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Metrikleri yenile'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  // Hizmet Skoru
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppThemeColors.accentCyan.withValues(alpha: 0.2),
                          AppThemeColors.accentPurple.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hizmet Skoru',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '92/100',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 32,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Mükemmel',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: 0.92,
                            minHeight: 8,
                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation(
                              AppThemeColors.accentCyan,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Temel Metrikler
                  const Text(
                    'Temel Performans',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _MetricCard(
                    title: 'Yanıt Hızı',
                    value: '2.3 dk',
                    change: '+0.5 dk',
                    changeColor: Colors.red,
                    icon: Icons.schedule_rounded,
                    description: 'Ortalama yanıt süresi',
                  ),
                  const SizedBox(height: 10),
                  _MetricCard(
                    title: 'Tamamlanma Oranı',
                    value: '98.5%',
                    change: '-0.2%',
                    changeColor: Colors.green,
                    icon: Icons.check_circle_outline_rounded,
                    description: 'Başarılı tamamlanan seanslar',
                  ),
                  const SizedBox(height: 10),
                  _MetricCard(
                    title: 'İptal Oranı',
                    value: '0.8%',
                    change: '-0.3%',
                    changeColor: Colors.green,
                    icon: Icons.cancel_outlined,
                    description: 'İptal edilen seanslar',
                  ),
                  const SizedBox(height: 10),
                  _MetricCard(
                    title: 'Müşteri Memnuniyeti',
                    value: '4.8/5.0',
                    change: '+0.1',
                    changeColor: Colors.green,
                    icon: Icons.sentiment_satisfied_outlined,
                    description: 'Ortalama müşteri puanı',
                  ),
                  const SizedBox(height: 20),

                  // Zaman Dilimine Göre
                  const Text(
                    'Bu Ay İstatistikleri',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _MetricRow(
                          label: 'Toplam Seans',
                          value: '247',
                          color: AppThemeColors.accentCyan,
                        ),
                        const Divider(height: 16),
                        _MetricRow(
                          label: 'Toplam Dakika',
                          value: '1.240 dk',
                          color: Colors.green,
                        ),
                        const Divider(height: 16),
                        _MetricRow(
                          label: 'Ortalama Seans Süresi',
                          value: '5 dk',
                          color: Colors.amber,
                        ),
                        const Divider(height: 16),
                        _MetricRow(
                          label: 'En Yüksek Aktivite Saati',
                          value: '20:00 - 21:00',
                          color: Colors.purple,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Ödül Seviyeleri
                  const Text(
                    'Başarı Seviyeleri',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _AchievementLevel(
                    title: 'Bronz Seviye',
                    description: '50+ seans tamamlandı',
                    progress: 1.0,
                    icon: '🥉',
                  ),
                  const SizedBox(height: 10),
                  _AchievementLevel(
                    title: 'Gümüş Seviye',
                    description: '150+ seans tamamlandı',
                    progress: 0.85,
                    icon: '🥈',
                  ),
                  const SizedBox(height: 10),
                  _AchievementLevel(
                    title: 'Altın Seviye',
                    description: '300+ seans tamamlandı',
                    progress: 0.45,
                    icon: '🥇',
                  ),
                  const SizedBox(height: 10),
                  _AchievementLevel(
                    title: 'Elmas Seviye',
                    description: '500+ seans tamamlandı',
                    progress: 0.20,
                    icon: '💎',
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.change,
    required this.changeColor,
    required this.icon,
    required this.description,
  });

  final String title;
  final String value;
  final String change;
  final Color changeColor;
  final IconData icon;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppThemeColors.accentCyan.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppThemeColors.accentCyan, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                change,
                style: TextStyle(
                  fontSize: 10,
                  color: changeColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _AchievementLevel extends StatelessWidget {
  const _AchievementLevel({
    required this.title,
    required this.description,
    required this.progress,
    required this.icon,
  });

  final String title;
  final String description;
  final double progress;
  final String icon;

  @override
  Widget build(BuildContext context) {
    final isUnlocked = progress >= 0.99;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnlocked
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.06),
        border: Border.all(
          color: isUnlocked
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (isUnlocked)
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(
                isUnlocked ? Colors.green : AppThemeColors.accentCyan,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(progress * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
