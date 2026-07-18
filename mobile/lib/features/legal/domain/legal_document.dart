import '../../../core/config/env.dart';

/// Profil → Yasal bölümünde listelenen belgeler.
class LegalDocument {
  const LegalDocument({
    required this.title,
    required this.slug,
    this.fallbackPath,
  });

  final String title;
  final String slug;
  final String? fallbackPath;

  String get fallbackUrl {
    final path = fallbackPath ?? slug;
    return '${Env.siteOrigin}/tr/yasal/$path';
  }
}

const kLegalDocuments = <LegalDocument>[
  LegalDocument(
    title: 'Kullanıcı Sözleşmesi',
    slug: 'kullanim-sartlari',
  ),
  LegalDocument(
    title: 'Gizlilik Politikası',
    slug: 'gizlilik-politikasi',
  ),
  LegalDocument(
    title: 'Çocuk Güvenliği Politikası',
    slug: 'cocuk-guvenligi',
    fallbackPath: 'gizlilik-politikasi',
  ),
  LegalDocument(
    title: 'KVKK',
    slug: 'kvkk',
    fallbackPath: 'gizlilik-politikasi',
  ),
  LegalDocument(
    title: 'Topluluk Kuralları',
    slug: 'topluluk-kurallari',
    fallbackPath: 'kullanim-sartlari',
  ),
];
