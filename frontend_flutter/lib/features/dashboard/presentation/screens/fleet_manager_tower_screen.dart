import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';

class FleetManagerTowerScreen extends ConsumerStatefulWidget {
  const FleetManagerTowerScreen({super.key});

  @override
  ConsumerState<FleetManagerTowerScreen> createState() => _FleetManagerTowerScreenState();
}

class _FleetManagerTowerScreenState extends ConsumerState<FleetManagerTowerScreen> {
  int _selectedNavIndex = 0;

  @override
  Widget build(BuildContext context) {
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
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.anchor, color: AppColors.electricGreen, size: 28),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Control Tower',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      Text(
                        'FUELANCHOR',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  Stack(
                    children: [
                      IconButton(
                        icon: Icon(Icons.notifications_outlined, size: 28),
                        onPressed: () {},
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.electricGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.grey[300],
                    child: Icon(Icons.person, color: Colors.grey[700], size: 26),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Row
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.navy,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'FUEL SAVED',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.verified, color: AppColors.electricGreen, size: 16),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Text(
                                  '1,240L',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.trending_up, color: AppColors.electricGreen, size: 16),
                                    SizedBox(width: 4),
                                    Text(
                                      '+12% this week',
                                      style: TextStyle(
                                        color: AppColors.electricGreen,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ACTIVE TRUCKS',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Row(
                                  children: [
                                    Text(
                                      '42',
                                      style: TextStyle(
                                        color: AppColors.navy,
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Column(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[300],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Container(
                                          width: 32,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[400],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 6),
                                Text(
                                  '95% fleet utilization',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    // Map View
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            // Placeholder map
                            Container(
                              color: Colors.grey[300],
                              child: Center(
                                child: Icon(Icons.map, size: 80, color: Colors.grey[500]),
                              ),
                            ),
                            // Live Tracking Badge
                            Positioned(
                              top: 16,
                              left: 16,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.location_pin, color: Colors.red, size: 16),
                                    SizedBox(width: 6),
                                    Text(
                                      'LIVE TRACKING',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.navy,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Vehicle marker example
                            Positioned(
                              top: 120,
                              left: 140,
                              child: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.electricGreen,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.electricGreen.withOpacity(0.4),
                                      blurRadius: 12,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Icon(Icons.local_shipping, color: AppColors.navy, size: 20),
                              ),
                            ),
                            // Vehicle label
                            Positioned(
                              top: 100,
                              left: 100,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'KCA 123X',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.navy,
                                  ),
                                ),
                              ),
                            ),
                            // Map Controls
                            Positioned(
                              bottom: 16,
                              right: 16,
                              child: Column(
                                children: [
                                  FloatingActionButton(
                                    mini: true,
                                    backgroundColor: AppColors.electricGreen,
                                    onPressed: () {},
                                    child: Icon(Icons.add, color: AppColors.navy),
                                  ),
                                  SizedBox(height: 8),
                                  FloatingActionButton(
                                    mini: true,
                                    backgroundColor: Colors.white,
                                    onPressed: () {},
                                    child: Icon(Icons.remove, color: AppColors.navy),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    // Fleet Status Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Fleet Status',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Row(
                            children: [
                              Text(
                                'View All',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Icon(Icons.chevron_right, color: Colors.grey[700]),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    // Vehicle Status Cards
                    _VehicleStatusCard(
                      plateNumber: 'KCA 123X - Scania G410',
                      fuelLevel: 0.65,
                      fuelPercent: '65%',
                      isLow: false,
                    ),
                    SizedBox(height: 12),
                    _VehicleStatusCard(
                      plateNumber: 'KDA 456Y - Mercedes Actros',
                      fuelLevel: 0.22,
                      fuelPercent: '22%',
                      isLow: true,
                    ),
                    SizedBox(height: 12),
                    _VehicleStatusCard(
                      plateNumber: 'KCB 789Z - Scania P360',
                      fuelLevel: 0.88,
                      fuelPercent: '88%',
                      isLow: false,
                    ),
                    SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.electricGreen,
        child: Icon(Icons.add, color: AppColors.navy, size: 32),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: (index) => setState(() => _selectedNavIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.electricGreen,
        unselectedItemColor: Colors.grey[600],
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Tower',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.policy),
            label: 'Policies',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
        ],
      ),
    );
  }
}

class _VehicleStatusCard extends StatelessWidget {
  final String plateNumber;
  final double fuelLevel;
  final String fuelPercent;
  final bool isLow;

  const _VehicleStatusCard({
    required this.plateNumber,
    required this.fuelLevel,
    required this.fuelPercent,
    required this.isLow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.local_shipping, color: AppColors.navy, size: 28),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plateNumber,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fuel Level',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(height: 4),
                          Stack(
                            children: [
                              Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: fuelLevel,
                                child: Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: isLow ? Colors.red : AppColors.electricGreen,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      fuelPercent,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isLow ? Colors.red : AppColors.navy,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.electricGreen,
              foregroundColor: AppColors.navy,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Top Up',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
