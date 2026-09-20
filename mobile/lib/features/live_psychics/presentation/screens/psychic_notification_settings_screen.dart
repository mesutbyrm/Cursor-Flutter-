import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';

/// Bildirim Ayarları — Gelen istek, mesaj, inceleme, kampanya bildirimleri
class PsychicNotificationSettingsScreen extends ConsumerStatefulWidget {
  const PsychicNotificationSettingsScreen({super.key});

  @override
  ConsumerState<PsychicNotificationSettingsScreen> createState() =>
      _PsychicNotificationSettingsScreenState();
}

class _PsychicNotificationSettingsScreenState
    extends ConsumerState<PsychicNotificationSettingsScreen> {
  // Bildirim ayarları (mock)
  bool incomingRequestNotification = true;
  bool messageNotification = true;
  bool reviewNotification = true;
  bool campaignNotification = false;
  bool soundEnabled = true;
  bool vibrationEnabled = true;
  String notificationTiming = 'immediate'; // immediate, silent_hours, quiet

  final quietHoursStart = TimeOfDay(hour: 22, minute: 0);
  final quietHoursEnd = TimeOfDay(hour: 8, minute: 0);

  @override
  Widget build(BuildContext context) {
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
                      title: 'Bildirim Ayarları',
                      subtitle: 'Bildirimleri kişiselleştir',
                    ),
                  ),
                  DiscoverIconButton(
                    icon: Icons.info_outline_rounded,
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Bildirimleri istedikleri şekilde özelleştirebilirsiniz'),
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
                  // Bildirim Türleri
                  const Text(
                    'Bildirim Türleri',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _NotificationToggleTile(
                    title: 'Gelen Seans İstekleri',
                    subtitle: 'Yeni seans talebine anında bildir',
                    icon: Icons.notifications_active_rounded,
                    iconColor: Colors.blue,
                    value: incomingRequestNotification,
                    onChanged: (val) => setState(() => incomingRequestNotification = val),
                  ),
                  const SizedBox(height: 10),
                  _NotificationToggleTile(
                    title: 'Mesajlar',
                    subtitle: 'Danışanlardan gelen mesajlar',
                    icon: Icons.mail_outline_rounded,
                    iconColor: Colors.green,
                    value: messageNotification,
                    onChanged: (val) => setState(() => messageNotification = val),
                  ),
                  const SizedBox(height: 10),
                  _NotificationToggleTile(
                    title: 'Yorum & Değerlendirmeler',
                    subtitle: 'Seans sonrası alınan yorumlar',
                    icon: Icons.star_outline_rounded,
                    iconColor: Colors.amber,
                    value: reviewNotification,
                    onChanged: (val) => setState(() => reviewNotification = val),
                  ),
                  const SizedBox(height: 10),
                  _NotificationToggleTile(
                    title: 'Kampanya & Promosyon',
                    subtitle: 'Özel kampanya ve indirim duyuruları',
                    icon: Icons.local_offer_outlined,
                    iconColor: Colors.purple,
                    value: campaignNotification,
                    onChanged: (val) => setState(() => campaignNotification = val),
                  ),
                  const SizedBox(height: 20),

                  // Ses & Titreşim
                  const Text(
                    'Ses & Titreşim',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _NotificationToggleTile(
                    title: 'Ses',
                    subtitle: 'Bildirim sesi etkin',
                    icon: Icons.volume_up_rounded,
                    iconColor: AppThemeColors.accentCyan,
                    value: soundEnabled,
                    onChanged: (val) => setState(() => soundEnabled = val),
                  ),
                  const SizedBox(height: 10),
                  _NotificationToggleTile(
                    title: 'Titreşim',
                    subtitle: 'Cihaz titreşimi etkin',
                    icon: Icons.vibration_rounded,
                    iconColor: AppThemeColors.accentPurple,
                    value: vibrationEnabled,
                    onChanged: (val) => setState(() => vibrationEnabled = val),
                  ),
                  const SizedBox(height: 20),

                  // Bildirim Zamanlaması
                  const Text(
                    'Bildirim Zamanlaması',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _NotificationTimingCard(
                    title: 'Hemen',
                    description: 'Bildirimleri anlık olarak al',
                    selected: notificationTiming == 'immediate',
                    onTap: () => setState(() => notificationTiming = 'immediate'),
                  ),
                  const SizedBox(height: 10),
                  _NotificationTimingCard(
                    title: 'Sessiz Saatlerde Kapat',
                    description: '22:00 - 08:00 arasında sustur',
                    selected: notificationTiming == 'silent_hours',
                    onTap: () => setState(() => notificationTiming = 'silent_hours'),
                  ),
                  const SizedBox(height: 10),
                  _NotificationTimingCard(
                    title: 'Daha Sonra Göster',
                    description: 'Önemli bildirimleri saatlik özetle',
                    selected: notificationTiming == 'quiet',
                    onTap: () => setState(() => notificationTiming = 'quiet'),
                  ),
                  const SizedBox(height: 20),

                  // Hassasiyet Seviyesi
                  const Text(
                    'Hassasiyet Seviyesi',
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Hassas (Her şey)'),
                            Radio<String>(
                              value: 'sensitive',
                              groupValue: 'sensitive',
                              onChanged: (_) {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Normal (Varsayılan)'),
                            Radio<String>(
                              value: 'normal',
                              groupValue: 'normal',
                              onChanged: (_) {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Az (Sadece kritik)'),
                            Radio<String>(
                              value: 'minimal',
                              groupValue: 'minimal',
                              onChanged: (_) {},
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Kaydet Butonu
                  FilledButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bildirim ayarları kaydedildi'),
                        ),
                      );
                      context.pop();
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Kaydet'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Varsayılan ayarlara sıfırlandı'),
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Sıfırla'),
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

class _NotificationToggleTile extends StatelessWidget {
  const _NotificationToggleTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool value;
  final Function(bool) onChanged;

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
              color: iconColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
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
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _NotificationTimingCard extends StatelessWidget {
  const _NotificationTimingCard({
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? AppThemeColors.accentCyan.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.06),
          border: Border.all(
            color: selected ? AppThemeColors.accentCyan : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppThemeColors.accentCyan : Colors.white54,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppThemeColors.accentCyan,
                        ),
                      ),
                    )
                  : null,
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
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
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
