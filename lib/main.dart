import 'package:flutter/material.dart';

import 'models/app_models.dart';
import 'services/app_repository.dart';
import 'services/trtc_service.dart';

const String kAppName = 'VivaLive';
const String kLogoAsset = 'assets/brand/vivalive_logo.png';

void main() {
  runApp(const VivaLiveApp());
}

class VivaLiveApp extends StatefulWidget {
  const VivaLiveApp({super.key});

  @override
  State<VivaLiveApp> createState() => _VivaLiveAppState();
}

class _VivaLiveAppState extends State<VivaLiveApp> {
  final AppRepository _repository = AppRepository();
  bool _showSplash = true;
  bool _isAuthenticated = false;
  AppUser? _currentUser;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _showSplash = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C3AED),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F3FF),
        useMaterial3: true,
      ),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        child: _showSplash
            ? const SplashScreen()
            : _isAuthenticated
            ? SocialShell(
                repository: _repository,
                currentUser: _currentUser,
                onLogout: () {
                  setState(() {
                    _isAuthenticated = false;
                    _currentUser = null;
                  });
                },
              )
            : AuthScreen(
                repository: _repository,
                onAuthenticated: (AppUser? user) {
                  setState(() {
                    _isAuthenticated = true;
                    _currentUser = user;
                  });
                },
              ),
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF13052E),
              Color(0xFF4C1D95),
              Color(0xFFEC4899),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const _LogoMark(size: 118, showGlow: true),
              const SizedBox(height: 22),
              const Text(
                kAppName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Canlı yayın • Sesli oda • Sosyal akış',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 42),
              SizedBox(
                width: 130,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.repository,
    required this.onAuthenticated,
  });

  final AppRepository repository;
  final ValueChanged<AppUser?> onAuthenticated;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _birthTimeController = TextEditingController();
  final TextEditingController _referralController = TextEditingController();
  bool _isRegister = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _birthDateController.text = '1995-06-20';
    _birthTimeController.text = '14:30';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _birthDateController.dispose();
    _birthTimeController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF080312),
              Color(0xFF2E1065),
              Color(0xFFEC4899),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Center(child: _LogoMark(size: 92, showGlow: true)),
                    const SizedBox(height: 18),
                    const Text(
                      kAppName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Canlı yayınlara, sesli odalara ve sosyal akışa katıl.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 26),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: _AuthModeButton(
                              selected: !_isRegister,
                              text: 'Giriş',
                              onTap: () => setState(() => _isRegister = false),
                            ),
                          ),
                          Expanded(
                            child: _AuthModeButton(
                              selected: _isRegister,
                              text: 'Kayıt',
                              onTap: () => setState(() => _isRegister = true),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _isRegister
                          ? _RegisterFields(
                              key: const ValueKey<String>('register'),
                              nameController: _nameController,
                              usernameController: _usernameController,
                              birthDateController: _birthDateController,
                              birthTimeController: _birthTimeController,
                              referralController: _referralController,
                            )
                          : const SizedBox(key: ValueKey<String>('login')),
                    ),
                    _AuthTextField(
                      controller: _emailController,
                      label: 'E-posta',
                      icon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    _AuthTextField(
                      controller: _passwordController,
                      label: 'Şifre',
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffix: IconButton(
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF7C3AED),
                      ),
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isRegister ? 'Hesap oluştur' : 'Giriş yap'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.44),
                        ),
                      ),
                      onPressed: _isLoading
                          ? null
                          : () => widget.onAuthenticated(_guestUser),
                      icon: const Icon(Icons.explore),
                      label: const Text('Misafir olarak devam et'),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Giriş: /api/auth/mobile-login • Kayıt: /api/auth/mobile-register',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.48),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _showMessage('E-posta ve şifre gerekli.');
      return;
    }
    if (_isRegister &&
        (_nameController.text.trim().isEmpty ||
            _usernameController.text.trim().isEmpty ||
            _birthDateController.text.trim().isEmpty ||
            _birthTimeController.text.trim().isEmpty)) {
      _showMessage(
        'Kayıt için ad, kullanıcı adı, doğum tarihi ve saati gerekli.',
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isRegister) {
        final AuthSession session = await widget.repository.register(
          name: _nameController.text.trim(),
          username: _usernameController.text.trim(),
          email: email,
          password: password,
          birthDate: _birthDateController.text.trim(),
          birthTime: _birthTimeController.text.trim(),
          referralCode: _referralController.text.trim().isEmpty
              ? null
              : _referralController.text.trim(),
        );
        if (!mounted) {
          return;
        }
        widget.onAuthenticated(session.user);
      } else {
        final AuthSession session = await widget.repository.login(
          email: email,
          password: password,
        );
        if (!mounted) {
          return;
        }
        widget.onAuthenticated(session.user);
      }
    } catch (error) {
      _showMessage('Giriş yapılamadı: $error');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

const AppUser _guestUser = AppUser(
  id: 'guest',
  name: 'Misafir Kullanıcı',
  username: 'misafir',
  avatarUrl: '',
  followers: 0,
  following: 0,
  likes: 0,
  isGold: false,
  coinBalance: 0,
);

class _RegisterFields extends StatelessWidget {
  const _RegisterFields({
    super.key,
    required this.nameController,
    required this.usernameController,
    required this.birthDateController,
    required this.birthTimeController,
    required this.referralController,
  });

  final TextEditingController nameController;
  final TextEditingController usernameController;
  final TextEditingController birthDateController;
  final TextEditingController birthTimeController;
  final TextEditingController referralController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _AuthTextField(
          controller: nameController,
          label: 'Ad soyad',
          icon: Icons.badge_outlined,
        ),
        const SizedBox(height: 12),
        _AuthTextField(
          controller: usernameController,
          label: 'Kullanıcı adı',
          icon: Icons.alternate_email,
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: _AuthTextField(
                controller: birthDateController,
                label: 'Doğum tarihi',
                icon: Icons.calendar_today_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _AuthTextField(
                controller: birthTimeController,
                label: 'Doğum saati',
                icon: Icons.schedule,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _AuthTextField(
          controller: referralController,
          label: 'Davet kodu (opsiyonel)',
          icon: Icons.card_giftcard,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _AuthModeButton extends StatelessWidget {
  const _AuthModeButton({
    required this.selected,
    required this.text,
    required this.onTap,
  });

  final bool selected;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? const Color(0xFF7C3AED) : Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.68)),
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
    );
  }
}

class _DarkTextField extends StatelessWidget {
  const _DarkTextField({
    required this.controller,
    required this.label,
    required this.icon,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.68)),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class SocialShell extends StatefulWidget {
  const SocialShell({
    super.key,
    required this.repository,
    required this.currentUser,
    required this.onLogout,
  });

  final AppRepository repository;
  final AppUser? currentUser;
  final VoidCallback onLogout;

  @override
  State<SocialShell> createState() => _SocialShellState();
}

class _SocialShellState extends State<SocialShell> {
  static const List<_Destination> _destinations = <_Destination>[
    _Destination('Akış', Icons.dynamic_feed_outlined, Icons.dynamic_feed),
    _Destination('Keşfet', Icons.travel_explore_outlined, Icons.travel_explore),
    _Destination('Canlı', Icons.live_tv_outlined, Icons.live_tv),
    _Destination('Odalar', Icons.graphic_eq_outlined, Icons.graphic_eq),
    _Destination('Profil', Icons.person_outline, Icons.person),
  ];

  late Future<List<FeedPostModel>> _feedFuture;
  late Future<List<LiveStreamModel>> _liveFuture;
  late Future<List<AudioRoomModel>> _roomFuture;
  late Future<List<GiftTypeModel>> _giftFuture;
  int _currentIndex = 0;
  bool _isRefreshing = false;
  bool _showLiveFullscreen = false;
  AudioRoomModel? _activeRoom;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final _Destination current = _destinations[_currentIndex];

    if (_showLiveFullscreen) {
      return FullScreenLivePage(
        repository: widget.repository,
        currentUser: widget.currentUser,
        liveFuture: _liveFuture,
        giftFuture: _giftFuture,
        onClose: () => setState(() => _showLiveFullscreen = false),
        onMessage: _showMessage,
      );
    }

    if (_activeRoom != null) {
      return VoiceRoomPage(
        repository: widget.repository,
        room: _activeRoom!,
        giftFuture: _giftFuture,
        onClose: () => setState(() => _activeRoom = null),
        onMessage: _showMessage,
      );
    }

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: Row(
          children: <Widget>[
            const _LogoMark(size: 38),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  kAppName,
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  '${current.label} • ${widget.currentUser?.name ?? 'Misafir'}',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ],
        ),
        actions: <Widget>[
          _UserBadge(user: widget.currentUser),
          _NotificationButton(count: 9, onTap: _showApiNotice),
          IconButton(
            tooltip: 'Mesajlar',
            onPressed: _showApiNotice,
            icon: const Icon(Icons.mark_chat_unread_outlined),
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 2 || _currentIndex == 3
          ? FloatingActionButton.extended(
              onPressed: _showApiNotice,
              icon: Icon(_currentIndex == 2 ? Icons.videocam : Icons.mic),
              label: Text(_currentIndex == 2 ? 'Yayın aç' : 'Oda aç'),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            if (_isRefreshing) const LinearProgressIndicator(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  child: _PageBody(
                    key: ValueKey<int>(_currentIndex),
                    index: _currentIndex,
                    onAction: _showApiNotice,
                    feedFuture: _feedFuture,
                    liveFuture: _liveFuture,
                    roomFuture: _roomFuture,
                    giftFuture: _giftFuture,
                    isApiConfigured: widget.repository.isConfigured,
                    onOpenLive: _openLiveFullscreen,
                    onOpenRoom: _openVoiceRoom,
                    currentUser: widget.currentUser,
                    onLogout: widget.onLogout,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: NavigationBar(
            height: 72,
            selectedIndex: _currentIndex,
            onDestinationSelected: _selectDestination,
            destinations: <Widget>[
              for (final _Destination destination in _destinations)
                NavigationDestination(
                  icon: Icon(destination.icon),
                  selectedIcon: Icon(destination.selectedIcon),
                  label: destination.label,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    _loadData();
    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (!mounted) {
      return;
    }

    setState(() => _isRefreshing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.repository.isConfigured
              ? 'API verileri yenilendi'
              : 'Demo veriler yenilendi. Canlı veri için API_BASE_URL gerekli.',
        ),
      ),
    );
  }

  void _showApiNotice() {
    _showMessage(
      widget.repository.isConfigured
          ? 'Bu aksiyon API endpointine bağlanmaya hazır.'
          : 'API_BASE_URL verilince bu alan canlı veriye bağlanacak.',
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _loadData() {
    _feedFuture = widget.repository.fetchFeed();
    _liveFuture = widget.repository.fetchLiveStreams();
    _roomFuture = widget.repository.fetchAudioRooms();
    _giftFuture = widget.repository.fetchGiftTypes();
  }

  void _openLiveFullscreen() {
    setState(() {
      _currentIndex = 2;
      _showLiveFullscreen = true;
    });
  }

  void _openVoiceRoom(AudioRoomModel room) {
    setState(() {
      _currentIndex = 3;
      _activeRoom = room;
    });
  }

  void _selectDestination(int index) {
    if (index == 2) {
      _openLiveFullscreen();
      return;
    }

    setState(() {
      _currentIndex = index;
      _showLiveFullscreen = false;
      _activeRoom = null;
    });
  }
}

class _PageBody extends StatelessWidget {
  const _PageBody({
    super.key,
    required this.index,
    required this.onAction,
    required this.feedFuture,
    required this.liveFuture,
    required this.roomFuture,
    required this.giftFuture,
    required this.isApiConfigured,
    required this.onOpenLive,
    required this.onOpenRoom,
    required this.currentUser,
    required this.onLogout,
  });

  final int index;
  final VoidCallback onAction;
  final Future<List<FeedPostModel>> feedFuture;
  final Future<List<LiveStreamModel>> liveFuture;
  final Future<List<AudioRoomModel>> roomFuture;
  final Future<List<GiftTypeModel>> giftFuture;
  final bool isApiConfigured;
  final VoidCallback onOpenLive;
  final ValueChanged<AudioRoomModel> onOpenRoom;
  final AppUser? currentUser;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 104),
      children: <Widget>[
        if (index == 0)
          FeedPage(
            onAction: onAction,
            feedFuture: feedFuture,
            isApiConfigured: isApiConfigured,
          ),
        if (index == 1) ExplorePage(onAction: onAction),
        if (index == 2)
          LivePage(
            onAction: onAction,
            onOpenLive: onOpenLive,
            liveFuture: liveFuture,
            giftFuture: giftFuture,
          ),
        if (index == 3)
          RoomsPage(
            onAction: onAction,
            roomFuture: roomFuture,
            onOpenRoom: onOpenRoom,
          ),
        if (index == 4)
          ProfilePage(
            onAction: onAction,
            currentUser: currentUser,
            onLogout: onLogout,
          ),
      ],
    );
  }
}

class FeedPage extends StatelessWidget {
  const FeedPage({
    super.key,
    required this.onAction,
    required this.feedFuture,
    required this.isApiConfigured,
  });

  final VoidCallback onAction;
  final Future<List<FeedPostModel>> feedFuture;
  final bool isApiConfigured;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HomeHero(onAction: onAction),
        const SizedBox(height: 18),
        const _StoryRail(),
        const SizedBox(height: 18),
        const _SectionTitle('Sosyal akış'),
        const SizedBox(height: 10),
        _ApiStatusBanner(
          isConfigured: isApiConfigured,
          liveText: 'Sosyal akış /api/social/feed endpointinden çekiliyor.',
          demoText:
              'Şu an demo akış gösteriliyor. Build sırasında API_BASE_URL verilirse canlı veriye bağlanır.',
        ),
        const SizedBox(height: 10),
        FutureBuilder<List<FeedPostModel>>(
          future: feedFuture,
          builder:
              (
                BuildContext context,
                AsyncSnapshot<List<FeedPostModel>> snapshot,
              ) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _LoadingCard(text: 'Akış yükleniyor...');
                }
                if (snapshot.hasError) {
                  return _ErrorCard(message: snapshot.error.toString());
                }
                final List<FeedPostModel> posts =
                    snapshot.data ?? DemoData.feedPosts;
                return Column(
                  children: <Widget>[
                    for (
                      int index = 0;
                      index < posts.length;
                      index++
                    ) ...<Widget>[
                      _FeedPost(
                        avatarColor: index.isEven
                            ? const Color(0xFF7C3AED)
                            : const Color(0xFF06B6D4),
                        name: posts[index].authorName,
                        username: posts[index].username,
                        text: posts[index].text,
                        likes: _compactCount(posts[index].likes),
                        comments: _compactCount(posts[index].comments),
                        onAction: onAction,
                      ),
                      if (index != posts.length - 1) const SizedBox(height: 12),
                    ],
                  ],
                );
              },
        ),
        const SizedBox(height: 18),
        const _SectionTitle('Hızlı sistemler'),
        const SizedBox(height: 10),
        _QuickGrid(onAction: onAction),
      ],
    );
  }
}

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key, required this.onAction});

  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SearchPanel(),
        const SizedBox(height: 16),
        const _SectionTitle('Trendler'),
        const SizedBox(height: 10),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _TrendChip('#canliyayinda'),
            _TrendChip('#seslioda'),
            _TrendChip('#hediyeyagmuru'),
            _TrendChip('#funclub'),
            _TrendChip('#goldhaftasi'),
          ],
        ),
        const SizedBox(height: 18),
        const _SectionTitle('12 yorum türü'),
        const SizedBox(height: 10),
        _FortuneTypesGrid(onAction: onAction),
        const SizedBox(height: 18),
        const _SectionTitle('Oyunlar ve görevler'),
        const SizedBox(height: 10),
        _GameCarousel(onAction: onAction),
      ],
    );
  }
}

