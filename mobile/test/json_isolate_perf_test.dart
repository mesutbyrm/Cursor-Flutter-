import 'package:canlifal_social/core/performance/json_isolate_perf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('decode small json synchronously on caller', () async {
    final value = await JsonIsolatePerf.decode('{"ok":true}');
    expect(value, {'ok': true});
    expect(JsonIsolatePerf.shouldIsolate('{"ok":true}'), isFalse);
  });

  test('decode large json via isolate threshold', () async {
    final inner = List.filled(1500, {'id': 'item', 'title': 'Canlifal test payload'});
    final raw =
        '{"items":[${inner.map((e) => '{"id":"item","title":"Canlifal test payload"}').join(',')}]}';
    expect(raw.length, greaterThan(JsonIsolatePerf.largeThreshold));
    final value = await JsonIsolatePerf.decode(raw);
    expect(value, isA<Map>());
    expect((value as Map)['items'], isA<List>());
  });

  test('decodeMap returns null for non-object', () async {
    expect(await JsonIsolatePerf.decodeMap('[1]'), isNull);
  });
}
