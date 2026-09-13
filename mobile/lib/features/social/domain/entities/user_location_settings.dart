import '../../../../core/util/json_util.dart';

/// `GET/POST /api/user/location` — OpenAPI POST: latitude, longitude, locationEnabled, showDistance.
class UserLocationSettings {
  const UserLocationSettings({
    this.locationEnabled = false,
    this.showDistance = true,
  });

  final bool locationEnabled;
  final bool showDistance;

  factory UserLocationSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const UserLocationSettings();
    final root = json['data'] is Map ? asJsonMap(json['data']) : json;
    return UserLocationSettings(
      locationEnabled: root['locationEnabled'] == true,
      showDistance: root['showDistance'] != false,
    );
  }

  Map<String, dynamic> toPostBody({
    bool? locationEnabled,
    bool? showDistance,
    double? latitude,
    double? longitude,
  }) {
    return {
      if (locationEnabled != null) 'locationEnabled': locationEnabled,
      if (showDistance != null) 'showDistance': showDistance,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }
}
