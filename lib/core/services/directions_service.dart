import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';

class DirectionsResult {
  final List<LatLng> points;
  final String distance;
  final String duration;
  final double distanceValue; // in meters

  DirectionsResult({
    required this.points,
    required this.distance,
    required this.duration,
    required this.distanceValue,
  });
}

class DirectionsService {
  static const String _apiKey = "AIzaSyCUVtYc5DVhtStudSzSpTKj5_P6WOwZsUU";
  final PolylinePoints _polylinePoints = PolylinePoints(apiKey: _apiKey);

  Future<DirectionsResult?> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      PolylineResult result = await _polylinePoints.getRouteBetweenCoordinates(
        request: PolylineRequest(
          origin: PointLatLng(origin.latitude, origin.longitude),
          destination: PointLatLng(destination.latitude, destination.longitude),
          mode: TravelMode.driving,
        ),
      );

      if (result.errorMessage != null && result.errorMessage!.isNotEmpty) {
        print('Directions API Error: ${result.errorMessage}');
        return null;
      }

      if (result.points.isNotEmpty) {
        List<LatLng> points = result.points
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList();

        double totalDistance = 0;
        for (int i = 0; i < points.length - 1; i++) {
          totalDistance += Geolocator.distanceBetween(
            points[i].latitude,
            points[i].longitude,
            points[i + 1].latitude,
            points[i + 1].longitude,
          );
        }

        // Simple estimation if Directions API doesn't provide it directly in this plugin version
        // Avg speed 25 km/h (urban) = 416 meters/minute
        int minutes = (totalDistance / 416).ceil();
        if (minutes < 1) minutes = 1;
        
        double miles = totalDistance / 1609.34;

        return DirectionsResult(
          points: points,
          distance: '${miles.toStringAsFixed(1)} mi',
          duration: '$minutes min',
          distanceValue: totalDistance,
        );
      }
    } catch (e) {
      print('Directions Service Exception: $e');
    }
    return null;
  }
}
