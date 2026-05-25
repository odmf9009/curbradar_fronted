import 'dart:async';
import 'package:geolocator/geolocator.dart';

/// Service specialized in handling GPS permissions and real-time location.
class LocationService {
  
  /// Checks and requests necessary location permissions.
  Future<bool> checkAndRequestPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Check location permission using geolocator
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return false;
    }

    return true;
  }

  /// Returns a stream of real-time location updates.
  Stream<Position> get locationStream {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best, // Máxima precisión posible
      distanceFilter: 1, // Actualizar cada metro de movimiento
    );
    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  /// Gets the current position once.
  Future<Position?> getCurrentLocation() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );
    } catch (e) {
      return null;
    }
  }
}
