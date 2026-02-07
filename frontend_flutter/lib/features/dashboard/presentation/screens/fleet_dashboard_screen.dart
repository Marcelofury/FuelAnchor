import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/providers/providers.dart';
import 'dart:math' as math;

class FleetDashboardScreen extends ConsumerStatefulWidget {
  const FleetDashboardScreen({super.key});

  @override
  ConsumerState<FleetDashboardScreen> createState() => _FleetDashboardScreenState();
}

class _FleetDashboardScreenState extends ConsumerState<FleetDashboardScreen> {
  final TextEditingController _odometerController = TextEditingController(text: '124850');
  String _selectedFuelType = 'Diesel';
  int _selectedNavIndex = 0;
  
  final double _fuelLimit = 50.0;
  final double _fuelUsed = 30.0;
  final double _fuelRemaining = 20.0;
  
  @override
  void dispose() {
    _odometerController.dispose();
    super.dispose();
  }

  Future<void> _generateVoucher() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Voucher generated successfully!'),
        backgroundColor: AppColors.electricGreen,
      ),
    );
  }

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
                      color: Colors.blue[700],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.water_drop, color: Colors.white, size: 28),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FUELANCHOR',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'FLEET MANAGEMENT',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'John Doe',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'ID: 882190',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 12),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey[300],
                    child: Icon(Icons.person, color: Colors.grey[700], size: 28),
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
                    // Vehicle Info Card
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 120,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Icon(
                                    Icons.directions_car,
                                    size: 60,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[700],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'ACTIVE',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'VEHICLE INFO',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 11,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'UBA 123X',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.navy,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.route, size: 14, color: Colors.blue[700]),
                                    SizedBox(width: 4),
                                    Text(
                                      'Kampala — Jinja',
                                      style: TextStyle(
                                        color: Colors.blue[700],
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Row(
                                  children: [
                                    Text(
                                      'STATUS: ',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      'ON TRIP',
                                      style: TextStyle(
                                        color: AppColors.navy,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: AppColors.electricGreen,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'SYNCED TO CHAIN',
                                      style: TextStyle(
                                        color: AppColors.electricGreen,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    // Fuel Allowance Card
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'DAILY FUEL ALLOWANCE',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 24),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 200,
                                height: 200,
                                child: CustomPaint(
                                  painter: _CircularProgressPainter(
                                    value: _fuelRemaining / _fuelLimit,
                                    backgroundColor: AppColors.navy,
                                    valueColor: AppColors.electricGreen,
                                  ),
                                ),
                              ),
                              Column(
                                children: [
                                  Text(
                                    '${_fuelRemaining.toInt()}L',
                                    style: TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.navy,
                                    ),
                                  ),
                                  Text(
                                    'REMAINING',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    'LIMIT',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '${_fuelLimit.toInt()}.0 L',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.navy,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  Text(
                                    'USED TODAY',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '${_fuelUsed.toInt()}.0 L',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    // Prepare for Fueling Card
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue[100]!, width: 2, style: BorderStyle.solid),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.blue[700],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.qr_code_scanner, color: Colors.white, size: 24),
                              ),
                              SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Prepare for Fueling',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.navy,
                                    ),
                                  ),
                                  Text(
                                    'Enter details to generate voucher',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ODOMETER (KM)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    TextField(
                                      controller: _odometerController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.grey[300]!),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.grey[300]!),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      ),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'FUEL TYPE',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey[300]!),
                                      ),
                                      padding: EdgeInsets.symmetric(horizontal: 12),
                                      child: DropdownButton<String>(
                                        value: _selectedFuelType,
                                        isExpanded: true,
                                        underline: SizedBox(),
                                        items: ['Diesel', 'Petrol', 'Super'].map((fuel) {
                                          return DropdownMenuItem(
                                            value: fuel,
                                            child: Text(
                                              fuel,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedFuelType = value!;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _generateVoucher,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.electricGreen,
                                foregroundColor: AppColors.navy,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'GENERATE VOUCHER',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    // Nearest Station Map
                    Container(
                      height: 220,
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
                                child: Icon(Icons.map, size: 60, color: Colors.grey[500]),
                              ),
                            ),
                            // Live Tracking Badge
                            Positioned(
                              top: 16,
                              right: 16,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: AppColors.electricGreen,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
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
                            // Station Info
                            Positioned(
                              bottom: 16,
                              left: 16,
                              right: 16,
                              child: Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.navy,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.navigation, color: AppColors.electricGreen, size: 14),
                                              SizedBox(width: 4),
                                              Text(
                                                'NEAREST AUTHORIZED STATION',
                                                style: TextStyle(
                                                  color: AppColors.electricGreen,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Shell Mukono',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            '1.2 km away • 4 mins drive',
                                            style: TextStyle(
                                              color: Colors.grey[400],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.navigation, color: Colors.blue[700], size: 24),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
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
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.support_agent),
            label: 'Support',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double value;
  final Color backgroundColor;
  final Color valueColor;

  _CircularProgressPainter({
    required this.value,
    required this.backgroundColor,
    required this.valueColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 24.0;

    // Background arc
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -math.pi / 2,
      math.pi * 2,
      false,
      backgroundPaint,
    );

    // Value arc
    final valuePaint = Paint()
      ..color = valueColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -math.pi / 2,
      math.pi * 2 * value,
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.valueColor != valueColor;
  }
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
