import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/core/design_system/cds_states.dart';
import 'package:canlifal_social/core/network/api_exception.dart';

/// `CdsError.view` kullanıcıya `error.toString()` gösteriyordu; bu ham
/// "ApiException(402): ..." / "DioException [...]" metinlerinin ekrana
/// sızması demekti. `ApiException.userMessage` tam da bunu engellemek için
/// var ("ham DioException veya toString göstermez").
void main() {
  Future<void> pumpError(WidgetTester tester, Object error) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => CdsError.view(context: context, error: error),
          ),
        ),
      ),
    );
  }

  testWidgets('ApiException ham toString yerine kullanıcı mesajını gösterir',
      (tester) async {
    await pumpError(
      tester,
      const ApiException('Yetersiz jeton', statusCode: 402),
    );

    expect(find.text('Yetersiz jeton'), findsOneWidget);
    expect(
      find.textContaining('ApiException'),
      findsNothing,
      reason: 'ham exception tipi kullanıcıya gösterilmemeli',
    );
    expect(find.textContaining('402'), findsNothing);
  });

  testWidgets('tanınmayan hata için okunabilir metin üretir', (tester) async {
    await pumpError(tester, Exception('DioException [connection error]'));

    expect(
      find.textContaining('DioException'),
      findsNothing,
      reason: 'ham Dio metni kullanıcıya gösterilmemeli',
    );
    expect(
      find.textContaining('İnternet bağlantınızı'),
      findsOneWidget,
      reason: 'userMessage bu durumu bağlantı hatasına çeviriyor',
    );
  });

  testWidgets('onRetry verilince tekrar dene butonu görünür ve çalışır',
      (tester) async {
    var retried = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => CdsError.view(
              context: context,
              error: const ApiException('Sunucu hatası'),
              onRetry: () => retried++,
            ),
          ),
        ),
      ),
    );

    final retry = find.text('Tekrar dene');
    expect(retry, findsOneWidget);
    await tester.tap(retry);
    expect(retried, 1);
  });
}
