import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../auth/providers/providers.dart';
import '../../../wallet/providers/wallet_providers.dart';

class FleetDashboardScreen extends ConsumerStatefulWidget {
  const FleetDashboardScreen({super.key});

  @override
  ConsumerState<FleetDashboardScreen> createState() => _FleetDashboardScreenState();
}

class _FleetDashboardScreenState extends ConsumerState<FleetDashboardScreen> {
  final TextEditingController _odometerController = TextEditingController();
  final double _fuelQuota = 500.0; // Mock data - should come from smart contract

  @override
  void dispose() {
    _odometerController.dispose();
    super.dispose();
  }

  Future<void> _submitOdometer() async {
    final odometer = _odometerController.text;
    
    if (odometer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter odometer reading')),
      );
      return;
    }

    // TODO: Call smart contract to update odometer and calculate fuel quota
    
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Odometer updated successfully')),
    );
    
    _odometerController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final balanceAsync = ref.watch(walletBalanceNotifierProvider);
    final publicKeyAsync = ref.watch(userPublicKeyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fleet Driver Dashboard'),
        backgroundColor: AppColors.darkNavy,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(userRoleNotifierProvider.notifier).clearRole();
              context.go('/login');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(walletBalanceNotifierProvider.notifier).refresh();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Fuel Quota Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.electricGreen.withOpacity(0.2),
                        AppColors.darkNavy,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.electricGreen.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.local_gas_station,
                            color: AppColors.electricGreen,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            AppStrings.fuelQuota,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppColors.slate,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '$_fuelQuota L',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: AppColors.electricGreen,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _fuelQuota / 1000, // Assuming 1000L is max
                        backgroundColor: AppColors.lightNavy,
                        color: AppColors.electricGreen,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Remaining quota for this period',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.slate,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Wallet Balance Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.darkNavy,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.slate.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.walletBalance,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.slate,
                            ),
                      ),
                      const SizedBox(height: 8),
                      balanceAsync.when(
                        data: (balance) => Text(
                          balance != null ? '${balance.balance} FUEL' : '0 FUEL',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppColors.electricGreen,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        loading: () => const CircularProgressIndicator(
                          color: AppColors.electricGreen,
                        ),
                        error: (error, _) => const Text(
                          'Error loading balance',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                      const SizedBox(height: 12),
                      publicKeyAsync.when(
                        data: (publicKey) => Text(
                          publicKey ?? 'No wallet',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.slate,
                                fontFamily: 'monospace',
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        loading: () => const SizedBox(),
                        error: (_, __) => const SizedBox(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Odometer Input Section
                Text(
                  'Update Odometer',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.lightSlate,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _odometerController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    color: AppColors.lightSlate,
                    fontSize: 18,
                  ),
                  decoration: InputDecoration(
                    labelText: AppStrings.odometer,
                    hintText: AppStrings.enterOdometer,
                    labelStyle: const TextStyle(color: AppColors.slate),
                    hintStyle: TextStyle(color: AppColors.slate.withOpacity(0.5)),
                    prefixIcon: const Icon(Icons.speed, color: AppColors.electricGreen),
                    filled: true,
                    fillColor: AppColors.darkNavy,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.slate.withOpacity(0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.slate.withOpacity(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.electricGreen, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _submitOdometer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electricGreen,
                    foregroundColor: AppColors.navy,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    AppStrings.submit,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Trip History (Placeholder)
                Text(
                  'Recent Trips',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.lightSlate,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.darkNavy,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'No trips recorded yet',
                      style: TextStyle(
                        color: AppColors.slate,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
