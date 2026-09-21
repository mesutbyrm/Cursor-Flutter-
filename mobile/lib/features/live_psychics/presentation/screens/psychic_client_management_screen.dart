import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/ui/premium_2026/cosmic_galaxy_background.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';

class PsychicClientManagementScreen extends ConsumerStatefulWidget {
  const PsychicClientManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PsychicClientManagementScreen> createState() =>
      _PsychicClientManagementScreenState();
}

class _PsychicClientManagementScreenState
    extends ConsumerState<PsychicClientManagementScreen>
    with SingleTickerProviderStateMixin {
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
    return DiscoverBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.black.withValues(alpha: 0.3),
          centerTitle: true,
          title: const Text(
            'Müşteri Yönetimi',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppThemeColors.accentCyan,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'İlişkiler'),
              Tab(text: 'Destek'),
              Tab(text: 'Geri Bildirim'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _RelationshipsTab(),
            _SupportTicketsTab(),
            _FeedbackTab(),
          ],
        ),
      ),
    );
  }
}

class _RelationshipsTab extends StatefulWidget {
  @override
  State<_RelationshipsTab> createState() => _RelationshipsTabState();
}

class _RelationshipsTabState extends State<_RelationshipsTab> {
  late List<Map<String, dynamic>> clients;

  @override
  void initState() {
    super.initState();
    clients = [
      {
        'name': 'Ayşe Kara',
        'sessions': 12,
        'spending': '₺450',
        'lastSession': '2 gün önce',
        'relationship': 'VIP',
        'notes': 'Düzenli müşteri, Tarot severli',
      },
      {
        'name': 'Zeynep Mert',
        'sessions': 8,
        'spending': '₺320',
        'lastSession': '5 gün önce',
        'relationship': 'Normal',
        'notes': 'Astroloji ilgileri, soru sordu',
      },
      {
        'name': 'Fatma Yıldız',
        'sessions': 5,
        'spending': '₺280',
        'lastSession': '1 haftadır',
        'relationship': 'Potansiyel VIP',
        'notes': 'Yeni müşteri, hızlı büyüme',
      },
      {
        'name': 'Emre Demir',
        'sessions': 15,
        'spending': '₺680',
        'lastSession': '1 gün önce',
        'relationship': 'VIP+',
        'notes': 'En sadık müşteri, her tür seansı deneyen',
      },
      {
        'name': 'Müge Şahin',
        'sessions': 3,
        'spending': '₺150',
        'lastSession': '3 haftadır',
        'relationship': 'Churn Risk',
        'notes': 'Tekrar gelmesi gerekebilir',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Müşteri İlişkileri',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ...clients.map((client) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client['name'],
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getRelationshipColor(client['relationship'])
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            client['relationship'],
                            style: TextStyle(
                              fontSize: 10,
                              color: _getRelationshipColor(
                                  client['relationship']),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        client['spending'],
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppThemeColors.accentCyan,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${client["sessions"]} seans',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      client['notes'],
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Son seans: ${client["lastSession"]}',
                    style: TextStyle(fontSize: 10, color: Colors.white54),
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Text('İlişkiyi Yönet'),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('${client["name"]} ilişkisi açılıyor'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      PopupMenuItem(
                        child: const Text('Not Ekle'),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('${client["name"]} için not eklendi'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                    child: const Icon(Icons.more_vert_rounded,
                        color: Colors.white54, size: 18),
                  ),
                ],
              ),
            ],
          ),
        )),
      ],
    );
  }

  Color _getRelationshipColor(String relationship) {
    switch (relationship) {
      case 'VIP+':
        return Colors.amber;
      case 'VIP':
        return Colors.amber.shade700;
      case 'Potansiyel VIP':
        return Colors.blue;
      case 'Churn Risk':
        return Colors.red;
      default:
        return Colors.white;
    }
  }
}

class _SupportTicketsTab extends StatefulWidget {
  @override
  State<_SupportTicketsTab> createState() => _SupportTicketsTabState();
}

class _SupportTicketsTabState extends State<_SupportTicketsTab> {
  late List<Map<String, dynamic>> tickets;

