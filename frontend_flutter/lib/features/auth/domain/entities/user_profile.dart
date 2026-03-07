import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/enums/user_role.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String publicKey,
    required UserRole role,
    required String name,
    required String phone,
    String? vehicleId,
    String? fleetName,
    String? stationId,
    String? stationName,
    String? nationalId,
    double? fuelQuota,
    double? lastOdometerReading,
    @Default(false) bool isSynced,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}
