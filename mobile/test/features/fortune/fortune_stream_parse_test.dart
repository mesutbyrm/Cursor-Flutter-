import 'package:canlifal_social/features/fortune/data/services/fortune_sse_service.dart';
import 'package:canlifal_social/features/fortune/domain/entities/user_fortune_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('OpenAI delta chunk text is read', () {
    expect(
      FortuneSseService.pieceOf({
        'choices': [
          {
            'delta': {'content': 'Merhaba'},
          },
        ],
      }),
      'Merhaba',
    );
    expect(FortuneSseService.pieceOf({'content': 'Düz'}), 'Düz');
  });

  test('full SSE body (non-stream POST) is concatenated', () {
    const body = 'data: {"choices":[{"delta":{"content":"Kartların "}}]}\n\n'
        'data: {"choices":[{"delta":{"content":"anlamı"}}]}\n\n'
        'data: [DONE]\n\n';
    expect(FortuneSseService.textFromStreamBody(body), 'Kartların anlamı');
    expect(FortuneSseService.textFromStreamBody('Kurşun dökme yorumu'),
        'Kurşun dökme yorumu');
  });

  test('history titles are Turkish for backend keys', () {
    const f = UserFortuneEntity(id: '1', type: 'coffee', slug: 'kahve-fali', detail: 'Yorum');
    expect(f.displayTitle, 'Kahve Falı');
    expect(f.displayBody, 'Yorum');
  });
}
