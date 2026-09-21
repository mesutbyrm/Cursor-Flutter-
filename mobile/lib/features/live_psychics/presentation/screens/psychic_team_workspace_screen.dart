import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/ui/premium_2026/cosmic_galaxy_background.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';

class PsychicTeamWorkspaceScreen extends ConsumerStatefulWidget {
  const PsychicTeamWorkspaceScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PsychicTeamWorkspaceScreen> createState() =>
      _PsychicTeamWorkspaceScreenState();
}

class _PsychicTeamWorkspaceScreenState
    extends ConsumerState<PsychicTeamWorkspaceScreen>
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
            'Takım Çalışması',
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
              Tab(text: 'Üyeler'),
              Tab(text: 'Vardiyalar'),
              Tab(text: 'İşbirliği'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _TeamMembersTab(),
            _ShiftsTab(),
            _CollaborationTab(),
          ],
        ),
      ),
    );
  }
}

class _TeamMembersTab extends StatefulWidget {
  @override
  State<_TeamMembersTab> createState() => _TeamMembersTabState();
}

class _TeamMembersTabState extends State<_TeamMembersTab> {
  late List<Map<String, dynamic>> teamMembers;

  @override
  void initState() {
    super.initState();
    teamMembers = [
      {
        'name': 'Siz (Yönetici)',
        'role': 'Yönetici',
        'status': 'Çevrimiçi',
        'sessions': 45,
        'rating': 4.8,
        'joinDate': '2026-01-15',
      },
      {
        'name': 'Merve Yılmaz',
        'role': 'Üye',
        'status': 'Çevrimiçi',
        'sessions': 28,
        'rating': 4.6,
        'joinDate': '2026-06-10',
      },
      {
        'name': 'Özlem Aydın',
        'role': 'Üye',
        'status': 'Çevrimdışı',
        'sessions': 15,
        'rating': 4.4,
        'joinDate': '2026-07-22',
      },
      {
        'name': 'Aslı Şahiner',
        'role': 'Üye',
        'status': 'Çevrimiçi',
        'sessions': 32,
        'rating': 4.9,
        'joinDate': '2026-05-18',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Takım Üyeleri',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ...teamMembers.map((member) => Container(
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
                          member['name'],
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppThemeColors.accentCyan
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                member['role'],
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppThemeColors.accentCyan,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              member['status'] == 'Çevrimiçi'
                                  ? Icons.circle
                                  : Icons.circle_outlined,
                              color: member['status'] == 'Çevrimiçi'
                                  ? Colors.green
                                  : Colors.grey,
                              size: 8,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              member['status'],
                              style: TextStyle(
                                fontSize: 10,
                                color: member['status'] == 'Çevrimiçi'
                                    ? Colors.green
                                    : Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Colors.amber, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            member['rating'].toString(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${member["sessions"]} seans',
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
              Text(
                'Katıldı: ${member["joinDate"]}',
                style: TextStyle(fontSize: 10, color: Colors.white54),
              ),
              if (member['role'] != 'Yönetici')
                Row(
                  children: [
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: const Text('İzinleri Düzenle'),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${member["name"]} izinleri açılıyor',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                        PopupMenuItem(
                          child: const Text('Çıkar'),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${member["name"]} takımdan çıkarıldı',
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
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Yeni üye davet ediliyor...'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          icon: const Icon(Icons.person_add_rounded, size: 18),
          label: const Text('Üye Davet Et'),
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
}

class _ShiftsTab extends StatefulWidget {
  @override
  State<_ShiftsTab> createState() => _ShiftsTabState();
}

class _ShiftsTabState extends State<_ShiftsTab> {
  late List<Map<String, dynamic>> shifts;

  @override
  void initState() {
    super.initState();
    shifts = [
      {
        'date': 'Bugün',
        'time': '14:00 - 23:00',
        'members': ['Siz', 'Merve Yılmaz', 'Aslı Şahiner'],
        'online': 3,
      },
      {
        'date': 'Yarın',
        'time': '10:00 - 18:00',
        'members': ['Özlem Aydın', 'Merve Yılmaz'],
        'online': 1,
      },
      {
        'date': 'Pazar',
        'time': '15:00 - 23:00',
        'members': ['Siz', 'Aslı Şahiner'],
        'online': 1,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Vardiyalar',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ...shifts.map((shift) => Container(
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
                        shift['date'],
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.schedule_rounded,
                              size: 14, color: Colors.white54),
                          const SizedBox(width: 4),
                          Text(
                            shift['time'],
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppThemeColors.accentCyan
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${shift["online"]} çevrimiçi',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppThemeColors.accentCyan,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Üyeler:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: (shift['members'] as List<String>)
                    .map((member) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        member,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ))
                    .toList(),
              ),
            ],
          ),
        )),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Yeni vardiya oluşturuluyor...'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Yeni Vardiya'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}

class _CollaborationTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collaborationNotes = [
      {
        'author': 'Merve Yılmaz',
        'message': 'Müşteri Ayşe K. için özel notlar ekledim',
        'time': '2 dakika önce',
        'type': 'Müşteri Notu',
      },
      {
        'author': 'Aslı Şahiner',
        'message': 'Yeni seans paketi hakkında fikirler',
        'time': '1 saat önce',
        'type': 'Öneriler',
      },
      {
        'author': 'Siz',
        'message': 'Bugünün hedefi: 10 seans tamamla',
        'time': '3 saat önce',
        'type': 'Hedef',
      },
      {
        'author': 'Özlem Aydın',
        'message': 'Sistem güncellemesi hakkında soru',
        'time': 'Dün',
        'type': 'Soru',
      },
      {
        'author': 'Merve Yılmaz',
        'message': 'İyi seanslar geçirdim, teşekkürler!',
        'time': '2 gün önce',
        'type': 'Durum',
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'İşbirliği Notu',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ...collaborationNotes.map((note) => Container(
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
                        note['author'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getNoteTypeColor(note['type'] as String)
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          note['type'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            color: _getNoteTypeColor(note['type'] as String),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    note['time'] as String,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                note['message'] as String,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        )),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            hintText: 'Not yaz...',
            hintStyle: TextStyle(color: Colors.white54),
            prefixIcon: const Icon(Icons.edit_note_rounded,
                color: AppThemeColors.accentCyan),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                  color: AppThemeColors.accentCyan.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                  color: AppThemeColors.accentCyan.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                  color: AppThemeColors.accentCyan, width: 2),
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
          ),
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Not eklendi: "$value"'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Color _getNoteTypeColor(String type) {
    switch (type) {
      case 'Müşteri Notu':
        return Colors.blue;
      case 'Öneriler':
        return Colors.green;
      case 'Hedef':
        return Colors.purple;
      case 'Soru':
        return Colors.orange;
      case 'Durum':
        return Colors.cyan;
      default:
        return Colors.white;
    }
  }
}
