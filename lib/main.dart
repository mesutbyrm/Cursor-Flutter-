import 'package:flutter/material.dart';

void main() {
  runApp(const CanlifalApp());
}

class CanlifalApp extends StatelessWidget {
  const CanlifalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Canlifal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C3AED),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFAF7FF),
        useMaterial3: true,
      ),
      home: const CanlifalHomePage(),
    );
  }
}

class CanlifalHomePage extends StatefulWidget {
  const CanlifalHomePage({super.key});

  @override
  State<CanlifalHomePage> createState() => _CanlifalHomePageState();
}

class _CanlifalHomePageState extends State<CanlifalHomePage> {
  static const List<_Destination> _destinations = <_Destination>[
    _Destination(
      label: 'Ana Sayfa',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      subtitle: 'Keşfet',
    ),
    _Destination(
      label: 'Videolar',
      icon: Icons.play_circle_outline,
      selectedIcon: Icons.play_circle,
      subtitle: 'Video yorumlar',
    ),
    _Destination(
      label: 'Canlı',
      icon: Icons.live_tv_outlined,
      selectedIcon: Icons.live_tv,
      subtitle: 'Canlı yayınlar',
    ),
    _Destination(
      label: 'Falcılar',
      icon: Icons.auto_awesome_outlined,
      selectedIcon: Icons.auto_awesome,
      subtitle: 'Uzmanlar',
    ),
    _Destination(
      label: 'Fal',
      icon: Icons.local_fire_department_outlined,
      selectedIcon: Icons.local_fire_department,
      subtitle: 'Fal gönder',
    ),
  ];

  int _currentIndex = 0;
  bool _isRefreshing = false;

  @override
  Widget build(BuildContext context) {
    final _Destination activeDestination = _destinations[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('Canlifal'),
            Text(
              activeDestination.subtitle,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Ana sayfaya dön',
            icon: const Icon(Icons.arrow_back),
            onPressed: _goHome,
          ),
          IconButton(
            tooltip: 'Yenile',
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            if (_isRefreshing) const LinearProgressIndicator(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _SectionBody(
                  key: ValueKey<int>(_currentIndex),
                  index: _currentIndex,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() => _currentIndex = index);
        },
        destinations: <Widget>[
          for (final _Destination destination in _destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
              label: destination.label,
            ),
        ],
      ),
    );
  }

  void _goHome() {
    if (_currentIndex == 0) {
      return;
    }

    setState(() => _currentIndex = 0);
  }

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (!mounted) {
      return;
    }

    setState(() => _isRefreshing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Canlifal içeriği yenilendi')),
    );
  }
}

class _SectionBody extends StatelessWidget {
  const _SectionBody({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      children: <Widget>[
        if (index == 0) const _HomeSection(),
        if (index == 1) const _VideosSection(),
        if (index == 2) const _LiveSection(),
        if (index == 3) const _FortuneTellersSection(),
        if (index == 4) const _FortuneSection(),
      ],
    );
  }
}

class _HomeSection extends StatelessWidget {
  const _HomeSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HeroCard(),
        SizedBox(height: 16),
        _SectionTitle(title: 'Bugün öne çıkanlar'),
        SizedBox(height: 10),
        _FeatureGrid(),
        SizedBox(height: 16),
        _SectionTitle(title: 'Popüler falcılar'),
        SizedBox(height: 10),
        _ExpertCard(
          name: 'Mira',
          specialty: 'Kahve falı ve ilişki yorumu',
          rating: '4.9',
          status: 'Çevrim içi',
          color: Color(0xFF7C3AED),
        ),
        SizedBox(height: 12),
        _ExpertCard(
          name: 'Defne',
          specialty: 'Tarot ve enerji açılımı',
          rating: '4.8',
          status: '5 dk içinde uygun',
          color: Color(0xFFEC4899),
        ),
      ],
    );
  }
}

class _VideosSection extends StatelessWidget {
  const _VideosSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _SectionHeader(
          icon: Icons.play_circle,
          title: 'Video yorumlar',
          text: 'Fal yorumlarını kısa videolarla takip et.',
        ),
        SizedBox(height: 16),
        _VideoCard(
          title: 'Aşk hayatında yeni dönem',
          duration: '03:24',
          accent: Color(0xFF7C3AED),
        ),
        SizedBox(height: 12),
        _VideoCard(
          title: 'Kahve telvesinde çıkan 5 işaret',
          duration: '05:10',
          accent: Color(0xFFEC4899),
        ),
        SizedBox(height: 12),
        _VideoCard(
          title: 'Haftanın tarot mesajı',
          duration: '04:42',
          accent: Color(0xFFF59E0B),
        ),
      ],
    );
  }
}

