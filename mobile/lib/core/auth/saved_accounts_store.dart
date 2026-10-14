import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../network/token_storage.dart';
import '../../features/auth/domain/entities/user_entity.dart';

const _kSavedAccounts = 'saved_accounts_v1';

/// Cihazda aynı anda tutulabilecek en fazla hesap (aktif hesap dahil).
const maxSavedAccounts = 5;

class SavedAccountEntry {
  const SavedAccountEntry({
    required this.userId,
    required this.label,
    required this.accessToken,
    this.username,
    this.refreshToken,
    this.avatarUrl,
    this.lastUsedMs,
  });

  final String userId;
  final String label;
  final String? username;
  final String accessToken;
  final String? refreshToken;
  final String? avatarUrl;
  final int? lastUsedMs;

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'label': label,
        if (username != null) 'username': username,
        'accessToken': accessToken,
        if (refreshToken != null) 'refreshToken': refreshToken,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (lastUsedMs != null) 'lastUsedMs': lastUsedMs,
      };

  factory SavedAccountEntry.fromJson(Map<String, dynamic> json) {
    return SavedAccountEntry(
      userId: json['userId']?.toString() ?? '',
      label: json['label']?.toString() ?? 'Hesap',
      username: json['username']?.toString(),
      accessToken: json['accessToken']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      lastUsedMs: json['lastUsedMs'] is num
          ? (json['lastUsedMs'] as num).toInt()
          : null,
    );
  }
}

/// Cihazdaki kayıtlı oturumlar — hesaplar arası geçiş için token'ları saklar.
/// Liste en son kullanılan önce sıralıdır.
class SavedAccountsStore {
  SavedAccountsStore(this._storage);

  final FlutterSecureStorage _storage;

  Future<List<SavedAccountEntry>> readAll() async {
    final raw = await _storage.read(key: _kSavedAccounts);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final e in list)
          if (e is Map)
            SavedAccountEntry.fromJson(Map<String, dynamic>.from(e)),
      ].where((e) => e.userId.isNotEmpty && e.accessToken.isNotEmpty).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Yeni bir hesap eklenebilir mi? Aktif hesap zaten listedeyse sayılır.
  Future<bool> canAddAnother() async =>
      (await readAll()).length < maxSavedAccounts;

  /// Aktif oturumun güncel token'larını listeye yazar (en başa taşır).
  Future<void> upsertFromSession({
    required UserEntity user,
    required TokenStorage tokens,
  }) async {
    final access = tokens.peekAccess() ?? await tokens.readAccess();
    if (access == null ||
        access.isEmpty ||
        access == TokenStorage.sessionCookieMarker) {
      return;
    }
    final refresh = tokens.peekRefresh() ?? await tokens.readRefresh();
    final label = user.display.trim().isNotEmpty
        ? user.display.trim()
        : (user.username.isNotEmpty
            ? user.username
            : (user.email ?? 'Hesap'));
    final entry = SavedAccountEntry(
      userId: user.id,
      label: label,
      username: user.username.isNotEmpty ? user.username : null,
      accessToken: access,
      refreshToken: refresh,
      avatarUrl: user.avatarUrl,
      lastUsedMs: DateTime.now().millisecondsSinceEpoch,
    );
    var all = await readAll();
    all = [
      entry,
      ...all.where((a) => a.userId != user.id),
    ];
    if (all.length > maxSavedAccounts) {
      all = all.sublist(0, maxSavedAccounts);
    }
    await _write(all);
  }

  Future<SavedAccountEntry?> byUserId(String userId) async {
    final id = userId.trim();
    if (id.isEmpty) return null;
    for (final e in await readAll()) {
      if (e.userId == id) return e;
    }
    return null;
  }

  Future<void> remove(String userId) async {
    final all = (await readAll()).toList()
      ..removeWhere((e) => e.userId == userId);
    await _write(all);
  }

  Future<void> _write(List<SavedAccountEntry> entries) async {
    final encoded = jsonEncode(entries.map((e) => e.toJson()).toList());
    await _storage.write(key: _kSavedAccounts, value: encoded);
  }
}

final savedAccountsStoreProvider = Provider<SavedAccountsStore>((ref) {
  return SavedAccountsStore(ref.watch(secureStorageProvider));
});

final savedAccountsListProvider =
    FutureProvider.autoDispose<List<SavedAccountEntry>>((ref) async {
  return ref.watch(savedAccountsStoreProvider).readAll();
});
