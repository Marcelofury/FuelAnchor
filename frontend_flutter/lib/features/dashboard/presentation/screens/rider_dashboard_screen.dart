import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../auth/providers/providers.dart';
import '../../../wallet/providers/wallet_providers.dart';
import '../../../payment/providers/payment_providers.dart';

class RiderDashboardScreen extends ConsumerStatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  ConsumerState<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends ConsumerState<RiderDashboardScreen> {
  bool _isScanning = false;

  Future<void> _startScanning() async {
    setState(() => _isScanning = true);
  }

  void _onQRCodeDetected(BarcodeCapture capture) async {
    final String? merchantId = capture.barcodes.first.rawValue;
    
    if (merchantId == null || merchantId.isEmpty) {
      return;
    }

    setState(() => _isScanning = false);

    if (!mounted) return;

    // Show payment dialog
    await _showPaymentDialog(merchantId);
  }

  Future<void> _showPaymentDialog(String merchantId) async {
    final amountController = TextEditingController();
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: const Text('Enter Amount'),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.lightSlate),
          decoration: const InputDecoration(
            labelText: 'Amount (FUEL)',
            labelStyle: TextStyle(color: AppColors.slate),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.slate),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.electricGreen),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.electricGreen,
              foregroundColor: AppColors.navy,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _executePayment(merchantId, amountController.text);
            },
            child: const Text('Pay'),
          ),
        ],
      ),
    );
  }

  Future<void> _executePayment(String merchantId, String amount) async {
    // Get current location
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to get GPS location')),
      );
      return;
    }

    if (!mounted) return;

    final gps = {
      'latitude': position.latitude,
      'longitude': position.longitude,
    };

    // Execute payment
    await ref.read(paymentNotifierProvider.notifier).executePayment(
          amount: amount,
          merchantId: merchantId,
          gpsCoordinates: gps,
        );

    if (!mounted) return;

    final paymentState = ref.read(paymentNotifierProvider);
    
    paymentState.when(
      data: (hash) {
        if (hash != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment successful! TX: ${hash.substring(0, 10)}...')),
          );
          // Refresh balance
          ref.read(walletBalanceNotifierProvider.notifier).refresh();
        }
      },
      error: (error, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $error')),
        );
      },
      loading: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final balanceAsync = ref.watch(walletBalanceNotifierProvider);
    final publicKeyAsync = ref.watch(userPublicKeyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rider Dashboard'),
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
      body: _isScanning
          ? MobileScanner(
              onDetect: _onQRCodeDetected,
            )
          : SafeArea(
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
                      // Wallet Balance Card
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
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
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
                            const SizedBox(height: 16),
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

                      // Scan to Pay Button
                      ElevatedButton.icon(
                        onPressed: _startScanning,
                        icon: const Icon(Icons.qr_code_scanner, size: 32),
                        label: const Text(
                          AppStrings.scanToPay,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.electricGreen,
                          foregroundColor: AppColors.navy,
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Recent Transactions (Placeholder)
                      Text(
                        'Recent Transactions',
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
                            'No transactions yet',
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
