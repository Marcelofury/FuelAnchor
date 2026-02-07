import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../auth/providers/providers.dart';

part 'payment_providers.g.dart';

/// Payment State Provider - Manages payment transactions
@riverpod
class PaymentNotifier extends _$PaymentNotifier {
  @override
  AsyncValue<String?> build() {
    return const AsyncValue.data(null);
  }

  Future<void> executePayment({
    required String amount,
    required String merchantId,
    required Map<String, double> gpsCoordinates,
  }) async {
    state = const AsyncValue.loading();
    
    final stellarService = ref.read(stellarServiceProvider);
    
    state = await AsyncValue.guard(() async {
      final result = await stellarService.payMerchant(
        amount: amount,
        merchantId: merchantId,
        driverGps: gpsCoordinates,
      );
      
      return result.fold(
        (failure) => throw Exception(failure.message),
        (transactionHash) => transactionHash,
      );
    });
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}
