import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _nativeRoutes = {
  '/dreams/contest',
  '/astrology/compatibility',
  '/football',
  '/ajans/weekly-tasks',
  '/co-broadcast-invites',
  '/settings/voice-audio',
};

const _nativeAliases = {
  '/ruya-yarismasi': '/dreams/contest',
  '/burc-uyumu': '/astrology/compatibility',
  '/futbol': '/football',
};

final _blogDetail = RegExp(r'^/blog/([^/?#]+)/?$');
final _dreamSymbolDetail = RegExp(r'^/ruya-sozlugu/([^/?#]+)/?$');
final _tiktok = RegExp(r'^/tiktok(/[^/?#]+)?/?$');

/// İçerik detay yolu (blog yazısı, burç blogu, rüya sembolü, TikTok) —
/// native sayfa varsa yolu, yoksa `null` döner.
String? nativeContentDetailPath(String path) {
  final p = path.trim();
  if (p == '/blog/burclar' || p.startsWith('/blog/burclar?')) return p;
  final blog = _blogDetail.firstMatch(p);
  if (blog != null && blog.group(1) != 'kategori') return p;
  if (_dreamSymbolDetail.hasMatch(p)) return p;
  if (_tiktok.hasMatch(p)) return p;
  return null;
}

/// Site yolu → native Flutter route (WebView yok).
void openNativeSitePath(BuildContext context, String path) {
  final p = path.trim();
  if (p.isEmpty) return;

  final detail = nativeContentDetailPath(p);
  if (detail != null) {
    context.push(detail);
    return;
  }

  final alias = _nativeAliases[p];
  if (alias != null) {
    context.push(alias);
    return;
  }
  if (_nativeRoutes.contains(p) || p.startsWith('/dreams/contest/')) {
    context.push(p);
    return;
  }

  if (p.startsWith('/auth/reset-password') || p.startsWith('/sifre-sifirla')) {
    final uri = Uri.tryParse(p.startsWith('http') ? p : 'https://canlifal.com$p');
    final token = uri?.queryParameters['token'];
    context.push(
      token != null && token.isNotEmpty
          ? '/auth/reset-password?token=${Uri.encodeComponent(token)}'
          : '/auth/reset-password',
    );
    return;
  }
  if (p.startsWith('/auth/forgot-password')) {
    context.push('/auth/forgot-password');
    return;
  }
  if (p == '/populer-falcilar') {
    context.push('/canli-falcilar');
    return;
  }
  if (p == '/falci-ol' || p == '/falci-panel') {
    context.push(p == '/falci-panel' ? '/falci-panel' : '/falci-ol');
    return;
  }
  if (p == '/yayinci-ol' || p == '/yayinci-panel') {
    context.push('/falci-ol');
    return;
  }
  if (p == '/bana-ozel' || p.startsWith('/bana-ozel/')) {
    context.push('/fortune/bana-ozel');
    return;
  }
  if (p.startsWith('/fortune') || p.contains('fal')) {
    context.push(p.startsWith('/') ? p : '/$p');
    return;
  }
  if (p == '/shorts' || p.startsWith('/shorts/')) {
    context.push(p.startsWith('/') ? p : '/$p');
    return;
  }
  if (p == '/live' || p.startsWith('/live')) {
    context.go('/live');
    return;
  }
  if (p.contains('sohbet') || p.contains('voice')) {
    context.push('/voice-rooms');
    return;
  }
  if (p.startsWith('/canli-falcilar')) {
    context.push(p.startsWith('/') ? p : '/$p');
    return;
  }
  if (p == '/ajans-ol') {
    context.push('/ajans-ol');
    return;
  }
  if (p == '/fan-club-hub' ||
      p == '/fan-club' ||
      p.contains('fan-club') ||
      p.contains('fanclub')) {
    context.push('/fan-club-hub');
    return;
  }
  if (p == '/celebrities-hub' ||
      p.startsWith('/unluler') ||
      p.startsWith('/celebrities')) {
    context.push('/celebrities-hub');
    return;
  }
  if (p.startsWith('/football')) {
    context.push('/football');
    return;
  }
  if (p == '/oyunlar' || p == '/games') {
    context.push('/games-hub');
    return;
  }
  if (p.startsWith('/games-hub')) {
    context.push(p.startsWith('/') ? p : '/$p');
    return;
  }
  if (p == '/blog-hub' || p.startsWith('/blog')) {
    context.push('/blog-hub');
    return;
  }
  if (p.startsWith('/ruya-sozlugu') ||
      p.startsWith('/ruya-trendleri') ||
      p.startsWith('/ruya-takvimi') ||
      p.startsWith('/ruya-istatistikleri') ||
      p.startsWith('/ruya-yarismasi') ||
      p == '/dreams-hub' ||
      p.startsWith('/dreams')) {
    context.push('/dreams-hub');
    return;
  }
  if (p.startsWith('/ruya') || p.contains('ruya-yorumu')) {
    context.push('/fortune/ruya-tabiri');
    return;
  }
  if (p == '/jeton-store' || p.contains('jeton')) {
    context.push('/jeton-store');
    return;
  }
  if (p == '/ad-rewards' || p.contains('reklam')) {
    context.push('/ad-rewards');
    return;
  }
  if (p == '/profile/growth' ||
      p.contains('gorev') ||
      p.contains('görev') ||
      p.contains('reward') ||
      p.contains('watch-ad') ||
      p.contains('odul') ||
      p.contains('ödül')) {
    context.push('/profile/growth');
    return;
  }
  if (p == '/profile' || p.contains('profil')) {
    context.go('/profile');
    return;
  }
  if (p == '/admin/panel' || p.startsWith('/admin/panel/')) {
    context.push('/admin/panel');
    return;
  }
  if (p == '/admin' || p.startsWith('/admin/')) {
    context.push('/admin');
    return;
  }
  if (p == '/ajans' || p.startsWith('/ajans')) {
    context.push('/ajans/dashboard');
    return;
  }
  context.push('/content-hub');
}