class LivePage extends StatelessWidget {
  const LivePage({
    super.key,
    required this.onAction,
    required this.onOpenLive,
    required this.liveFuture,
    required this.giftFuture,
  });

  final VoidCallback onAction;
  final VoidCallback onOpenLive;
  final Future<List<LiveStreamModel>> liveFuture;
  final Future<List<GiftTypeModel>> giftFuture;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _LiveStage(onAction: onOpenLive),
        const SizedBox(height: 16),
        const _SectionTitle('Canlı yayınlar'),
        const SizedBox(height: 10),
        FutureBuilder<List<LiveStreamModel>>(
          future: liveFuture,
          builder:
              (
                BuildContext context,
                AsyncSnapshot<List<LiveStreamModel>> snapshot,
              ) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _LoadingCard(
                    text: 'Canlı yayınlar yükleniyor...',
                  );
                }
                if (snapshot.hasError) {
                  return _ErrorCard(message: snapshot.error.toString());
                }
                final List<LiveStreamModel> streams =
                    snapshot.data ?? DemoData.liveStreams;
                return Column(
                  children: <Widget>[
                    for (
                      int index = 0;
                      index < streams.length;
                      index++
                    ) ...<Widget>[
                      _LiveListTile(
                        title: streams[index].title,
                        host: streams[index].hostName,
                        viewers: _compactCount(streams[index].viewerCount),
                        color: index.isEven
                            ? const Color(0xFFEC4899)
                            : const Color(0xFF7C3AED),
                        onAction: onOpenLive,
                      ),
                      if (index != streams.length - 1)
                        const SizedBox(height: 10),
                    ],
                  ],
                );
              },
        ),
        const SizedBox(height: 16),
        _GiftPanel(onAction: onAction, giftFuture: giftFuture),
      ],
    );
  }
}

