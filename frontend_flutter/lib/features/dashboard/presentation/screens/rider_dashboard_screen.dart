import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/responsive.dart';
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
  final int _selectedNavIndex = 0;

  void _onQRCodeDetected(BarcodeCapture capture) async {
    final String? merchantId = capture.barcodes.first.rawValue;
    
    if (merchantId == null || merchantId.isEmpty) {
      return;
    }

    setState(() => _isScanning = false);

    if (!mounted) return;
    await _showPaymentDialog(merchantId);
  }

  Future<void> _showPaymentDialog(String merchantId) async {
    final amountController = TextEditingController();
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: const Text('Enter Amount', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.lightSlate),
          decoration: const InputDecoration(
            labelText: 'Amount (UGX)',
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
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
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
            const SnackBar(content: Text('Payment successful!')),
          );
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

    if (_isScanning) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.navy,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => _isScanning = false),
          ),
          title: const Text('Scan QR Code'),
        ),
        body: MobileScanner(onDetect: _onQRCodeDetected),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.navy,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.electricGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.anchor, color: AppColors.navy, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FUEL ANCHOR',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        'ENERGY BLOCKCHAIN',
                        style: TextStyle(
                          color: AppColors.electricGreen,
                          fontSize: 10,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                    onPressed: () {},
                  ),
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.slate,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await ref.read(walletBalanceNotifierProvider.notifier).refresh();
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Greeting
                      Text(
                        'GOOD MORNING, MUSA',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Credit Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.navy,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.electricGreen, width: 3),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'AVAILABLE CREDIT',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.electricGreen.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.electricGreen),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.verified, size: 14, color: AppColors.electricGreen),
                                      SizedBox(width: 4),
                                      Text(
                                        'BLOCKCHAIN SECURED',
                                        style: TextStyle(
                                          color: AppColors.electricGreen,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            balanceAsync.when(
                              data: (balance) => Text(
                                'UGX ${balance?.balance ?? '0'}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              loading: () => const CircularProgressIndicator(color: AppColors.electricGreen),
                              error: (_, __) => const Text(
                                'UGX 0',
                                style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Progress Bar
                            Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: 0.75,
                                    minHeight: 8,
                                    backgroundColor: Colors.grey[800],
                                    valueColor: const AlwaysStoppedAnimation(AppColors.electricGreen),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '75% FUEL CAP',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {},
                                    icon: const Icon(Icons.add_circle, size: 20),
                                    label: const Text(
                                      'Top Up Balance',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.electricGreen,
                                      foregroundColor: AppColors.navy,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[800],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.visibility_outlined, color: Colors.white),
                                    onPressed: () {},
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Stats Row
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.local_gas_station, color: Colors.grey[600], size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'FUEL USAGE',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 11,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        '12.7L',
                                        style: TextStyle(
                                          color: AppColors.navy,
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Text(
                                          '/ week',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.stars, color: Colors.grey[600], size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'REWARDS',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 11,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '840',
                                        style: TextStyle(
                                          color: AppColors.navy,
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Padding(
                                        padding: EdgeInsets.only(bottom: 4),
                                        child: Text(
                                          '+12 pts',
                                          style: TextStyle(
                                            color: AppColors.electricGreen,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Recent Fuelings
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Fuelings',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.navy,
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              'VIEW HISTORY',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const _FuelingTile(
                        stationName: 'Shell Kasubi',
                        date: 'Oct 12',
                        time: '10:30 AM',
                        liters: '4.5L',
                        amount: '-22,500 UGX',
                      ),
                      const SizedBox(height: 12),
                      const _FuelingTile(
                        stationName: 'TotalEnergies Mengo',
                        date: 'Oct 10',
                        time: '04:15 PM',
                        liters: '3.2L',
                        amount: '-16,000 UGX',
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: SizedBox(
        width: MediaQuery.of(context).size.width - 120,
        child: FloatingActionButton.extended(
          onPressed: () => setState(() => _isScanning = true),
          backgroundColor: AppColors.electricGreen,
          foregroundColor: AppColors.navy,
          icon: const Icon(Icons.qr_code_scanner, size: 28),
          label: const Text(
            'SCAN TO PUMP',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: (index) {
          if (index == 0) {
            // Already on home
            return;
          } else if (index == 1) {
            // Navigate to History
            context.push('/history');
          } else if (index == 2) {
            // Navigate to Nearby Stations
            context.push('/nearby-stations');
          } else if (index == 3) {
            // Navigate to Profile
            context.push('/profile');
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.navy,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'HOME',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'HISTORY',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.near_me),
            label: 'NEARBY',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'PROFILE',
          ),
        ],
      ),
    );
  }
}

class _FuelingTile extends StatelessWidget {
  final String stationName;
  final String date;
  final String time;
  final String liters;
  final String amount;

  const _FuelingTile({
    required this.stationName,
    required this.date,
    required this.time,
    required this.liters,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_gas_station, color: AppColors.navy),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stationName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$date • $time',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                liters,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                amount,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
