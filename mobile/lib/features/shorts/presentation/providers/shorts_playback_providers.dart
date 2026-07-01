import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/shorts_safe_settings_store.dart';

/// Feed oynatma hızı (0.5 / 1 / 1.5 / 2).
final shortPlaybackSpeedProvider = StateProvider<double>((ref) => 1.0);

class ShortsSafeSettings {
  const ShortsSafeSettings({
    required this.restrictedMode,
    required this.hideMature,
  });

  final bool restrictedMode;
  final bool hideMature;
}

class ShortsSafeSettingsNotifier extends AsyncNotifier<ShortsSafeSettings> {
  @override
  Future<ShortsSafeSettings> build() async {
    final store = ShortsSafeSettingsStore.instance;
    return ShortsSafeSettings(
      restrictedMode: await store.isRestrictedMode(),
      hideMature: await store.hideMatureContent(),
    );
  }

  Future<void> setRestrictedMode(bool value) async {
    await ShortsSafeSettingsStore.instance.setRestrictedMode(value);
    state = AsyncValue.data(
      ShortsSafeSettings(
        restrictedMode: value,
        hideMature: state.valueOrNull?.hideMature ?? true,
      ),
    );
  }

  Future<void> setHideMature(bool value) async {
    await ShortsSafeSettingsStore.instance.setHideMatureContent(value);
    state = AsyncValue.data(
      ShortsSafeSettings(
        restrictedMode: state.valueOrNull?.restrictedMode ?? false,
        hideMature: value,
      ),
    );
  }
}

final shortsSafeSettingsProvider =
    AsyncNotifierProvider<ShortsSafeSettingsNotifier, ShortsSafeSettings>(
  ShortsSafeSettingsNotifier.new,
);

const shortPlaybackSpeedOptions = <double>[0.5, 1.0, 1.5, 2.0];
