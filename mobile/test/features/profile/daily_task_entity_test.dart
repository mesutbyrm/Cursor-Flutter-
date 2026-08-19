import 'package:canlifal_social/features/profile/domain/entities/daily_task_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DailyTaskEntity.fromJson — /api/daily-missions', () {
    test('maps type, reward and earnedJeton from production shape', () {
      const json = {
        'type': 'login',
        'title': 'Günlük Giriş',
        'description': 'Uygulamaya giriş yap',
        'reward': 5,
        'icon': '👋',
        'autoComplete': true,
        'completed': true,
        'earnedJeton': 5,
      };

      final task = DailyTaskEntity.fromJson(json);

      expect(task.id, 'login');
      expect(task.title, 'Günlük Giriş');
      expect(task.rewardJeton, 5);
      expect(task.completed, isTrue);
      expect(task.icon, '👋');
    });

    test('open_fortune mission uses type as id', () {
      const json = {
        'type': 'open_fortune',
        'title': 'Fal Baktır',
        'reward': 10,
        'completed': false,
        'earnedJeton': 10,
      };

      final task = DailyTaskEntity.fromJson(json);

      expect(task.id, 'open_fortune');
      expect(task.rewardJeton, 10);
      expect(task.completed, isFalse);
    });
  });
}
