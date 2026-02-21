import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fuelanchor/core/constants/app_colors.dart';
import '../../../payment/presentation/widgets/relworx_payment_widget.dart';
import '../../../wallet/providers/wallet_providers.dart';

/// Screen for mobile money deposits using Relworx gateway
class MobileMoneyScreen extends ConsumerStatefulWidget {
  const MobileMoneyScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MobileMoneyScreen> createState() => _MobileMoneyScreenState();
}

class _MobileMoneyScreenState extends ConsumerState<MobileMoneyScreen> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _showPaymentWidget = false;
  double? _paymentAmount;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _initiatePayment() {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);
      setState(() {
        _paymentAmount = amount;
        _showPaymentWidget = true;
      });
    }
  }

  void _handlePaymentSuccess() {
    // Refresh wallet balance
    ref.read(walletBalanceNotifierProvider.notifier).refresh();
    
    setState(() {
      _showPaymentWidget = false;
      _amountController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment successful! Your wallet will be credited shortly.'),
        backgroundColor: AppColors.electricGreen,
        duration: Duration(seconds: 5),
      ),
    );

    // Navigate back after short delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.pop(context);
    });
  }

  void _handlePaymentCancel() {
    setState(() {
      _showPaymentWidget = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showPaymentWidget && _paymentAmount != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.navy,
          title: const Text('Complete Payment'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handlePaymentCancel,
          ),
        ),
        body: RelworxPaymentWidget(
          amount: _paymentAmount!,
          narration: 'Fuel Anchor Top Up',
          onSuccess: _handlePaymentSuccess,
          onCancel: _handlePaymentCancel,
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        title: const Text('Top Up Wallet'),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.navy, AppColors.navy.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet,
                      color: AppColors.electricGreen,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Mobile Money Top Up',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Instantly add FUEL tokens using MTN or Airtel money',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Amount input
              Text(
                'Enter Amount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Enter amount in UGX',
                  prefixIcon: const Icon(Icons.attach_money, color: AppColors.electricGreen, size: 28),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.electricGreen, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  if (amount < 1000) {
                    return 'Minimum amount is UGX 1,000';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Quick amount buttons
              Text(
                'Quick Select',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildQuickAmountButton(5000)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildQuickAmountButton(10000)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildQuickAmountButton(20000)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildQuickAmountButton(50000)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildQuickAmountButton(100000)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildQuickAmountButton(200000)),
                ],
              ),
              const SizedBox(height: 32),

              // Continue button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _initiatePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electricGreen,
                    foregroundColor: AppColors.navy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue to Payment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Info cards
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Supported Networks',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[900],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '• MTN Mobile Money (Uganda)\n• Airtel Money (Uganda)',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.security, color: Colors.green[700], size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Secure Payment',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[900],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your payment is processed securely through Relworx gateway. Funds are credited instantly.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.green[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAmountButton(int amount) {
    return OutlinedButton(
      onPressed: () {
        _amountController.text = amount.toString();
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(color: Colors.grey[300]!),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        '${amount ~/ 1000}K',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
        ),
      ),
    );
  }
}