class FullScreenLivePage extends StatefulWidget {
  const FullScreenLivePage({
    super.key,
    required this.repository,
    required this.currentUser,
    required this.liveFuture,
    required this.giftFuture,
    required this.onClose,
    required this.onMessage,
  });

  final AppRepository repository;
  final AppUser? currentUser;
  final Future<List<LiveStreamModel>> liveFuture;
  final Future<List<GiftTypeModel>> giftFuture;
  final VoidCallback onClose;
  final ValueChanged<String> onMessage;

  @override
  State<FullScreenLivePage> createState() => _FullScreenLivePageState();
}

class _FullScreenLivePageState extends State<FullScreenLivePage> {
  final PageController _pageController = PageController();
  final TrtcService _trtcService = TrtcService();
  final TextEditingController _commentController = TextEditingController();
  late final String _viewerUserId =
      widget.currentUser?.id ??
      'viewer_${DateTime.now().millisecondsSinceEpoch}';

  ActiveTrtcSession? _activeSession;
  final List<LiveStreamModel> _createdStreams = <LiveStreamModel>[];
  String? _joinedStreamId;
  int _currentPage = 0;
  bool _connectingTrtc = false;
  String _trtcStatus = 'TRTC UserSig hazırlanıyor';

  @override
  void dispose() {
    _trtcService.leave(_activeSession);
    _pageController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<List<LiveStreamModel>>(
        future: widget.liveFuture,
        builder:
            (
              BuildContext context,
              AsyncSnapshot<List<LiveStreamModel>> snapshot,
            ) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _FullScreenLoading();
              }

              final List<LiveStreamModel> apiStreams = snapshot.hasError
                  ? DemoData.liveStreams
                  : snapshot.data ?? DemoData.liveStreams;
              final List<LiveStreamModel> streams = <LiveStreamModel>[
                ..._createdStreams,
                ...apiStreams,
              ];

              if (streams.isEmpty) {
                return _EmptyLiveFullscreen(
                  onClose: widget.onClose,
                  onCreate: _showCreateLiveSheet,
                );
              }

              final LiveStreamModel activeStream = streams[_currentPage];
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _joinTrtcIfReady(activeStream);
              });

              return Stack(
                children: <Widget>[
                  const Positioned.fill(child: _SafeLiveVideoPlaceholder()),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            Colors.black.withValues(alpha: 0.10),
                            Colors.black.withValues(alpha: 0.18),
                            Colors.black.withValues(alpha: 0.78),
                          ],
                        ),
                      ),
                    ),
                  ),
                  PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    itemCount: streams.length,
                    onPageChanged: (int index) {
                      setState(() => _currentPage = index);
                      _joinTrtcIfReady(streams[index], force: true);
                    },
                    itemBuilder: (BuildContext context, int index) {
                      return _LiveBackdrop(
                        stream: streams[index],
                        index: index,
                      );
                    },
                  ),
                  _LiveTopBar(
                    status: _trtcStatus,
                    connecting: _connectingTrtc,
                    onClose: widget.onClose,
                    onCreate: _showCreateLiveSheet,
                  ),
                  _LiveActionRail(
                    stream: activeStream,
                    onLike: () => _like(activeStream),
                    onGift: () => _showGiftSheet(activeStream),
                    onShare: () =>
                        widget.onMessage('Paylaşım ekranı bağlanacak'),
                  ),
                  _LiveBottomPanel(
                    stream: activeStream,
                    controller: _commentController,
                    onSendComment: () => _sendComment(activeStream),
                    onGift: () => _showGiftSheet(activeStream),
                  ),
                ],
              );
            },
      ),
    );
  }

  Future<void> _joinTrtcIfReady(
    LiveStreamModel stream, {
    bool force = false,
  }) async {
    if (_connectingTrtc) {
      return;
    }
    if (!force && _joinedStreamId == stream.id) {
      return;
    }
    if (_joinedStreamId == stream.id) {
      return;
    }

    setState(() {
      _connectingTrtc = true;
      _trtcStatus = 'TRTC UserSig alınıyor';
    });

    try {
      await _trtcService.leave(_activeSession);
      _activeSession = await _trtcService.joinLiveRoom(
        stream: stream,
        userId: _viewerUserId,
        onStatus: (String message) {
          if (mounted) {
            setState(() => _trtcStatus = message);
          }
        },
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _joinedStreamId = stream.id;
        _trtcStatus =
            'UserSig hazır • SDKAppID ${_activeSession!.credentials.sdkAppId}';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _trtcStatus = 'TRTC beklemede: $error');
    } finally {
      if (mounted) {
        setState(() => _connectingTrtc = false);
      }
    }
  }

  Future<void> _like(LiveStreamModel stream) async {
    try {
      await widget.repository.likeLiveStream(stream.id);
      widget.onMessage('Kalp gönderildi');
    } catch (error) {
      widget.onMessage('Beğeni gönderilemedi: $error');
    }
  }

  Future<void> _sendComment(LiveStreamModel stream) async {
    final String content = _commentController.text.trim();
    if (content.isEmpty) {
      return;
    }
    _commentController.clear();
    try {
      await widget.repository.sendStreamComment(
        streamId: stream.id,
        content: content,
      );
      widget.onMessage('Yorum gönderildi');
    } catch (error) {
      widget.onMessage('Yorum gönderilemedi: $error');
    }
  }

  void _showGiftSheet(LiveStreamModel stream) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _LiveGiftSheet(
          giftFuture: widget.giftFuture,
          onGiftSelected: (GiftTypeModel gift) async {
            Navigator.of(context).pop();
            try {
              await widget.repository.sendStreamGift(
                streamId: stream.id,
                giftTypeId: gift.id,
                quantity: 1,
              );
              widget.onMessage('${gift.name} hediyesi gönderildi');
            } catch (error) {
              widget.onMessage('Hediye gönderilemedi: $error');
            }
          },
        );
      },
    );
  }

  void _showCreateLiveSheet() {
    final TextEditingController titleController = TextEditingController(
      text: 'Yeni canlı yayın',
    );
    final TextEditingController descriptionController = TextEditingController(
      text: 'Canlı sohbet ve hediye yayını',
    );
    bool creating = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                18,
                18,
                18,
                MediaQuery.viewInsetsOf(context).bottom +
                    MediaQuery.paddingOf(context).bottom +
                    18,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF130A20),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text(
                    'Canlı yayın aç',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _DarkTextField(
                    controller: titleController,
                    label: 'Yayın başlığı',
                    icon: Icons.live_tv,
                  ),
                  const SizedBox(height: 12),
                  _DarkTextField(
                    controller: descriptionController,
                    label: 'Açıklama',
                    icon: Icons.notes,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: creating
                        ? null
                        : () async {
                            setSheetState(() => creating = true);
                            try {
                              final LiveStreamModel stream = await widget
                                  .repository
                                  .createLiveStream(
                                    title: titleController.text.trim().isEmpty
                                        ? 'Canlı yayın'
                                        : titleController.text.trim(),
                                    description: descriptionController.text
                                        .trim(),
                                  );
                              if (!mounted) {
                                return;
                              }
                              setState(() {
                                _createdStreams.insert(0, stream);
                                _currentPage = 0;
                                _joinedStreamId = null;
                              });
                              if (!context.mounted) {
                                return;
                              }
                              Navigator.of(context).pop();
                              widget.onMessage('Yayın oluşturuldu');
                            } catch (error) {
                              final LiveStreamModel
                              demoStream = LiveStreamModel(
                                id: 'local-live-${DateTime.now().millisecondsSinceEpoch}',
                                title: titleController.text.trim().isEmpty
                                    ? 'Canlı yayın'
                                    : titleController.text.trim(),
                                hostName: widget.currentUser?.name ?? 'Sen',
                                viewerCount: 1,
                                roomId:
                                    'local_${DateTime.now().millisecondsSinceEpoch}',
                                coverUrl: '',
                              );
                              if (!mounted) {
                                return;
                              }
                              setState(() {
                                _createdStreams.insert(0, demoStream);
                                _currentPage = 0;
                                _joinedStreamId = null;
                              });
                              if (!context.mounted) {
                                return;
                              }
                              Navigator.of(context).pop();
                              widget.onMessage(
                                'API yayın açma yanıtı alınamadı; yerel önizleme açıldı: $error',
                              );
                            } finally {
                              setSheetState(() => creating = false);
                            }
                          },
                    icon: creating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.videocam),
                    label: Text(creating ? 'Açılıyor...' : 'Yayını başlat'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _LiveBackdrop extends StatelessWidget {
  const _LiveBackdrop({required this.stream, required this.index});

  final LiveStreamModel stream;
  final int index;

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = <Color>[
      const Color(0xFF14001F),
      index.isEven ? const Color(0xFF7C3AED) : const Color(0xFF0EA5E9),
      index.isEven ? const Color(0xFFEC4899) : const Color(0xFF10B981),
    ];
    return IgnorePointer(
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Opacity(
              opacity: 0.72,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.25, -0.35),
                    radius: 1.05,
                    colors: colors,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 140,
            left: 24,
            child: _BlurCircle(color: colors.last, size: 160),
          ),
          Positioned(
            right: -30,
            bottom: 180,
            child: _BlurCircle(color: colors[1], size: 230),
          ),
          Center(
            child: Icon(
              Icons.live_tv,
              color: Colors.white.withValues(alpha: 0.16),
              size: 180,
            ),
          ),
          Positioned(
            top: 120,
            left: 20,
            right: 20,
            child: Text(
              stream.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.08),
                fontSize: 54,
                fontWeight: FontWeight.w900,
                height: 0.95,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SafeLiveVideoPlaceholder extends StatelessWidget {
  const _SafeLiveVideoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF090012),
            Color(0xFF2E1065),
            Color(0xFFBE185D),
          ],
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Opacity(
              opacity: 0.18,
              child: GridView.count(
                crossAxisCount: 5,
                physics: const NeverScrollableScrollPhysics(),
                children: List<Widget>.generate(
                  40,
                  (int index) =>
                      const Icon(Icons.auto_awesome, color: Colors.white),
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
                border: Border.all(color: Colors.white24),
              ),
              child: const Icon(
                Icons.videocam_rounded,
                color: Colors.white,
                size: 72,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveTopBar extends StatelessWidget {
  const _LiveTopBar({
    required this.status,
    required this.connecting,
    required this.onClose,
    required this.onCreate,
  });

  final String status;
  final bool connecting;
  final VoidCallback onClose;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 12,
      right: 12,
      top: MediaQuery.paddingOf(context).top + 8,
      child: Row(
        children: <Widget>[
          IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: 0.34),
              foregroundColor: Colors.white,
            ),
            onPressed: onClose,
            icon: const Icon(Icons.keyboard_arrow_down),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.34),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: <Widget>[
                  if (connecting)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else
                    const Icon(
                      Icons.sensors,
                      color: Colors.greenAccent,
                      size: 16,
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      status,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEC4899),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onPressed: onCreate,
            icon: const Icon(Icons.videocam, size: 18),
            label: const Text('Yayın aç'),
          ),
        ],
      ),
    );
  }
}

class _LiveActionRail extends StatelessWidget {
  const _LiveActionRail({
    required this.stream,
    required this.onLike,
    required this.onGift,
    required this.onShare,
  });

  final LiveStreamModel stream;
  final VoidCallback onLike;
  final VoidCallback onGift;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 12,
      bottom: 118,
      child: Column(
        children: <Widget>[
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white,
            child: Text(
              stream.hostName.characters.first,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 16),
          _LiveRoundAction(
            icon: Icons.favorite,
            label: _compactCount(stream.viewerCount),
            color: const Color(0xFFEF4444),
            onTap: onLike,
          ),
          const SizedBox(height: 14),
          _LiveRoundAction(
            icon: Icons.chat_bubble,
            label: 'Chat',
            color: const Color(0xFF38BDF8),
            onTap: () {},
          ),
          const SizedBox(height: 14),
          _LiveRoundAction(
            icon: Icons.card_giftcard,
            label: 'Hediye',
            color: const Color(0xFFF59E0B),
            onTap: onGift,
          ),
          const SizedBox(height: 14),
          _LiveRoundAction(
            icon: Icons.share,
            label: 'Paylaş',
            color: Colors.white,
            onTap: onShare,
          ),
        ],
      ),
    );
  }
}