class _LiveSection extends StatelessWidget {
  const _LiveSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _SectionHeader(
          icon: Icons.live_tv,
          title: 'Canlı yayınlar',
          text: 'Canlı fal yayınlarını ve anlık yorumları izle.',
        ),
        SizedBox(height: 16),
        _LiveCard(),
        SizedBox(height: 14),
        _InfoCard(
          icon: Icons.notifications_active_outlined,
          title: 'Yayın hatırlatıcısı',
          text: 'Yeni canlı yayın başladığında bildirim al.',
        ),
      ],
    );
  }
}

class _FortuneTellersSection extends StatelessWidget {
  const _FortuneTellersSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _SectionHeader(
          icon: Icons.auto_awesome,
          title: 'Falcılar',
          text: 'Deneyimli yorumcular arasından seçim yap.',
        ),
        SizedBox(height: 16),
        _ExpertCard(
          name: 'Selin',
          specialty: 'Tarot, numeroloji',
          rating: '5.0',
          status: 'Hemen uygun',
          color: Color(0xFF7C3AED),
        ),
        SizedBox(height: 12),
        _ExpertCard(
          name: 'Aylin',
          specialty: 'Kahve falı',
          rating: '4.9',
          status: 'Çevrim içi',
          color: Color(0xFF10B981),
        ),
        SizedBox(height: 12),
        _ExpertCard(
          name: 'Ekin',
          specialty: 'Astroloji ve ilişki',
          rating: '4.8',
          status: 'Yoğun',
          color: Color(0xFFF59E0B),
        ),
      ],
    );
  }
}

class _FortuneSection extends StatelessWidget {
  const _FortuneSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _SectionHeader(
          icon: Icons.local_fire_department,
          title: 'Fal gönder',
          text: 'Kahve fincanı, tarot ya da günlük niyet için fal seç.',
        ),
        SizedBox(height: 16),
        _FortuneOption(
          icon: Icons.coffee,
          title: 'Kahve falı',
          text: 'Fincan fotoğrafını yükle, yorumunu al.',
        ),
        SizedBox(height: 12),
        _FortuneOption(
          icon: Icons.style,
          title: 'Tarot açılımı',
          text: 'Aşk, kariyer ya da genel enerji seç.',
        ),
        SizedBox(height: 12),
        _FortuneOption(
          icon: Icons.nights_stay_outlined,
          title: 'Günlük niyet',
          text: 'Bugünün mesajını hızlıca öğren.',
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF7C3AED), Color(0xFFEC4899)],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Canlifal mobil deneyimi',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Fal, canlı yayın ve uzman yorumcular tek ekranda.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Bu sürüm native Flutter arayüzüdür; WebView hata ekranı yerine uygulama tasarımı görünür.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.86),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF7C3AED),
            ),
            onPressed: () {},
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Hemen keşfet'),
          ),
        ],
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: <Widget>[
        Expanded(
          child: _MiniFeatureCard(
            icon: Icons.live_tv,
            title: 'Canlı',
            text: 'Yayınlar',
            color: Color(0xFFEF4444),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _MiniFeatureCard(
            icon: Icons.coffee,
            title: 'Kahve',
            text: 'Fal yorumu',
            color: Color(0xFF7C3AED),
          ),
        ),
      ],
    );
  }
}

class _MiniFeatureCard extends StatelessWidget {
  const _MiniFeatureCard({
    required this.icon,
    required this.title,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            foregroundColor: color,
            child: Icon(icon),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ExpertCard extends StatelessWidget {
  const _ExpertCard({
    required this.name,
    required this.specialty,
    required this.rating,
    required this.status,
    required this.color,
  });

  final String name;
  final String specialty;
  final String rating;
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withValues(alpha: 0.14),
            foregroundColor: color,
            child: Text(
              name.characters.first,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
                Text(specialty),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    _Pill(icon: Icons.star, text: rating),
                    _Pill(icon: Icons.circle, text: status),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({
    required this.title,
    required this.duration,
    required this.accent,
  });

  final String title;
  final String duration;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Row(
        children: <Widget>[
          Container(
            width: 82,
            height: 70,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.play_arrow_rounded, color: accent, size: 42),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                _Pill(icon: Icons.schedule, text: duration),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveCard extends StatelessWidget {
  const _LiveCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'CANLI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.visibility, color: Colors.white70, size: 18),
              const SizedBox(width: 6),
              const Text('1.2K', style: TextStyle(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 36),
          const Icon(Icons.auto_awesome, color: Colors.white, size: 42),
          const SizedBox(height: 16),
          const Text(
            'Gece tarot yayını başladı',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sorunu gönder, canlı yayında cevaplanma şansı yakala.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _FortuneOption extends StatelessWidget {
  const _FortuneOption({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Row(
        children: <Widget>[
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            child: Icon(icon),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(text),
              ],
            ),
          ),
          FilledButton(onPressed: () {}, child: const Text('Seç')),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Row(
        children: <Widget>[
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(text),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 26,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            child: Icon(icon),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(text),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Text(text, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(
                alpha: 0.45,
              ),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Destination {
  const _Destination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.subtitle,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String subtitle;
}
