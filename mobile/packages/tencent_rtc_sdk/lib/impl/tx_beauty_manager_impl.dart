import 'package:tencent_rtc_sdk/bindings/tx_beauty_manager_native.dart';

class TXBeautyManagerImpl {
  late final TXBeautyManagerNative _beautyManagerNative;
  static TXBeautyManagerImpl? _instance;

  TXBeautyManagerImpl._internal(dynamic beautyManagerPointer) {
    _beautyManagerNative = TXBeautyManagerNative(beautyManagerPointer);
  }

  factory TXBeautyManagerImpl(dynamic deviceManagerPointer) {
    return _instance ??= TXBeautyManagerImpl._internal(deviceManagerPointer);
  }

  static destroyBeautyManager() {
    _instance = null;
  }

  @override
  void enableSharpnessEnhancement(bool enable) {
    _beautyManagerNative.enableSharpnessEnhancement(enable);
  }

  @override
  void setBeautyLevel(int beautyLevel) {
    _beautyManagerNative.setBeautyLevel(beautyLevel);
  }

  @override
  void setBeautyStyle(int beautyStyle) {
    _beautyManagerNative.setBeautyStyle(beautyStyle);
  }

  @override
  int setFilter(String assetUrl) {
    return _beautyManagerNative.setFilter(assetUrl);
  }

  @override
  void setFilterStrength(double strength) {
    _beautyManagerNative.setFilterStrength(strength);
  }

  @override
  void setRuddyLevel(int ruddyLevel) {
    _beautyManagerNative.setRuddyLevel(ruddyLevel);
  }

  @override
  void setWhitenessLevel(int whitenessLevel) {
    _beautyManagerNative.setWhitenessLevel(whitenessLevel);
  }


}