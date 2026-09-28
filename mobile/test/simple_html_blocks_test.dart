import 'package:canlifal_social/core/util/simple_html_blocks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('başlık, paragraf ve liste öğelerini ayırır', () {
    const html = '```html\n<h2>Aşk Uyumu: 85/100</h2>'
        '<p>Koç ve <strong>Aslan</strong> &amp; ateş.</p>'
        '<ul><li>Tutku</li><li>Enerji</li></ul>\n```';
    expect(parseSimpleHtml(html), const [
      HtmlBlock(HtmlBlockKind.heading, 'Aşk Uyumu: 85/100'),
      HtmlBlock(HtmlBlockKind.paragraph, 'Koç ve Aslan & ateş.'),
      HtmlBlock(HtmlBlockKind.bullet, 'Tutku'),
      HtmlBlock(HtmlBlockKind.bullet, 'Enerji'),
    ]);
  });

  test('etiketsiz metni satır satır paragraf yapar', () {
    expect(parseSimpleHtml('Birinci satır<br>İkinci'), const [
      HtmlBlock(HtmlBlockKind.paragraph, 'Birinci satır'),
      HtmlBlock(HtmlBlockKind.paragraph, 'İkinci'),
    ]);
  });

  test('iç içe div içindeki blokları açar', () {
    expect(
      parseSimpleHtml('<div><h3>İş</h3><p>İyi</p></div>'),
      const [
        HtmlBlock(HtmlBlockKind.heading, 'İş'),
        HtmlBlock(HtmlBlockKind.paragraph, 'İyi'),
      ],
    );
  });

  test('boş girdi boş liste döner', () {
    expect(parseSimpleHtml('   '), isEmpty);
  });
}
