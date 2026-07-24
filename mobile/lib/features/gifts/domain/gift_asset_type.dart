import '../../../core/util/enum_from.dart';

/// Backend `GiftType.assetType` — hediye sistemi dokümanı §5.1.
enum GiftAssetType {
  image,
  video,
  lottie,
  svga,
  gif,
  unknown;

  static GiftAssetType parse(String? raw) =>
      enumFrom(GiftAssetType.values, raw, GiftAssetType.unknown);
}
