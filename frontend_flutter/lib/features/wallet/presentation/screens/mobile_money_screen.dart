import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fuelanchor/core/constants/app_colors.dart';
import 'package:fuelanchor/features/wallet/presentation/screens/sep24_webview_screen.dart';

/// Screen for initiating mobile money deposits and withdrawals via SEP-24
class MobileMoneyScreen extends ConsumerStatefulWidget {
  const MobileMoneyScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MobileMoneyScreen> createState() => _MobileMoneyScreenState();
}

class _MobileMoneyScreenState extends ConsumerState<MobileMoneyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  
  String _selectedProvider = 'mpesa';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _initiateDeposit() async {
    if (!_validateInputs()) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Call backend to initiate SEP-24 deposit
      final amount = double.parse(_amountController.text);
      final phone = _phoneController.text;

      // In real implementation, call your backend API
      // final response = await _apiService.initiateSep24Deposit(
      //   amount: amount,
      //   provider: _selectedProvider,
      //   phoneNumber: phone,
      // );

      // Mock SEP-24 URL (replace with actual backend response)
      final sep24Url = 'https://anchor.example.com/sep24/deposit?'
          'amount=$amount&'
          'provider=$_selectedProvider&'
          'phone=$phone&'
          'callback_url=fuelanchor://callback';

      // Navigate to WebView
      if (mounted) {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => Sep24WebViewScreen(
              url: sep24Url,
              title: 'Mobile Money Deposit',
              onSuccess: (data) {
                _handleTransactionSuccess('deposit', data);
              },
              onError: (error) {
                _handleTransactionError(error);
              },
              onCancel: () {
                _handleTransactionCancel();
              },
            ),
          ),
        );

        if (result == true) {
          // Transaction successful
          _resetForm();
        }
      }
    } catch (e) {
      _showErrorDialog('Failed to initiate deposit: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _initiateWithdrawal() async {
    if (!_validateInputs()) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final amount = double.parse(_amountController.text);
      final phone = _phoneController.text;

      // Mock SEP-24 URL for withdrawal
      final sep24Url = 'https://anchor.example.com/sep24/withdraw?'
          'amount=$amount&'
          'provider=$_selectedProvider&'
          'phone=$phone&'
          'callback_url=fuelanchor://callback';

      if (mounted) {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => Sep24WebViewScreen(
              url: sep24Url,
              title: 'Mobile Money Withdrawal',
              onSuccess: (data) {
                _handleTransactionSuccess('withdrawal', data);
              },
              onError: (error) {
                _handleTransactionError(error);
              },
              onCancel: () {
                _handleTransactionCancel();
              },
            ),
          ),
        );

        if (result == true) {
          _resetForm();
        }
      }
    } catch (e) {
      _showErrorDialog('Failed to initiate withdrawal: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  bool _validateInputs() {
    if (_amountController.text.isEmpty) {
      _showErrorDialog('Please enter an amount');
      return false;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showErrorDialog('Please enter a valid amount');
      return false;
    }

    if (_phoneController.text.isEmpty) {
      _showErrorDialog('Please enter your phone number');
      return false;
    }

    return true;
  }

  void _handleTransactionSuccess(String type, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 32),
            const SizedBox(width: 12),
            const Text('Success!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              type == 'deposit'
                  ? 'Your deposit has been processed successfully!'
                  : 'Your withdrawal has been processed successfully!',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            if (data['transactionId'] != null) ...[
              Text('Transaction ID:', style: TextStyle(color: Colors.grey[600])),
              Text(
                data['transactionId'],
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleTransactionError(String error) {
    _showErrorDialog(error);
  }

  void _handleTransactionCancel() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transaction cancelled'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    _amountController.clear();
    _phoneController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mobile Money'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: Colors.white,
          tabs: const [
            Tab(text: 'Deposit', icon: Icon(Icons.add_circle_outline)),
            Tab(text: 'Withdraw', icon: Icon(Icons.remove_circle_outline)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDepositTab(),
          _buildWithdrawalTab(),
        ],
      ),
    );
  }

  Widget _buildDepositTab() {
    return _buildTransactionForm(
      title: 'Deposit Funds',
      description: 'Add FUEL tokens to your wallet using mobile money',
      icon: Icons.account_balance_wallet,
      buttonText: 'Deposit Now',
      buttonColor: AppColors.success,
      onSubmit: _initiateDeposit,
    );
  }

  Widget _buildWithdrawalTab() {
    return _buildTransactionForm(
      title: 'Withdraw Funds',
      description: 'Convert FUEL tokens to mobile money on your phone',
      icon: Icons.monetization_on,
      buttonText: 'Withdraw Now',
      buttonColor: Colors.orange,
      onSubmit: _initiateWithdrawal,
    );
  }

  Widget _buildTransactionForm({
    required String title,
    required String description,
    required IconData icon,
    required String buttonText,
    required Color buttonColor,
    required VoidCallback onSubmit,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: buttonColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: buttonColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(icon, color: buttonColor, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: buttonColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Provider selection
          Text(
            'Select Provider',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: [
              _buildProviderChip('M-Pesa', 'mpesa', Colors.green),
              _buildProviderChip('MTN MoMo', 'mtn', Colors.yellow[700]!),
              _buildProviderChip('Airtel Money', 'airtel', Colors.red),
            ],
          ),
          const SizedBox(height: 24),

          // Amount input
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Amount (FUEL)',
              hintText: 'Enter amount',
              prefixIcon: Icon(Icons.attach_money, color: buttonColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: buttonColor, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Phone number input
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              hintText: '+254 XXX XXX XXX',
              prefixIcon: Icon(Icons.phone, color: buttonColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: buttonColor, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      buttonText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // Info text
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You will be redirected to complete the payment securely',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderChip(String label, String value, Color color) {
    final isSelected = _selectedProvider == value;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedProvider = value;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      side: BorderSide(
        color: isSelected ? color : Colors.grey[300]!,
        width: isSelected ? 2 : 1,
      ),
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}
