import 'package:freezed_annotation/freezed_annotation.dart';

part 'wallet_balance.freezed.dart';

@freezed
class WalletBalance with _$WalletBalance {
  const factory WalletBalance({
    required String assetCode,
    required String balance,
    required String assetIssuer,
  }) = _WalletBalance;
}
