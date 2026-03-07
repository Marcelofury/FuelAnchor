import 'package:geolocator/geolocator.dart';
import 'package:dartz/dartz.dart';
import 'package:fuelanchor/core/error/failure.dart';

/// Geofencing service for validating transactions within allowed radius
class GeofencingService {
  static const double _maxDistanceMeters = 100.0; // 100 meters radius

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check and request location permissions
  Future<Either<Failure, bool>> checkAndRequestPermissions() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return Left(Failure.validationError(
          'Location services are disabled. Please enable them to continue.',
        ));
      }

      // Check permission status
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return Left(Failure.unauthorized(
            'Location permission denied. Please grant permission to proceed.',
          ));
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return Left(Failure.unauthorized(
          'Location permissions are permanently denied. Please enable them in app settings.',
        ));
      }

      return const Right(true);
    } catch (e) {
      return Left(Failure.unknown(
        'Failed to check location permissions: ${e.toString()}',
      ));
    }
  }

  /// Get current user position
  Future<Either<Failure, Position>> getCurrentPosition() async {
    try {
      final permissionResult = await checkAndRequestPermissions();
      
      return permissionResult.fold(
        (failure) => Left(failure),
        (_) async {
          try {
            final position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
              timeLimit: const Duration(seconds: 10),
            );
            return Right(position);
          } catch (e) {
            return Left(Failure.unknown(
              'Failed to get current location: ${e.toString()}',
            ));
          }
        },
      );
    } catch (e) {
      return Left(Failure.unknown(
        'Unexpected error getting location: ${e.toString()}',
      ));
    }
  }

  /// Calculate distance between two coordinates using Haversine formula
  /// Returns distance in meters
  double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Validate if user is within allowed radius of target location
  /// Returns Right(distance) if valid, Left(Failure) if out of range
  Future<Either<Failure, double>> validateProximity({
    required double targetLat,
    required double targetLon,
    double? maxDistanceMeters,
  }) async {
    try {
      // Get current position
      final positionResult = await getCurrentPosition();
      
      return positionResult.fold(
        (failure) => Left(failure),
        (position) {
          // Calculate distance
          final distance = calculateDistance(
            lat1: position.latitude,
            lon1: position.longitude,
            lat2: targetLat,
            lon2: targetLon,
          );

          final allowedDistance = maxDistanceMeters ?? _maxDistanceMeters;

          // Validate distance
          if (distance > allowedDistance) {
            return Left(Failure.validationError(
              'You are too far from the station. Distance: ${distance.toStringAsFixed(0)}m (max: ${allowedDistance.toStringAsFixed(0)}m)',
            ));
          }

          return Right(distance);
        },
      );
    } catch (e) {
      return Left(Failure.unknown(
        'Failed to validate proximity: ${e.toString()}',
      ));
    }
  }
  /// Returns coordinates and distance if valid
  Future<Either<Failure, Map<String, dynamic>>> validateTransactionLocation({
    required double stationLat,
    required double stationLon,
    double? maxDistanceMeters,
  }) async {
    try {
      final proximityResult = await validateProximity(
        targetLat: stationLat,
        targetLon: stationLon,
        maxDistanceMeters: maxDistanceMeters,
      );

      return proximityResult.fold(
        (failure) => Left(failure),
        (distance) async {
          final positionResult = await getCurrentPosition();
          
          return positionResult.fold(
            (failure) => Left(failure),
            (position) => Right({
              'userLatitude': position.latitude,
              'userLongitude': position.longitude,
              'stationLatitude': stationLat,
              'stationLongitude': stationLon,
              'distance': distance,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
              'accuracy': position.accuracy,
            }),
          );
        },
      );
    } catch (e) {
      return Left(Failure.unknown(
        'Transaction location validation failed: ${e.toString()}',
      ));
    }
  }

  /// Check if user is within range (boolean result)
  Future<bool> isWithinRange({
    required double targetLat,
    required double targetLon,
    double? maxDistanceMeters,
  }) async {
    final result = await validateProximity(
      targetLat: targetLat,
      targetLon: targetLon,
      maxDistanceMeters: maxDistanceMeters,
    );
    
    return result.isRight();
  }

  /// Get distance to target location
  Future<Either<Failure, double>> getDistanceToLocation({
    required double targetLat,
    required double targetLon,
  }) async {
    final positionResult = await getCurrentPosition();
    
    return positionResult.fold(
      (failure) => Left(failure),
      (position) {
        final distance = calculateDistance(
          lat1: position.latitude,
          lon1: position.longitude,
          lat2: targetLat,
          lon2: targetLon,
        );
        return Right(distance);
      },
    );
  }

  /// Format distance for display
  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
  }

  /// Check if coordinates are valid
  bool isValidCoordinates(double lat, double lon) {
    return lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180;
  }

  /// Listen to position changes (for real-time tracking)
  Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10, // Update every 10 meters
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    );
  }
}
