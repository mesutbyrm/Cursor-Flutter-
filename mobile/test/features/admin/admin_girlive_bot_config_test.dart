import 'package:canlifal_social/features/admin/domain/admin_girlive_bot_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AdminGirLiveBotConfig parses root enable aliases', () {
    final cfg = AdminGirLiveBotConfig.fromJson({
      'botEnabled': false,
      'chatRoomEnabled': false,
      'streamEnabled': true,
      'publicMessages': {
        'enabled': false,
        'jetonPromoEnabled': true,
        'minMessageIntervalSec': 45,
      },
    });
    expect(cfg.enabled, isFalse);
    expect(cfg.voiceRoomEnabled, isFalse);
    expect(cfg.liveStreamEnabled, isTrue);
    expect(cfg.publicMessages.enabled, isFalse);
    expect(cfg.publicMessages.minMessageIntervalSec, 45);
    expect(cfg.publicMessageControlsActive, isFalse);
  });

  test('AdminGirLiveBotConfig toJson round-trip keys', () {
    const cfg = AdminGirLiveBotConfig(
      enabled: true,
      voiceRoomEnabled: true,
      liveStreamEnabled: false,
      publicMessages: AdminGirLiveBotPublicMessages(
        enabled: true,
        pkMidReminderEnabled: true,
        templates: {'welcome': 'Merhaba {name}'},
      ),
    );
    final json = cfg.toJson();
    expect(json['enabled'], isTrue);
    expect(json['voiceRoomEnabled'], isTrue);
    expect(json['liveStreamEnabled'], isFalse);
    final pm = json['publicMessages'] as Map<String, dynamic>;
    expect(pm['enabled'], isTrue);
    expect(pm['pkMidReminderEnabled'], isTrue);
    expect(pm['templates'], {'welcome': 'Merhaba {name}'});

    final again = AdminGirLiveBotConfig.fromJson(
      Map<String, dynamic>.from(json),
    );
    expect(again.liveStreamEnabled, isFalse);
    expect(again.publicMessages.templates['welcome'], 'Merhaba {name}');
  });
}
