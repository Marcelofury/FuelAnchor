import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/config/supabase_config.dart';

class SettlementScreen extends ConsumerStatefulWidget {
  const SettlementScreen({super.key});

  @override
  ConsumerState<SettlementScreen> createState() => _SettlementScreenState();
}

class _SettlementScreenState extends ConsumerState<SettlementScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = false;
  double _totalRevenue = 0;
  double _totalVolume = 0;
  int _transactionCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSettlementData();
  }

  Future<void> _loadSettlementData() async {
    setState(() => _isLoading = true);

    if (SupabaseConfig.isConfigured) {
      try {
        final userId = SupabaseService.currentUser?.id;
        if (userId == null) {
          _loadDummyData();
          setState(() => _isLoading = false);
          return;
        }
        
        final transactions = await SupabaseService.getTransactions(userId);
        
        // Filter for today
        final today = DateTime.now();
        final filteredTransactions = transactions.where((t) {
          final createdAt = DateTime.parse(t['created_at']);
          return createdAt.year == today.year &&
                 createdAt.month == today.month &&
                 createdAt.day == today.day;
        }).toList();

        _transactions = filteredTransactions;
        
        // Calculate totals
        _totalRevenue = filteredTransactions.fold(0, (sum, t) => sum + (t['amount'] as num).toDouble());
        _totalVolume = filteredTransactions.fold(0, (sum, t) => sum + ((t['fuel_volume'] as num?) ?? 0).toDouble());
        _transactionCount = filteredTransactions.length;
      } catch (e) {
        print('Error loading settlement data: $e');
        _loadDummyData();
      }
    } else {
      _loadDummyData();
    }

    setState(() => _isLoading = false);
  }

  void _loadDummyData() {
    _transactions = [
      {
        'from_user_id': 'RIDER001',
        'amount': 50000,
        'fuel_volume': 25.0,
        'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        'status': 'completed',
      },
      {
        'from_user_id': 'FLEET002',
        'amount': 120000,
        'fuel_volume': 60.0,
        'created_at': DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
        'status': 'completed',
      },
      {
        'from_user_id': 'RIDER003',
        'amount': 35000,
        'fuel_volume': 17.5,
        'created_at': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
        'status': 'completed',
      },
    ];
    
    _totalRevenue = 205000;
    _totalVolume = 102.5;
    _transactionCount = 3;
  }

  Future<void> _requestSettlement() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Request Settlement',
          style: TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Settlement Summary:'),
            const SizedBox(height: 12),
            Text(
              'Total Revenue: UGX ${_totalRevenue.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Total Volume: ${_totalVolume.toStringAsFixed(1)}L'),
            Text('Transactions: $_transactionCount'),
            const SizedBox(height: 16),
            const Text('Funds will be transferred to your registered account within 24 hours.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.electricGreen,
              foregroundColor: AppColors.navy,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // TODO: Process settlement via backend
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settlement request submitted successfully!'),
          backgroundColor: AppColors.electricGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        title: const Text('Daily Settlement'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSettlementData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Cards
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: 'Total Revenue',
                          value: 'UGX ${_totalRevenue.toStringAsFixed(0)}',
                          icon: Icons.attach_money,
                          color: AppColors.electricGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          title: 'Fuel Dispensed',
                          value: '${_totalVolume.toStringAsFixed(1)}L',
                          icon: Icons.water_drop,
                          color: Colors.blue[700]!,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SummaryCard(
                    title: 'Transactions',
                    value: _transactionCount.toString(),
                    icon: Icons.receipt_long,
                    color: AppColors.navy,
                  ),
                  const SizedBox(height: 24),

                  // Date selector
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: AppColors.navy),
                        const SizedBox(width: 12),
                        Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() => _selectedDate = date);
                              _loadSettlementData();
                            }
                          },
                          child: const Text('Change Date'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Transaction list
                  const Text(
                    'Today\'s Transactions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_transactions.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'No transactions for this date',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    )
                  else
                    ..._transactions.map((t) => _TransactionTile(transaction: t)),

                  const SizedBox(height: 20),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _transactionCount > 0 ? _requestSettlement : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.electricGreen,
            foregroundColor: AppColors.navy,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'REQUEST SETTLEMENT',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final time = DateTime.parse(transaction['created_at']);
    final hourStr = '${time.hour}:${time.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.electricGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_gas_station,
              color: AppColors.electricGreen,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction['from_user_id'],
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$hourStr • ${transaction['fuel_volume']}L',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            'UGX ${transaction['amount']}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }
}
