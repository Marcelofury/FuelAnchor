import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_entity.freezed.dart';

@freezed
class UserEntity with _$UserEntity {
  const factory UserEntity({
    required String publicKey,
    required String role,
    String? name,
    double? fuelQuota,
    double? lastOdometerReading,
  }) = _UserEntity;
}
