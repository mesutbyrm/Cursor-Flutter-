import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';

/// Profil Düzenleme — Ad, bio, avatar, kategori, fiyat.
class PsychicProfileEditScreen extends ConsumerStatefulWidget {
  const PsychicProfileEditScreen({super.key});

  @override
  ConsumerState<PsychicProfileEditScreen> createState() =>
      _PsychicProfileEditScreenState();
}

class _PsychicProfileEditScreenState
    extends ConsumerState<PsychicProfileEditScreen> {
  late TextEditingController nameCtrl;
  late TextEditingController bioCtrl;
  late TextEditingController experienceCtrl;
  late TextEditingController priceCtrl;
  late TextEditingController languagesCtrl;

  String selectedCategory = 'tarot';
  String selectedAvatar = 'avatar_1';
  bool isVerified = true;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: 'Ayşe Kaya');
    bioCtrl = TextEditingController(
      text: 'Tarot, fal ve numeroloji uzmanı. 10 yıllık deneyim.',
    );
    experienceCtrl = TextEditingController(text: '10');
    priceCtrl = TextEditingController(text: '49.99');
    languagesCtrl = TextEditingController(text: 'Türkçe, İngilizce');
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    bioCtrl.dispose();
    experienceCtrl.dispose();
    priceCtrl.dispose();
    languagesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const categories = [
      ('tarot', 'Tarot'),
      ('numerology', 'Numeroloji'),
      ('astrology', 'Astroloji'),
      ('palmistry', 'El Falı'),
      ('fortune_telling', 'Fal'),
      ('energy_reading', 'Enerji Okuma'),
      ('life_coaching', 'Yaşam Koçluğu'),
      ('spiritual_guidance', 'Ruhsal Rehberlik'),
    ];

    const avatars = [
      'avatar_1',
      'avatar_2',
      'avatar_3',
      'avatar_4',
      'avatar_5',
      'avatar_6',
    ];

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
                      title: 'Profili Düzenle',
                      subtitle: 'Bilgilerinizi güncelleyin',
                    ),
                  ),
                  DiscoverIconButton(
                    icon: Icons.check_rounded,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profil kaydedildi')),
                      );
                      context.pop();
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  // Avatar selection
                  const Text(
                    'Avatar',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppThemeColors.accentCyan,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: avatars.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final avatar = avatars[i];
                        final isSelected = selectedAvatar == avatar;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => selectedAvatar = avatar),
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? AppThemeColors.accentCyan
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: CircleAvatar(
                              backgroundColor: Colors.grey[700],
                              child: Text(
                                avatar.split('_').last,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Name
                  const Text(
                    'Ad Soyadı',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bio
                  const Text(
                    'Biyografi',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: bioCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                      hintText: 'Uzmanlaştığınız alanlar, deneyiminiz vb.',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category
                  const Text(
                    'Kategori',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    items: categories
                        .map((cat) => DropdownMenuItem(
                              value: cat.$1,
                              child: Text(cat.$2),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => selectedCategory = val);
                      }
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Experience
                  const Text(
                    'Deneyim (yıl)',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: experienceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Hourly price
                  const Text(
                    'Saatlik Fiyat (₺)',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                      prefix: const Text('₺ '),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Languages
                  const Text(
                    'Konuştuğu Diller',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: languagesCtrl,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                      hintText: 'Virgülle ayırarak yazın',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Verification status
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isVerified
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isVerified ? Colors.green : Colors.orange,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isVerified
                              ? Icons.verified_user_rounded
                              : Icons.info_rounded,
                          color: isVerified ? Colors.green : Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isVerified
                                    ? 'Doğrulanmış Falcı'
                                    : 'Doğrulama Bekleniyor',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: isVerified
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isVerified
                                    ? 'Profiliniz müşteriler tarafından görülebilir'
                                    : 'Yönetici onayı bekleniyor',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Save & Cancel buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.pop(),
                          child: const Text('İptal'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Profil kaydedildi'),
                              ),
                            );
                            context.pop();
                          },
                          child: const Text('Kaydet'),
                        ),
                      ),
                    ],
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
