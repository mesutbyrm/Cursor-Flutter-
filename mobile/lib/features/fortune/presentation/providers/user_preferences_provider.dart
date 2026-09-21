import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserPreferences {
  final String userId;
  final String theme;
  final String accentColor;
  final String fontSize;
  final bool animationsEnabled;
  final bool soundEnabled;
  final bool hapticEnabled;
  final String language;
  final String timeFormat;
  final String dateFormat;

  UserPreferences({
    required this.userId,
    this.theme = 'system',
    this.accentColor = 'cyan',
    this.fontSize = 'medium',
    this.animationsEnabled = true,
    this.soundEnabled = true,
    this.hapticEnabled = true,
    this.language = 'tr',
    this.timeFormat = '24h',
    this.dateFormat = 'dd.MM.yyyy',
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      userId: json['userId'] ?? '',
      theme: json['theme'] ?? 'system',
      accentColor: json['accentColor'] ?? 'cyan',
      fontSize: json['fontSize'] ?? 'medium',
      animationsEnabled: json['animationsEnabled'] ?? true,
      soundEnabled: json['soundEnabled'] ?? true,
      hapticEnabled: json['hapticEnabled'] ?? true,
      language: json['language'] ?? 'tr',
      timeFormat: json['timeFormat'] ?? '24h',
      dateFormat: json['dateFormat'] ?? 'dd.MM.yyyy',
    );
  }
}

class AnimationConfig {
  final String userId;
  final int pageTransitionDuration;
  final int cardFlipDuration;
  final bool scrollAnimationEnabled;
  final bool parallaxEnabled;
  final bool lightEffectsEnabled;

  AnimationConfig({
    required this.userId,
    this.pageTransitionDuration = 300,
    this.cardFlipDuration = 500,
    this.scrollAnimationEnabled = true,
    this.parallaxEnabled = true,
    this.lightEffectsEnabled = true,
  });

  factory AnimationConfig.fromJson(Map<String, dynamic> json) {
    return AnimationConfig(
      userId: json['userId'] ?? '',
      pageTransitionDuration: json['pageTransitionDuration'] ?? 300,
      cardFlipDuration: json['cardFlipDuration'] ?? 500,
      scrollAnimationEnabled: json['scrollAnimationEnabled'] ?? true,
      parallaxEnabled: json['parallaxEnabled'] ?? true,
      lightEffectsEnabled: json['lightEffectsEnabled'] ?? true,
    );
  }
}

class UserPreferencesService {
  Future<UserPreferences> getPreferences(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return UserPreferences(userId: userId);
  }

  Future<void> updatePreferences(String userId, {
    String? theme,
    String? accentColor,
    String? fontSize,
    bool? animationsEnabled,
    bool? soundEnabled,
    bool? hapticEnabled,
    String? language,
    String? timeFormat,
    String? dateFormat,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<AnimationConfig> getAnimationConfig(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return AnimationConfig(userId: userId);
  }

  Future<void> updateAnimationConfig(String userId, {
    int? pageTransitionDuration,
    int? cardFlipDuration,
    bool? scrollAnimationEnabled,
    bool? parallaxEnabled,
    bool? lightEffectsEnabled,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}

final userPreferencesServiceProvider = Provider((ref) => UserPreferencesService());

final userPreferencesProvider = FutureProvider.family<UserPreferences, String>((ref, userId) async {
  final service = ref.watch(userPreferencesServiceProvider);
  return service.getPreferences(userId);
});

final animationConfigProvider = FutureProvider.family<AnimationConfig, String>((ref, userId) async {
  final service = ref.watch(userPreferencesServiceProvider);
  return service.getAnimationConfig(userId);
});

class UpdatePreferencesNotifier extends StateNotifier<AsyncValue<void>> {
  UpdatePreferencesNotifier(this.ref) : super(const AsyncValue.data(null));
  final Ref ref;

  Future<void> update(String userId, {
    String? theme,
    String? accentColor,
    String? fontSize,
    bool? animationsEnabled,
    bool? soundEnabled,
    bool? hapticEnabled,
    String? language,
    String? timeFormat,
    String? dateFormat,
  }) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(userPreferencesServiceProvider);
      await service.updatePreferences(
        userId,
        theme: theme,
        accentColor: accentColor,
        fontSize: fontSize,
        animationsEnabled: animationsEnabled,
        soundEnabled: soundEnabled,
        hapticEnabled: hapticEnabled,
        language: language,
        timeFormat: timeFormat,
        dateFormat: dateFormat,
      );
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final updatePreferencesNotifierProvider = StateNotifierProvider<UpdatePreferencesNotifier, AsyncValue<void>>((ref) {
  return UpdatePreferencesNotifier(ref);
});
