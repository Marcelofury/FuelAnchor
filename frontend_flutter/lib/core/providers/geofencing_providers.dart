import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fuelanchor/core/services/geofencing_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dartz/dartz.dart';
import 'package:fuelanchor/core/error/failure.dart';

part 'geofencing_providers.g.dart';

/// Provider for GeofencingService singleton
@riverpod
GeofencingService geofencingService(GeofencingServiceRef ref) {
  return GeofencingService();
}

/// Provider to get current position
@riverpod
Future<Position> currentPosition(CurrentPositionRef ref) async {
  final service = ref.watch(geofencingServiceProvider);
  final result = await service.getCurrentPosition();
  
  return result.fold(
    (failure) => throw Exception(failure.message),
    (position) => position,
  );
}

/// Provider to check if location services are enabled
@riverpod
Future<bool> locationServiceEnabled(LocationServiceEnabledRef ref) async {
  final service = ref.watch(geofencingServiceProvider);
  return await service.isLocationServiceEnabled();
}

/// Provider to validate proximity to a station
@riverpod
class ProximityValidator extends _$ProximityValidator {
  @override
  Future<Either<Failure, double>> build({
    required double stationLat,
    required double stationLon,
    double? maxDistance,
  }) async {
    final service = ref.watch(geofencingServiceProvider);
    return await service.validateProximity(
      targetLat: stationLat,
      targetLon: stationLon,
      maxDistanceMeters: maxDistance,
    );
  }

  /// Revalidate proximity
  Future<void> revalidate() async {
    state = const AsyncValue.loading();
    final service = ref.read(geofencingServiceProvider);
    
    state = await AsyncValue.guard(() async {
      return await service.validateProximity(
        targetLat: stationLat,
        targetLon: stationLon,
        maxDistanceMeters: maxDistance,
      );
    });
  }
}

/// Provider to validate transaction location
@riverpod
class TransactionLocationValidator extends _$TransactionLocationValidator {
  @override
  Future<Either<Failure, Map<String, dynamic>>> build({
    required double stationLat,
    required double stationLon,
    double? maxDistance,
  }) async {
    final service = ref.watch(geofencingServiceProvider);
    return await service.validateTransactionLocation(
      stationLat: stationLat,
      stationLon: stationLon,
      maxDistanceMeters: maxDistance,
    );
  }

  /// Validate again
  Future<Either<Failure, Map<String, dynamic>>> validate() async {
    state = const AsyncValue.loading();
    final service = ref.read(geofencingServiceProvider);
    
    final result = await service.validateTransactionLocation(
      stationLat: stationLat,
      stationLon: stationLon,
      maxDistanceMeters: maxDistance,
    );

    state = AsyncValue.data(result);
    return result;
  }
}

/// Stream provider for real-time position updates
@riverpod
Stream<Position> positionStream(PositionStreamRef ref) {
  final service = ref.watch(geofencingServiceProvider);
  return service.getPositionStream();
}

/// Provider to get distance to a specific location
@riverpod
Future<double> distanceToLocation(
  DistanceToLocationRef ref, {
  required double targetLat,
  required double targetLon,
}) async {
  final service = ref.watch(geofencingServiceProvider);
  final result = await service.getDistanceToLocation(
    targetLat: targetLat,
    targetLon: targetLon,
  );
  
  return result.fold(
    (failure) => throw Exception(failure.message),
    (distance) => distance,
  );
}
