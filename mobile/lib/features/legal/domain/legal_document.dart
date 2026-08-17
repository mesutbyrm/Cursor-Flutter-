import '../../../core/config/env.dart';
import '../../../core/network/api_endpoints.dart';

/// Profil → Yasal bölümünde listelenen belgeler.
class LegalDocument {
  const LegalDocument({
    required this.title,
    required this.slug,
    this.apiPath,
    this.fallbackPath,
  });

  final String title;
  final String slug;
  /// Site-pages dışındaki üretim uçları (ör. çocuk güvenliği).
  final String? apiPath;
  final String? fallbackPath;

  String get fallbackUrl {
    final path = fallbackPath ?? slug;
    return '${Env.siteOrigin}/tr/yasal/$path';
  }
}

LegalDocument? legalDocumentForSlug(String slug) {
  final key = slug.trim();
  if (key.isEmpty) return null;
  for (final doc in kLegalDocuments) {
    if (doc.slug == key) return doc;
  }
  return null;
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
    apiPath: ApiEndpoints.legalChildSafety,
    fallbackPath: 'cocuk-guvenligi-politikasi',
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
