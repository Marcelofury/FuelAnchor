import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_entity.freezed.dart';

@freezed
class PaymentEntity with _$PaymentEntity {
  const factory PaymentEntity({
    required String driver,
    required String merchant,
    required String amount,
    required int timestamp,
    String? transactionHash,
  }) = _PaymentEntity;
}
