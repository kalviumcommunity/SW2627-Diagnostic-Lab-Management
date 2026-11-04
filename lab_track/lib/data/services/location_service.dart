import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

/// Service managing device GPS coordinates for phlebotomists and transit couriers.
class LocationService {
  /// Fetches current geographic coordinates with graceful permissions handling.
  static Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[LocationService] Location service disabled, using fallback coords.');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      debugPrint('[LocationService] Failed to query device location: $e');
      return null;
    }
  }

  /// Default Gurugram / Delhi NCR coordinates for offline/simulated transit.
  static const double defaultLatitude = 28.4595;
  static const double defaultLongitude = 77.0266;
}
