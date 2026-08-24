import 'package:geolocator/geolocator.dart';

import '../../../shorts/presentation/utils/reverse_geocode_helper.dart';

/// GPS konum seçimi sonucu.
class SocialPostLocationResult {
  const SocialPostLocationResult({this.label, this.errorMessage});

  final String? label;
  final String? errorMessage;

  bool get ok => label != null && label!.trim().isNotEmpty;
}

String formatSocialPostLocationSnippet(String label) => '📍 $label';

/// Sosyal paylaşım için mevcut GPS konumunu okunabilir etikete çevirir.
Future<SocialPostLocationResult> pickSocialPostLocationLabel() async {
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const SocialPostLocationResult(
        errorMessage: 'Konum servisi kapalı',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return const SocialPostLocationResult(errorMessage: 'Konum izni gerekli');
    }

    final position = await Geolocator.getCurrentPosition();
    final label = await reverseGeocodeLabel(position.latitude, position.longitude);
    return SocialPostLocationResult(label: label);
  } catch (e) {
    return SocialPostLocationResult(errorMessage: 'Konum alınamadı: $e');
  }
}