class _LiveRoundAction extends StatelessWidget {
  const _LiveRoundAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Column(
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.32),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveBottomPanel extends StatelessWidget {
  const _LiveBottomPanel({
    required this.stream,
    required this.controller,
    required this.onSendComment,
    required this.onGift,
  });

  final LiveStreamModel stream;
  final TextEditingController controller;
  final VoidCallback onSendComment;
  final VoidCallback onGift;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 82,
      bottom: MediaQuery.paddingOf(context).bottom + 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'CANLI',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_compactCount(stream.viewerCount)} izleyici',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            stream.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w900,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '@${stream.hostName} • Tencent RTC canlı yayın',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.76)),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Yorum yaz...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.62),
                    ),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.34),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => onSendComment(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: onSendComment,
                icon: const Icon(Icons.send),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: onGift,
                icon: const Icon(Icons.card_giftcard),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiveGiftSheet extends StatelessWidget {
  const _LiveGiftSheet({
    required this.giftFuture,
    required this.onGiftSelected,
  });

  final Future<List<GiftTypeModel>> giftFuture;
  final ValueChanged<GiftTypeModel> onGiftSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.paddingOf(context).bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF130A20),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: FutureBuilder<List<GiftTypeModel>>(
        future: giftFuture,
        builder:
            (
              BuildContext context,
              AsyncSnapshot<List<GiftTypeModel>> snapshot,
            ) {
              final List<GiftTypeModel> gifts = snapshot.hasError
                  ? DemoData.giftTypes
                  : snapshot.data ?? DemoData.giftTypes;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Text(
                        'Canlı hediyeler',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'API: /api/gifts/types',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  GridView.builder(
                    shrinkWrap: true,
                    itemCount: gifts.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.92,
                        ),
                    itemBuilder: (BuildContext context, int index) {
                      final GiftTypeModel gift = gifts[index];
                      return InkWell(
                        onTap: () => onGiftSelected(gift),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                gift.icon.isEmpty ? '🎁' : gift.icon,
                                style: const TextStyle(fontSize: 30),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                gift.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${gift.price} jeton',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.68),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
      ),
    );
  }
}

class _FullScreenLoading extends StatelessWidget {
  const _FullScreenLoading();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black,
      child: Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}

class _EmptyLiveFullscreen extends StatelessWidget {
  const _EmptyLiveFullscreen({required this.onClose, required this.onCreate});

  final VoidCallback onClose;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.live_tv, color: Colors.white, size: 52),
              const SizedBox(height: 14),
              const Text(
                'Şu an canlı yayın yok',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.videocam),
                label: const Text('Yayın aç'),
              ),
              const SizedBox(height: 10),
              TextButton(onPressed: onClose, child: const Text('Geri dön')),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlurCircle extends StatelessWidget {
  const _BlurCircle({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.34),
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 80,
            spreadRadius: 24,
          ),
        ],
      ),
    );
  }
}

