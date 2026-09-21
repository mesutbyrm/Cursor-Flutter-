import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/ui/premium_2026/cosmic_galaxy_background.dart';

class PsychicAiChatbotScreen extends ConsumerStatefulWidget {
  const PsychicAiChatbotScreen({super.key});

  @override
  ConsumerState<PsychicAiChatbotScreen> createState() =>
      _PsychicAiChatbotScreenState();
}

class _PsychicAiChatbotScreenState extends ConsumerState<PsychicAiChatbotScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const CosmicGalaxyBackground(),
          SingleChildScrollView(
            child: Column(
              children: [
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  title: const Text(
                    'AI Chatbot Asistanı',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  centerTitle: true,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppThemeColors.accentCyan.withValues(alpha: 0.2),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
                    tabs: const [
                      Tab(text: 'Seanslar'),
                      Tab(text: 'Şablonlar'),
                      Tab(text: 'Ayarlar'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _ConversationsTab(),
                      _TemplatesTab(),
                      _SettingsTab(),
                    ],
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

class _ConversationsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final conversations = [
      {
        'customer': 'Ayşe K.',
        'lastMessage': 'Hangi paketinizi tavsiye edersiniz?',
        'responseTime': '2 dk',
        'satisfaction': 4.8,
        'status': 'Aktif',
        'handedOff': false,
      },
      {
        'customer': 'Mehmet D.',
        'lastMessage': 'Seans saatleri neler?',
        'responseTime': '45 sn',
        'satisfaction': 5.0,
        'status': 'Tamamlandı',
        'handedOff': false,
      },
      {
        'customer': 'Zeynep T.',
        'lastMessage': 'Daha spesifik bir yanıt lazım...',
        'responseTime': '3 dk',
        'satisfaction': 3.5,
        'status': 'Yönlendirildi',
        'handedOff': true,
      },
      {
        'customer': 'Ali Y.',
        'lastMessage': 'İlk kez hoşlanmış, teşekkürler!',
        'responseTime': '1 dk',
        'satisfaction': 5.0,
        'status': 'Tamamlandı',
        'handedOff': false,
      },
      {
        'customer': 'Funda M.',
        'lastMessage': 'Ödeme sorunuyla ilgili...',
        'responseTime': '5 dk',
        'satisfaction': 4.0,
        'status': 'Yönlendirildi',
        'handedOff': true,
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Color(0xFF66BB6A).withValues(alpha: 0.3),
              ),
              color: Color(0xFF66BB6A).withValues(alpha: 0.1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chatbot Durumu',
                      style: TextStyle(fontSize: 12, color: Color(0xFF66BB6A)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Çalışıyor',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF66BB6A),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Ort. Yanıt Süresi',
                      style: TextStyle(fontSize: 12, color: Color(0xFF66BB6A)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '2.3 dk',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF66BB6A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Yakın Zamanlı Seanslar',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...conversations.map((c) {
            final satisfaction = c['satisfaction'] as double;
            final isHandedOff = c['handedOff'] as bool;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  color: Colors.white.withValues(alpha: 0.03),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c['customer'] as String,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              c['lastMessage'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Color(0xFFFFD54F), size: 16),
                                const SizedBox(width: 2),
                                Text(
                                  satisfaction.toStringAsFixed(1),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              c['responseTime'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: isHandedOff ? Color(0xFFEF5350).withValues(alpha: 0.2) :
                                   (c['status'] as String).contains('Tamamlandı') ? Color(0xFF66BB6A).withValues(alpha: 0.2) :
                                   Color(0xFF4FC3F7).withValues(alpha: 0.2),
                          ),
                          child: Text(
                            c['status'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isHandedOff ? Color(0xFFEF5350) :
                                     (c['status'] as String).contains('Tamamlandı') ? Color(0xFF66BB6A) :
                                     Color(0xFF4FC3F7),
                            ),
                          ),
                        ),
                        if (isHandedOff)
                          const Text(
                            'İnsan temsilci tarafından işleniyor',
                            style: TextStyle(fontSize: 10, color: Color(0xFFEF5350)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          const Text(
            'Chatbot İstatistikleri',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
              color: Colors.white.withValues(alpha: 0.03),
            ),
            child: Column(
              children: [
                _buildStatRow('Bugün İşlenen', '24 sohbet'),
                const SizedBox(height: 10),
                _buildStatRow('Ort. Memnuniyet', '4.6/5.0 ⭐'),
                const SizedBox(height: 10),
                _buildStatRow('Çözümleme Oranı', '78%'),
                const SizedBox(height: 10),
                _buildStatRow('İnsan Yönlendirmesi', '22%'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7)),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _TemplatesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final templates = [
      {
        'category': 'Selamlama',
        'responses': [
          'Hoş geldiniz! Size nasıl yardımcı olabilirim?',
          'Merhaba! 👋 Soran bir sorunuz varsa sorabilirsiniz',
        ],
        'uses': 142,
        'icon': Icons.waving_hand_rounded,
      },
      {
        'category': 'Paket Bilgisi',
        'responses': [
          'Üç paketimiz var: Başlangıç (₺50), Premium (₺120), VIP (₺250)',
          'Hangi paket en uygun sizin için hangisidir?',
        ],
        'uses': 89,
        'icon': Icons.card_giftcard_rounded,
      },
      {
        'category': 'Saat ve Mevcut Durum',
        'responses': [
          'Şu anda müsait değilim, daha sonra kontrol edebilir misiniz?',
          'Saat 18:00 sonrası seanslar mümkün',
        ],
        'uses': 67,
        'icon': Icons.schedule_rounded,
      },
      {
        'category': 'Ödeme Sorunları',
        'responses': [
          'Ödeme konusu hakkında endişeleriniz var mı? Detay verebilir misiniz?',
          'Ödeme sorularınız için lütfen destek ekibimize yönlendirileceksiniz',
        ],
        'uses': 34,
        'icon': Icons.payment_rounded,
      },
      {
        'category': 'Teşekkür Cevapları',
        'responses': [
          'Teşekkür ederim! Umarım seansı beğenmişsinizdir 🙏',
          'Memnuniyet duymaktan çok mutluyum!',
        ],
        'uses': 156,
        'icon': Icons.favorite_rounded,
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Otomatik Yanıt Şablonları',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...templates.map((t) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  color: Colors.white.withValues(alpha: 0.03),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppThemeColors.accentPurple.withValues(alpha: 0.2),
                          ),
                          child: Icon(
                            t['icon'] as IconData,
                            color: AppThemeColors.accentPurple,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            t['category'] as String,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Chip(
                          label: Text('${t['uses']}x'),
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          labelStyle: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...((t['responses'] as List).cast<String>()).map((response) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                          child: Text(
                            '• $response',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${t['category']} şablonu düzenleniyor...'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppThemeColors.accentPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text('Düzenle', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SettingsTab extends StatefulWidget {
  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  bool _chatbotEnabled = true;
  bool _autoResponse = true;
  bool _escalateUnsolved = true;
  String _selectedLanguage = 'Türkçe';
  String _selectedTone = 'Profesyonel';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chatbot Aktivasyonu',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
              color: Colors.white.withValues(alpha: 0.03),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chatbot Aktif',
                  style: TextStyle(fontSize: 13),
                ),
                Switch(
                  value: _chatbotEnabled,
                  onChanged: (value) => setState(() => _chatbotEnabled = value),
                  activeColor: Color(0xFF66BB6A),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Yanıt Ayarları',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
              color: Colors.white.withValues(alpha: 0.03),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Otomatik Yanıt',
                      style: TextStyle(fontSize: 13),
                    ),
                    Switch(
                      value: _autoResponse,
                      onChanged: (value) => setState(() => _autoResponse = value),
                      activeColor: Color(0xFF4FC3F7),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Çözülemezse Yönlendir',
                      style: TextStyle(fontSize: 13),
                    ),
                    Switch(
                      value: _escalateUnsolved,
                      onChanged: (value) => setState(() => _escalateUnsolved = value),
                      activeColor: Color(0xFFFFD54F),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Dil Seçimi',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
              color: Colors.white.withValues(alpha: 0.03),
            ),
            child: DropdownButton<String>(
              value: _selectedLanguage,
              dropdownColor: Colors.grey[900],
              isExpanded: true,
              underline: const SizedBox(),
              style: const TextStyle(color: Colors.white),
              items: ['Türkçe', 'English', 'Español', 'Français', 'Deutsch']
                  .map((lang) => DropdownMenuItem(
                        value: lang,
                        child: Text(lang),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedLanguage = value);
                }
              },
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Cevap Stili',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
              color: Colors.white.withValues(alpha: 0.03),
            ),
            child: DropdownButton<String>(
              value: _selectedTone,
              dropdownColor: Colors.grey[900],
              isExpanded: true,
              underline: const SizedBox(),
              style: const TextStyle(color: Colors.white),
              items: ['Profesyonel', 'Samimi', 'Mistikal', 'Edebiyatsal', 'Mizahi']
                  .map((tone) => DropdownMenuItem(
                        value: tone,
                        child: Text(tone),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedTone = value);
                }
              },
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ayarlar kaydedildi'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text('Değişiklikleri Kaydet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF66BB6A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