  @override
  void initState() {
    super.initState();
    tickets = [
      {
        'id': '#T001',
        'customer': 'Ayşe Kara',
        'issue': 'Seans başlamadı, para iade',
        'status': 'Çözümlendi',
        'priority': 'Yüksek',
        'date': '2026-09-20',
      },
      {
        'id': '#T002',
        'customer': 'Zeynep Mert',
        'issue': 'Sistem hatası, seans kesildi',
        'status': 'Devam Ediyor',
        'priority': 'Yüksek',
        'date': '2026-09-21',
      },
      {
        'id': '#T003',
        'customer': 'Fatma Yıldız',
        'issue': 'Ödeme yöntemi sorunu',
        'status': 'Bekleniyor',
        'priority': 'Orta',
        'date': '2026-09-21',
      },
      {
        'id': '#T004',
        'customer': 'Emre Demir',
        'issue': 'Fatura talep',
        'status': 'Çözümlendi',
        'priority': 'Düşük',
        'date': '2026-09-19',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Destek Talepleri',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ...tickets.map((ticket) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
                        ticket['id'],
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppThemeColors.accentCyan,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ticket['customer'],
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(ticket['status'])
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      ticket['status'],
                      style: TextStyle(
                        fontSize: 10,
                        color: _getStatusColor(ticket['status']),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                ticket['issue'],
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getPriorityColor(ticket['priority'])
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          ticket['priority'],
                          style: TextStyle(
                            fontSize: 10,
                            color: _getPriorityColor(ticket['priority']),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ticket['date'],
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.open_in_new_rounded,
                        color: AppThemeColors.accentCyan, size: 18),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${ticket["id"]} açılıyor'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        )),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Yeni destek talebi oluşturuluyor...'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Yeni Talep'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppThemeColors.accentCyan,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Çözümlendi':
        return Colors.green;
      case 'Devam Ediyor':
        return Colors.blue;
      case 'Bekleniyor':
        return Colors.orange;
      default:
        return Colors.white;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Yüksek':
        return Colors.red;
      case 'Orta':
        return Colors.orange;
      case 'Düşük':
        return Colors.green;
      default:
        return Colors.white;
    }
  }
}

class _FeedbackTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedbackItems = [
      {
        'customer': 'Ayşe Kara',
        'rating': 5,
        'message':
            'Çok doğru tahminler! Her seans hayatımı değiştiriyor.',
        'date': '2026-09-20',
        'type': 'Pozitif',
      },
      {
        'customer': 'Zeynep Mert',
        'rating': 4,
        'message': 'İyi bir seans, fakat daha detaylı olabilirdi',
        'date': '2026-09-19',
        'type': 'Kısmen Olumlu',
      },
      {
        'customer': 'Fatma Yıldız',
        'rating': 5,
        'message': 'Harika bir deneyim, kesinlikle tavsiye ederim!',
        'date': '2026-09-18',
        'type': 'Pozitif',
      },
      {
        'customer': 'Müge Şahin',
        'rating': 3,
        'message': 'Orta düzey bir seans, beklediğim kadar iyi değildi',
        'date': '2026-09-17',
        'type': 'Tarafsız',
      },
      {
        'customer': 'Emre Demir',
        'rating': 5,
        'message': 'En iyi falcısın! Hep seni seçerim.',
        'date': '2026-09-16',
        'type': 'Pozitif',
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Müşteri Geri Bildirimi',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ...feedbackItems.map((feedback) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
                        feedback['customer'] as String,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: List.generate(
                          5,
                          (index) => Icon(
                            index < (feedback['rating'] as int)
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: Colors.amber,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getFeedbackColor(feedback['type'] as String)
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      feedback['type'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        color: _getFeedbackColor(feedback['type'] as String),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                feedback['message'] as String,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    feedback['date'] as String,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white54,
                    ),
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Text('Teşekkür Cevabı Gönder'),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${feedback["customer"]} ya teşekkür mesajı gönderildi',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      PopupMenuItem(
                        child: const Text('Rapor Et'),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${feedback["customer"]} "ın geri bildirimi rapor edildi',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                    child: const Icon(Icons.more_vert_rounded,
                        color: Colors.white54, size: 18),
                  ),
                ],
              ),
            ],
          ),
        )),
      ],
    );
  }

  Color _getFeedbackColor(String type) {
    switch (type) {
      case 'Pozitif':
        return Colors.green;
      case 'Kısmen Olumlu':
        return Colors.blue;
      case 'Tarafsız':
        return Colors.orange;
      default:
        return Colors.white;
    }
  }
}
