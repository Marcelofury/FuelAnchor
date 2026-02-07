import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../auth/providers/providers.dart';
import '../domain/entities/wallet_balance.dart';

part 'wallet_providers.g.dart';

/// Wallet Balance Provider - Fetches FUEL token balance
@riverpod
class WalletBalanceNotifier extends _$WalletBalanceNotifier {
  @override
  Future<WalletBalance?> build() async {
    return _fetchBalance();
  }

  Future<WalletBalance?> _fetchBalance() async {
    final stellarService = ref.read(stellarServiceProvider);
    final result = await stellarService.getFuelBalance();
    
    return result.fold(
      (failure) => null,
      (balance) => balance,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchBalance());
  }
}