class RoomsPage extends StatelessWidget {
  const RoomsPage({
    super.key,
    required this.onAction,
    required this.roomFuture,
    required this.onOpenRoom,
  });

  final VoidCallback onAction;
  final Future<List<AudioRoomModel>> roomFuture;
  final ValueChanged<AudioRoomModel> onOpenRoom;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _RoomHeader(onAction: onAction),
        const SizedBox(height: 16),
        const _SectionTitle('Sesli sohbet odaları'),
        const SizedBox(height: 10),
        FutureBuilder<List<AudioRoomModel>>(
          future: roomFuture,
          builder:
              (
                BuildContext context,
                AsyncSnapshot<List<AudioRoomModel>> snapshot,
              ) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _LoadingCard(text: 'Sesli odalar yükleniyor...');
                }
                if (snapshot.hasError) {
                  return _ErrorCard(message: snapshot.error.toString());
                }
                final List<AudioRoomModel> rooms =
                    snapshot.data ?? DemoData.audioRooms;
                return Column(
                  children: <Widget>[
                    for (
                      int index = 0;
                      index < rooms.length;
                      index++
                    ) ...<Widget>[
                      _AudioRoomCard(
                        title: rooms[index].title,
                        subtitle:
                            '${rooms[index].speakerCount} konuşmacı • ${rooms[index].listenerCount} dinleyici',
                        color: <Color>[
                          const Color(0xFF7C3AED),
                          const Color(0xFF10B981),
                          const Color(0xFFF59E0B),
                        ][index % 3],
                        onAction: () => onOpenRoom(rooms[index]),
                      ),
                      if (index != rooms.length - 1) const SizedBox(height: 12),
                    ],
                  ],
                );
              },
        ),
      ],
    );
  }
}

class VoiceRoomPage extends StatefulWidget {
  const VoiceRoomPage({
    super.key,
    required this.repository,
    required this.room,
    required this.giftFuture,
    required this.onClose,
    required this.onMessage,
  });

  final AppRepository repository;
  final AudioRoomModel room;
  final Future<List<GiftTypeModel>> giftFuture;
  final VoidCallback onClose;
  final ValueChanged<String> onMessage;

  @override
  State<VoiceRoomPage> createState() => _VoiceRoomPageState();
}

