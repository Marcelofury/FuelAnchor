import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../auth/providers/providers.dart';

class MerchantDashboardScreen extends ConsumerStatefulWidget {
  const MerchantDashboardScreen({super.key});

  @override
  ConsumerState<MerchantDashboardScreen> createState() => _MerchantDashboardScreenState();
}

class _MerchantDashboardScreenState extends ConsumerState<MerchantDashboardScreen> {
  final int _selectedNavIndex = 0;
  bool _isRefreshing = false;

  @override
  Widget build(BuildContext context) {
    final publicKeyAsync = ref.watch(userPublicKeyProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  Icon(Icons.local_gas_station, color: Colors.blue[700], size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'FuelAnchor',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 24),
                    onPressed: () async {
                      setState(() => _isRefreshing = true);
                      await Future.delayed(const Duration(seconds: 1));
                      setState(() => _isRefreshing = false);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Pump QR Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Pump #1',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.navy,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Shell Kampala - Central District',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // QR Code
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.blue[200]!, width: 3),
                            ),
                            child: publicKeyAsync.when(
                              data: (publicKey) => QrImageView(
                                data: publicKey ?? 'STATION_ID_12345',
                                version: QrVersions.auto,
                                size: 200.0,
                                backgroundColor: Colors.white,
                              ),
                              loading: () => SizedBox(
                                width: 200,
                                height: 200,
                                child: const Center(child: CircularProgressIndicator()),
                              ),
                              error: (_, __) => SizedBox(
                                width: 200,
                                height: 200,
                                child: const Center(child: Icon(Icons.error)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'SCAN TO INITIATE FUELING',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final publicKey = publicKeyAsync.value ?? 'STATION_ID_12345';
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Station ID copied: ${publicKey.substring(0, 8)}...'),
                                    backgroundColor: AppColors.electricGreen,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.share),
                              label: const Text('Share Station ID'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[700],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Live Activity Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Live Activity',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              if (_isRefreshing)
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              if (!_isRefreshing)
                                Icon(Icons.refresh, size: 14, color: Colors.blue[700]),
                              const SizedBox(width: 6),
                              Text(
                                _isRefreshing ? 'REFRESHING...' : 'REFRESHING...',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Activity Items
                    const _ActivityTile(
                      vehicleId: 'UBA 123X',
                      time: 'Today, 10:45 AM',
                      amount: '50,000 UGX',
                      status: ActivityStatus.verified,
                      icon: Icons.directions_car,
                    ),
                    const SizedBox(height: 12),
                    const _ActivityTile(
                      vehicleId: 'UBD 456Y',
                      time: 'Today, 10:30 AM',
                      amount: '120,000 UGX',
                      status: ActivityStatus.waiting,
                      icon: Icons.local_shipping,
                    ),
                    const SizedBox(height: 12),
                    const _ActivityTile(
                      vehicleId: 'UAZ 789Q',
                      time: 'Today, 10:15 AM',
                      amount: '35,500 UGX',
                      status: ActivityStatus.completed,
                      icon: Icons.local_taxi,
                    ),
                    const SizedBox(height: 12),
                    const _ActivityTile(
                      vehicleId: 'UEB 221M',
                      time: 'Today, 10:05 AM',
                      amount: '12,000 UGX',
                      status: ActivityStatus.verified,
                      icon: Icons.motorcycle,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: (index) {
          if (index == 0) {
            // Already on activity page
            return;
          } else if (index == 1) {
            // Navigate to Scan
            context.push('/scan');
          } else if (index == 2) {
            // Navigate to Settlement
            context.push('/settlement');
          } else if (index == 3) {
            // Navigate to Profile
            context.push('/profile');
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue[700],
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_gas_station),
            label: 'ACTIVITY',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'SCAN',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: 'SETTLEMENT',
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

enum ActivityStatus {
  verified,
  waiting,
  completed,
}

class _ActivityTile extends StatelessWidget {
  final String vehicleId;
  final String time;
  final String amount;
  final ActivityStatus status;
  final IconData icon;

  const _ActivityTile({
    required this.vehicleId,
    required this.time,
    required this.amount,
    required this.status,
    required this.icon,
  });

  Color get _getBackgroundColor {
    switch (status) {
      case ActivityStatus.verified:
        return Colors.blue[50]!;
      case ActivityStatus.waiting:
        return Colors.orange[50]!;
      case ActivityStatus.completed:
        return Colors.green[50]!;
    }
  }

  Color get _getIconColor {
    switch (status) {
      case ActivityStatus.verified:
        return Colors.blue[700]!;
      case ActivityStatus.waiting:
        return Colors.orange[700]!;
      case ActivityStatus.completed:
        return Colors.green[700]!;
    }
  }

  Widget get _getStatusBadge {
    switch (status) {
      case ActivityStatus.verified:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue[700],
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'VERIFIED',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.verified, color: Colors.white, size: 14),
            ],
          ),
        );
      case ActivityStatus.waiting:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'WAITING',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 4),
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      case ActivityStatus.completed:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.electricGreen,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'COMPLETED',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.check_circle, color: AppColors.navy, size: 14),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _getIconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vehicle ID: $vehicleId',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  amount,
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _getStatusBadge,
        ],
      ),
    );
  }
}
