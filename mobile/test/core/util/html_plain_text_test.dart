import 'package:canlifal_social/core/network/api_endpoints.dart';
import 'package:canlifal_social/core/util/html_plain_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('htmlToPlainText etiket ve entity temizler', () {
    expect(
      htmlToPlainText(
        '<p>Merhaba <strong>dünya</strong></p><script>alert(1)</script>&amp; fal',
      ),
      'Merhaba dünya\n& fal',
    );
    expect(htmlToPlainText('Düz metin'), 'Düz metin');
  });

  test('ünlü takip ucu kılavuz CelebrityRepository ile aynı', () {
    expect(ApiEndpoints.celebrityFollow('c1'), '/api/celebrities/c1/follow');
    expect(ApiEndpoints.celebrity('c1'), '/api/celebrities/c1');
    expect(ApiEndpoints.blogPost('kahve'), '/api/blog/kahve');
  });
}