class _VoiceRoomPageState extends State<VoiceRoomPage> {
  bool _joining = true;
  bool _micEnabled = false;
  String _status = 'Odaya bağlanıyor...';

  @override
  void initState() {
    super.initState();
    _enterRoom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080312),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: <Widget>[
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          widget.room.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          _status,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.62),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_joining)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                children: <Widget>[
                  _VoiceRoomHero(room: widget.room),
                  const SizedBox(height: 18),
                  const Text(
                    'Konuşmacılar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SpeakerGrid(room: widget.room),
                  const SizedBox(height: 20),
                  _VoiceRoomChatPreview(room: widget.room),
                  const SizedBox(height: 20),
                  _VoiceRoomGiftPreview(
                    giftFuture: widget.giftFuture,
                    onGiftSelected: _sendGift,
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _toggleMic,
                      icon: Icon(_micEnabled ? Icons.mic : Icons.mic_off),
                      label: Text(
                        _micEnabled ? 'Mikrofon açık' : 'Koltuğa otur',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filledTonal(
                    onPressed: () => _showGiftSheet(context),
                    icon: const Icon(Icons.card_giftcard),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filledTonal(
                    onPressed: () =>
                        widget.onMessage('Oda paylaşımı bağlanacak'),
                    icon: const Icon(Icons.share),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _enterRoom() async {
    try {
      await widget.repository.enterAudioRoom(widget.room.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _joining = false;
        _status = 'Odaya girildi • ${widget.room.listenerCount} dinleyici';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _joining = false;
        _status = 'Güvenli önizleme modu • API giriş hatası: $error';
      });
    }
  }

  Future<void> _toggleMic() async {
    final bool next = !_micEnabled;
    setState(() {
      _micEnabled = next;
      _status = next ? 'Mikrofon açılıyor...' : 'Dinleyici moduna geçiliyor...';
    });
    try {
      await widget.repository.enableRoomVoice(
        roomId: widget.room.id,
        enabled: next,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _status = next ? 'Koltuktasın • mikrofon açık' : 'Dinleyici modundasın';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _status = next
            ? 'Mikrofon UI açık • API yanıtı bekleniyor'
            : 'Dinleyici modundasın';
      });
      widget.onMessage('Sesli oda API yanıtı alınamadı: $error');
    }
  }

  void _showGiftSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _LiveGiftSheet(
          giftFuture: widget.giftFuture,
          onGiftSelected: (GiftTypeModel gift) {
            Navigator.of(context).pop();
            _sendGift(gift);
          },
        );
      },
    );
  }

  Future<void> _sendGift(GiftTypeModel gift) async {
    try {
      await widget.repository.sendRoomGift(
        roomId: widget.room.id,
        giftTypeId: gift.id,
        quantity: 1,
      );
      widget.onMessage('${gift.name} odaya gönderildi');
    } catch (error) {
      widget.onMessage('Odaya hediye gönderilemedi: $error');
    }
  }
}

class _VoiceRoomHero extends StatelessWidget {
  const _VoiceRoomHero({required this.room});

  final AudioRoomModel room;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _gradientDecoration(const <Color>[
        Color(0xFF7C3AED),
        Color(0xFF06B6D4),
      ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.graphic_eq, color: Colors.white, size: 44),
          const SizedBox(height: 16),
          Text(
            room.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${room.speakerCount} konuşmacı • ${room.listenerCount} dinleyici • Tencent sesli oda hazırlığı',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.82)),
          ),
        ],
      ),
    );
  }
}

class _SpeakerGrid extends StatelessWidget {
  const _SpeakerGrid({required this.room});

  final AudioRoomModel room;

  @override
  Widget build(BuildContext context) {
    final int speakerCount = room.speakerCount <= 0 ? 8 : room.speakerCount;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: speakerCount.clamp(4, 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (BuildContext context, int index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              CircleAvatar(
                backgroundColor: index == 0
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF7C3AED),
                child: Icon(
                  index == 0 ? Icons.workspace_premium : Icons.person,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                index == 0 ? 'Host' : 'Koltuk ${index + 1}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _VoiceRoomChatPreview extends StatelessWidget {
  const _VoiceRoomChatPreview({required this.room});

  final AudioRoomModel room;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Oda sohbeti',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(
            'Sistem: ${room.title} odasına hoş geldin.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
          ),
          const SizedBox(height: 6),
          Text(
            'API: /api/chat/rooms/${room.id}/messages',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.48)),
          ),
        ],
      ),
    );
  }
}

class _VoiceRoomGiftPreview extends StatelessWidget {
  const _VoiceRoomGiftPreview({
    required this.giftFuture,
    required this.onGiftSelected,
  });

