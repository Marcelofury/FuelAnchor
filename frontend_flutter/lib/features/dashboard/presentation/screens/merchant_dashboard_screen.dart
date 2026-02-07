import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/providers/providers.dart';

class MerchantDashboardScreen extends ConsumerStatefulWidget {
  const MerchantDashboardScreen({super.key});

  @override
  ConsumerState<MerchantDashboardScreen> createState() => _MerchantDashboardScreenState();
}

class _MerchantDashboardScreenState extends ConsumerState<MerchantDashboardScreen> {
  int _selectedNavIndex = 0;
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
              padding: EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  Icon(Icons.local_gas_station, color: Colors.blue[700], size: 28),
                  SizedBox(width: 12),
                  Text(
                    'FuelAnchor',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.electricGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.electricGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'BLOCKCHAIN LIVE',
                          style: TextStyle(
                            color: AppColors.electricGreen,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.refresh, size: 24),
                    onPressed: () async {
                      setState(() => _isRefreshing = true);
                      await Future.delayed(Duration(seconds: 1));
                      setState(() => _isRefreshing = false);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Pump QR Card
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Pump #1',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.navy,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Shell Kampala - Central District',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 24),
                          // QR Code
                          Container(
                            padding: EdgeInsets.all(20),
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
                              loading: () => Container(
                                width: 200,
                                height: 200,
                                child: Center(child: CircularProgressIndicator()),
                              ),
                              error: (_, __) => Container(
                                width: 200,
                                height: 200,
                                child: Center(child: Icon(Icons.error)),
                              ),
                            ),
                          ),
                          SizedBox(height: 24),
                          Text(
                            'SCAN TO INITIATE FUELING',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {},
                              icon: Icon(Icons.share),
                              label: Text('Share Station ID'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[700],
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    // Live Activity Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Live Activity',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                              SizedBox(width: 6),
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
                    SizedBox(height: 16),
                    // Activity Items
                    _ActivityTile(
                      vehicleId: 'UBA 123X',
                      time: 'Today, 10:45 AM',
                      amount: '50,000 UGX',
                      status: ActivityStatus.verified,
                      icon: Icons.directions_car,
                    ),
                    SizedBox(height: 12),
                    _ActivityTile(
                      vehicleId: 'UBD 456Y',
                      time: 'Today, 10:30 AM',
                      amount: '120,000 UGX',
                      status: ActivityStatus.waiting,
                      icon: Icons.local_shipping,
                    ),
                    SizedBox(height: 12),
                    _ActivityTile(
                      vehicleId: 'UAZ 789Q',
                      time: 'Today, 10:15 AM',
                      amount: '35,500 UGX',
                      status: ActivityStatus.completed,
                      icon: Icons.local_taxi,
                    ),
                    SizedBox(height: 12),
                    _ActivityTile(
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
        onTap: (index) => setState(() => _selectedNavIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue[700],
        unselectedItemColor: Colors.grey,
        items: [
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
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue[700],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
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
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
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
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.electricGreen,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
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
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _getIconColor, size: 28),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vehicle ID: $vehicleId',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 4),
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

                // QR Code Section
                Text(
                  'Payment QR Code',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.lightSlate,
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Customers scan this code to pay',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.slate,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // QR Code Container
                publicKeyAsync.when(
                  data: (publicKey) {
                    if (publicKey == null) {
                      return Container(
                        padding: const EdgeInsets.all(48),
                        decoration: BoxDecoration(
                          color: AppColors.darkNavy,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            'No wallet found',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ),
                      );
                    }

                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.electricGreen.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          QrImageView(
                            data: publicKey,
                            version: QrVersions.auto,
                            size: 250,
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.navy,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              publicKey,
                              style: const TextStyle(
                                color: AppColors.electricGreen,
                                fontSize: 10,
                                fontFamily: 'monospace',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => Container(
                    padding: const EdgeInsets.all(48),
                    decoration: BoxDecoration(
                      color: AppColors.darkNavy,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.electricGreen,
                      ),
                    ),
                  ),
                  error: (error, _) => Container(
                    padding: const EdgeInsets.all(48),
                    decoration: BoxDecoration(
                      color: AppColors.darkNavy,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        'Error loading QR code',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Today's Transactions (Placeholder)
                Text(
                  "Today's Transactions",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.lightSlate,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 16),
                const _TransactionTile(
                  amount: '45.50',
                  vehicle: 'Fleet Vehicle #1234',
                  time: '2 hours ago',
                ),
                const SizedBox(height: 12),
                const _TransactionTile(
                  amount: '67.20',
                  vehicle: 'Rider #5678',
                  time: '4 hours ago',
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.darkNavy,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'View All Transactions',
                      style: TextStyle(
                        color: AppColors.electricGreen,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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

class _TransactionTile extends StatelessWidget {
  final String amount;
  final String vehicle;
  final String time;

  const _TransactionTile({
    required this.amount,
    required this.vehicle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.slate.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.electricGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.trending_up,
              color: AppColors.electricGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle,
                  style: const TextStyle(
                    color: AppColors.lightSlate,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    color: AppColors.slate,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+$amount FUEL',
            style: const TextStyle(
              color: AppColors.electricGreen,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
