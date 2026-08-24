import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/core/network/api_endpoints.dart';
import 'package:canlifal_social/features/legal/domain/legal_document.dart';

void main() {
  test('çocuk güvenliği legal API ucu', () {
    final doc = legalDocumentForSlug('cocuk-guvenligi');
    expect(doc, isNotNull);
    expect(doc!.apiPath, ApiEndpoints.legalChildSafety);
    expect(doc.fallbackPath, 'cocuk-guvenligi-politikasi');
  });

  test('bilinmeyen slug null', () {
    expect(legalDocumentForSlug('yok'), isNull);
  });
}