  final Future<List<GiftTypeModel>> giftFuture;
  final ValueChanged<GiftTypeModel> onGiftSelected;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<GiftTypeModel>>(
      future: giftFuture,
      builder:
          (BuildContext context, AsyncSnapshot<List<GiftTypeModel>> snapshot) {
            final List<GiftTypeModel> gifts = snapshot.hasError
                ? DemoData.giftTypes
                : snapshot.data ?? DemoData.giftTypes;
            return Row(
              children: <Widget>[
                for (final GiftTypeModel gift in gifts.take(3)) ...<Widget>[
                  Expanded(
                    child: InkWell(
                      onTap: () => onGiftSelected(gift),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: <Widget>[
                            Text(
                              gift.icon.isEmpty ? '🎁' : gift.icon,
                              style: const TextStyle(fontSize: 26),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              gift.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${gift.price} jeton',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (gift != gifts.take(3).last) const SizedBox(width: 10),
                ],
              ],
            );
          },
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.onAction,
    required this.currentUser,
    required this.onLogout,
  });

  final VoidCallback onAction;
  final AppUser? currentUser;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _ProfileHeader(
          onAction: onAction,
          user: currentUser,
          onLogout: onLogout,
        ),
        const SizedBox(height: 14),
        Row(
          children: <Widget>[
            Expanded(
              child: _WalletCard(
                title: 'Jeton',
                amount: '12.850',
                icon: Icons.monetization_on,
                color: const Color(0xFFF59E0B),
                onAction: onAction,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _WalletCard(
                title: 'Gold',
                amount: 'Aktif',
                icon: Icons.workspace_premium,
                color: const Color(0xFF7C3AED),
                onAction: onAction,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _MenuCard(
          items: <_MenuItem>[
            _MenuItem(Icons.card_giftcard, 'Hediye geçmişi'),
            _MenuItem(Icons.group_add, 'Davet sistemi'),
            _MenuItem(Icons.notifications_active, 'Anlık bildirimler'),
            _MenuItem(Icons.favorite, 'FunClub üyelikleri'),
            _MenuItem(Icons.settings, 'Ayarlar'),
          ],
          onAction: onAction,
        ),
      ],
    );
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({required this.onAction});

  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _gradientDecoration(const <Color>[
        Color(0xFF6D28D9),
        Color(0xFFEC4899),
      ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const _LogoMark(size: 54),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Canlı sosyal platform',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                    Text(
                      'TikTok enerjisi, Instagram profili, Facebook akışı.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const <Widget>[
              _LightPill(Icons.videocam, 'Canlı yayın'),
              _LightPill(Icons.graphic_eq, 'Sesli oda'),
              _LightPill(Icons.card_giftcard, 'Animasyonlu hediye'),
              _LightPill(Icons.bolt, 'Anlık bildirim'),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF6D28D9),
                  ),
                  onPressed: onAction,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Keşfet'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.72),
                    ),
                  ),
                  onPressed: onAction,
                  icon: const Icon(Icons.add),
                  label: const Text('Paylaş'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StoryRail extends StatelessWidget {
  const _StoryRail();

  static const List<_Story> _stories = <_Story>[
    _Story('Sen', Icons.add, Color(0xFF7C3AED)),
    _Story('Lara', Icons.videocam, Color(0xFFEC4899)),
    _Story('Ege', Icons.sports_esports, Color(0xFF10B981)),
    _Story('Mina', Icons.star, Color(0xFFF59E0B)),
    _Story('Club', Icons.favorite, Color(0xFF06B6D4)),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _stories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (BuildContext context, int index) {
          final _Story story = _stories[index];
          return Column(
            children: <Widget>[
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: <Color>[story.color, const Color(0xFF7C3AED)],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(story.icon, color: story.color),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(story.label, style: Theme.of(context).textTheme.labelMedium),
            ],
          );
        },
      ),
    );
  }
}

class _FeedPost extends StatelessWidget {
  const _FeedPost({
    required this.avatarColor,
    required this.name,
    required this.username,
    required this.text,
    required this.likes,
    required this.comments,
    required this.onAction,
  });

  final Color avatarColor;
  final String name;
  final String username;
  final String text;
  final String likes;
  final String comments;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor: avatarColor.withValues(alpha: 0.14),
                foregroundColor: avatarColor,
                child: Text(name.characters.first),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      username,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onAction,
                icon: const Icon(Icons.more_horiz),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(text, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 14),
          Container(
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  avatarColor.withValues(alpha: 0.92),
                  const Color(0xFF111827),
                ],
              ),
            ),
            child: Stack(
              children: <Widget>[
                const Center(
                  child: Icon(
                    Icons.play_circle_fill,
                    size: 58,
                    color: Colors.white,
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: _DarkBadge(
                    icon: Icons.local_fire_department,
                    text: 'Trend',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              _ActionCounter(Icons.favorite, likes, onAction),
              _ActionCounter(Icons.mode_comment, comments, onAction),
              _ActionCounter(Icons.card_giftcard, 'Hediye', onAction),
              const Spacer(),
              IconButton(onPressed: onAction, icon: const Icon(Icons.share)),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickGrid extends StatelessWidget {
  const _QuickGrid({required this.onAction});

  final VoidCallback onAction;

  static const List<_Feature> _features = <_Feature>[
    _Feature(Icons.workspace_premium, 'Gold üyelik', 'Özel oda ve rozet'),
    _Feature(Icons.monetization_on, 'Jeton satın al', 'Hediye göndermek için'),
    _Feature(Icons.favorite, 'FunClub', 'İçerik üreticini destekle'),
    _Feature(Icons.person_add_alt_1, 'Davet et', 'Arkadaş getir, ödül kazan'),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _features.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (BuildContext context, int index) {
        final _Feature feature = _features[index];
        return _SurfaceCard(
          onTap: onAction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(feature.icon, color: Theme.of(context).colorScheme.primary),
              const Spacer(),
              Text(
                feature.title,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              Text(
                feature.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SearchPanel extends StatelessWidget {
  const _SearchPanel();

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Row(
        children: <Widget>[
          Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Yayın, oda, kişi, trend veya oyun ara',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const Icon(Icons.tune),
        ],
      ),
    );
  }
}

class _FortuneTypesGrid extends StatelessWidget {
  const _FortuneTypesGrid({required this.onAction});

  final VoidCallback onAction;

  static const List<String> _types = <String>[
    'Kahve',
    'Tarot',
    'Astroloji',
    'Rüya',
    'Numeroloji',
    'El falı',
    'Aşk',
    'Kariyer',
    'Enerji',
    'Günlük',
    'Katina',
    'Su falı',
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _types.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 9,
        mainAxisSpacing: 9,
        childAspectRatio: 1.12,
      ),
      itemBuilder: (BuildContext context, int index) {
        return _SurfaceCard(
          onTap: onAction,
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.auto_awesome,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                _types[index],
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GameCarousel extends StatelessWidget {
  const _GameCarousel({required this.onAction});

  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _GameCard(
            title: 'Çarkı çevir',
            icon: Icons.casino,
            color: const Color(0xFF7C3AED),
            onAction: onAction,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _GameCard(
            title: 'Günlük görev',
            icon: Icons.emoji_events,
            color: const Color(0xFFF59E0B),
            onAction: onAction,
          ),
        ),
      ],
    );
  }
}

class _LiveStage extends StatelessWidget {
  const _LiveStage({required this.onAction});

  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 430,
      decoration: _gradientDecoration(const <Color>[
        Color(0xFF111827),
        Color(0xFF7C3AED),
      ]),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Opacity(
              opacity: 0.25,
              child: GridView.count(
                crossAxisCount: 4,
                physics: const NeverScrollableScrollPhysics(),
                children: List<Widget>.generate(
                  24,
                  (int index) => const Icon(Icons.star, color: Colors.white24),
                ),
              ),
            ),
          ),
          Positioned(
            top: 14,
            left: 14,
            child: _DarkBadge(icon: Icons.circle, text: 'CANLI 18.2K'),
          ),
          Positioned(
            top: 14,
            right: 14,
            child: _DarkBadge(icon: Icons.monetization_on, text: 'Jeton'),
          ),
          const Center(
            child: Icon(Icons.person, color: Colors.white, size: 96),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Yayın başlığı buraya gelecek',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'API’den yayın sahibi, izleyici, sohbet ve hediye akışı çekilecek.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.78)),
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onAction,
                        icon: const Icon(Icons.card_giftcard),
                        label: const Text('Hediye gönder'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      onPressed: onAction,
                      icon: const Icon(Icons.chat_bubble),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: onAction,
                      icon: const Icon(Icons.favorite),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveListTile extends StatelessWidget {
  const _LiveListTile({
    required this.title,
    required this.host,
    required this.viewers,
    required this.color,
    required this.onAction,
  });

  final String title;
  final String host;
  final String viewers;
  final Color color;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      onTap: onAction,
      child: Row(
        children: <Widget>[
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(Icons.live_tv, color: color, size: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text('Yayıncı: $host'),
                const SizedBox(height: 8),
                _MetaPill(icon: Icons.visibility, text: viewers),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _GiftPanel extends StatelessWidget {
  const _GiftPanel({required this.onAction, required this.giftFuture});

  final VoidCallback onAction;
  final Future<List<GiftTypeModel>> giftFuture;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Sesli ve görsel hediyeler',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<GiftTypeModel>>(
            future: giftFuture,
            builder:
                (
                  BuildContext context,
                  AsyncSnapshot<List<GiftTypeModel>> snapshot,
                ) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LinearProgressIndicator();
                  }
                  final List<GiftTypeModel> gifts = snapshot.hasError
                      ? DemoData.giftTypes
                      : snapshot.data ?? DemoData.giftTypes;
                  return Row(
                    children: <Widget>[
                      for (
                        int index = 0;
                        index < gifts.take(3).length;
                        index++
                      ) ...<Widget>[
                        Expanded(
                          child: _GiftButton(
                            gift: gifts[index],
                            color: <Color>[
                              const Color(0xFFEC4899),
                              const Color(0xFF7C3AED),
                              const Color(0xFFF59E0B),
                            ][index % 3],
                            onAction: onAction,
                          ),
                        ),
                        if (index != gifts.take(3).length - 1)
                          const SizedBox(width: 8),
                      ],
                    ],
                  );
                },
          ),
        ],
      ),
    );
  }
}

class _GiftButton extends StatelessWidget {
  const _GiftButton({
    required this.gift,
    required this.color,
    required this.onAction,
  });

  final GiftTypeModel gift;
  final Color color;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onAction,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: <Widget>[
            gift.icon.isEmpty
                ? Icon(Icons.card_giftcard, color: color)
                : Text(gift.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(
              gift.name,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            Text('${gift.price} jeton'),
          ],
        ),
      ),
    );
  }
}

class _RoomHeader extends StatelessWidget {
  const _RoomHeader({required this.onAction});

  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _gradientDecoration(const <Color>[
        Color(0xFF0F766E),
        Color(0xFF06B6D4),
      ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.graphic_eq, color: Colors.white, size: 42),
          const SizedBox(height: 16),
          const Text(
            'Sesli odalarda konuş, dinle, hediye gönder.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.mic),
            label: const Text('Oda oluştur'),
          ),
        ],
      ),
    );
  }
}

class _AudioRoomCard extends StatelessWidget {
  const _AudioRoomCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      onTap: onAction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.graphic_eq, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _MetaPill(icon: Icons.card_giftcard, text: 'Hediye açık'),
            ],
          ),
          const SizedBox(height: 10),
          Text(subtitle),
          const SizedBox(height: 14),
          Row(
            children: List<Widget>.generate(
              5,
              (int index) => Padding(
                padding: EdgeInsets.only(right: index == 4 ? 0 : 8),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withValues(alpha: 0.12 + index * 0.04),
                  child: Icon(Icons.person, color: color, size: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.onAction,
    required this.user,
    required this.onLogout,
  });

  final VoidCallback onAction;
  final AppUser? user;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _gradientDecoration(const <Color>[
        Color(0xFF111827),
        Color(0xFF7C3AED),
      ]),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 44,
                backgroundColor: Colors.white,
                backgroundImage: (user?.avatarUrl.isNotEmpty ?? false)
                    ? NetworkImage(user!.avatarUrl)
                    : null,
                child: (user?.avatarUrl.isNotEmpty ?? false)
                    ? null
                    : const Icon(
                        Icons.person,
                        size: 46,
                        color: Color(0xFF7C3AED),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      user?.name ?? 'Misafir Kullanıcı',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '@${user?.username ?? 'misafir'} • ${user?.isGold == true ? 'Gold üye' : 'Standart'}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _LightPill(
                      user?.isGold == true
                          ? Icons.workspace_premium
                          : Icons.verified,
                      user?.isGold == true ? 'Gold profil' : 'Giriş yapıldı',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _ProfileStat(_compactCount(user?.followers ?? 0), 'Takipçi'),
              _ProfileStat(_compactCount(user?.following ?? 0), 'Takip'),
              _ProfileStat(_compactCount(user?.likes ?? 0), 'Beğeni'),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('Hikaye ekle'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                  ),
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Çıkış'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    required this.onAction,
  });

  final String title;
  final String amount;
  final IconData icon;
  final Color color;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      onTap: onAction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(title),
          Text(
            amount,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.items, required this.onAction});

  final List<_MenuItem> items;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          for (int index = 0; index < items.length; index++) ...<Widget>[
            ListTile(
              leading: Icon(
                items[index].icon,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(items[index].title),
              trailing: const Icon(Icons.chevron_right),
              onTap: onAction,
            ),
            if (index != items.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onAction,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      onTap: onAction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            foregroundColor: color,
            child: Icon(icon),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const Text('Jeton ve rozet ödülleri'),
        ],
      ),
    );
  }
}

class _ApiStatusBanner extends StatelessWidget {
  const _ApiStatusBanner({
    required this.isConfigured,
    required this.liveText,
    required this.demoText,
  });

