import 'package:canlifal_social/features/admin/domain/admin_girlive_bot_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads enabled/words/whitelist nested under config (backend GET shape)', () {
    final cfg = AdminGirLiveBotConfig.fromJson({
      'config': {
        'enabled': false,
        'words': [
          {'word': 'kotu', 'severity': 'HIGH', 'prefix': false},
          {'word': '  ', 'severity': 'LOW'},
        ],
        'whitelist': ['amaç', ''],
      },
      'publicMessages': {'enabled': true},
    });
    expect(cfg.enabled, isFalse);
    expect(cfg.words, hasLength(1));
    expect(cfg.words.first['severity'], 'HIGH');
    expect(cfg.whitelist, ['amaç']);
    final json = cfg.toJson();
    expect(json['enabled'], isFalse);
    expect(json['words'], hasLength(1));
  });
}
