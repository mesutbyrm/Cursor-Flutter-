// Profil eksiklik hesabı — kullanıcıya "profilini tamamla" göstergesi ve
// kırmızı sayı için. Saf/yan etkisiz; birim testi kolaydır.

/// Eksik bir profil alanı.
class ProfileCompletionItem {
  const ProfileCompletionItem(this.key, this.label);

  final String key;
  final String label;
}

bool _empty(String? s) => s == null || s.trim().isEmpty;

/// Doldurulması gereken ama boş olan profil alanları (önem sırasına göre).
/// [displayName] boşsa ya da kullanıcı adıyla aynıysa (varsayılan) eksik sayılır.
List<ProfileCompletionItem> missingProfileItems({
  required String username,
  String? avatarUrl,
  String? displayName,
  String? bio,
  String? city,
  String? zodiac,
  String? favoriteTeam,
}) {
  final missing = <ProfileCompletionItem>[];
  if (_empty(avatarUrl)) {
    missing.add(const ProfileCompletionItem('avatar', 'Profil fotoğrafı'));
  }
  final dn = displayName?.trim() ?? '';
  if (dn.isEmpty || dn == username.trim()) {
    missing.add(const ProfileCompletionItem('displayName', 'Görünen ad'));
  }
  if (_empty(bio)) {
    missing.add(const ProfileCompletionItem('bio', 'Hakkında'));
  }
  if (_empty(city)) {
    missing.add(const ProfileCompletionItem('city', 'Şehir'));
  }
  if (_empty(zodiac)) {
    missing.add(const ProfileCompletionItem('zodiac', 'Burç'));
  }
  if (_empty(favoriteTeam)) {
    missing.add(const ProfileCompletionItem('favoriteTeam', 'Favori takım'));
  }
  return missing;
}

/// Toplam alan sayısı (yüzde hesabı için).
const int kProfileCompletionFieldCount = 6;

/// 0..100 arası tamamlanma yüzdesi.
int profileCompletionPercent(int missingCount) {
  final filled = (kProfileCompletionFieldCount - missingCount)
      .clamp(0, kProfileCompletionFieldCount);
  return ((filled / kProfileCompletionFieldCount) * 100).round();
}