  final bool isConfigured;
  final String liveText;
  final String demoText;

  @override
  Widget build(BuildContext context) {
    final Color color = isConfigured
        ? const Color(0xFF10B981)
        : Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            isConfigured ? Icons.cloud_done : Icons.integration_instructions,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isConfigured ? liveText : demoText,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Row(
        children: <Widget>[
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.6),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'API verisi alınamadı: $message',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserBadge extends StatelessWidget {
  const _UserBadge({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Chip(
        visualDensity: VisualDensity.compact,
        avatar: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          backgroundImage: (user?.avatarUrl.isNotEmpty ?? false)
              ? NetworkImage(user!.avatarUrl)
              : null,
          child: (user?.avatarUrl.isNotEmpty ?? false)
              ? null
              : Text((user?.name ?? 'M').characters.first),
        ),
        label: Text(user?.name ?? 'Misafir', overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        IconButton(
          tooltip: 'Bildirimler',
          onPressed: onTap,
          icon: const Icon(Icons.notifications_none),
        ),
        Positioned(
          right: 8,
          top: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark({required this.size, this.showGlow = false});

  final double size;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    final Widget image = ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.24),
      child: Image.asset(
        kLogoAsset,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );

    if (!showGlow) {
      return image;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.28),
            blurRadius: 34,
            spreadRadius: 4,
          ),
        ],
      ),
      child: image,
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: padding,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.46),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: child,
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
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
    );
  }
}

class _TrendChip extends StatelessWidget {
  const _TrendChip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.local_fire_department, size: 18),
      label: Text(text),
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }
}

class _LightPill extends StatelessWidget {
  const _LightPill(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
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

class _DarkBadge extends StatelessWidget {
  const _DarkBadge({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCounter extends StatelessWidget {
  const _ActionCounter(this.icon, this.text, this.onTap);

  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(text),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat(this.value, this.label);

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}

BoxDecoration _gradientDecoration(List<Color> colors) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(30),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    ),
    boxShadow: <BoxShadow>[
      BoxShadow(
        color: colors.first.withValues(alpha: 0.24),
        blurRadius: 28,
        offset: const Offset(0, 14),
      ),
    ],
  );
}

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _Story {
  const _Story(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

class _Feature {
  const _Feature(this.icon, this.title, this.subtitle);

  final IconData icon;
  final String title;
  final String subtitle;
}

class _MenuItem {
  const _MenuItem(this.icon, this.title);

  final IconData icon;
  final String title;
}

String _compactCount(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  }
  return value.toString();
}
