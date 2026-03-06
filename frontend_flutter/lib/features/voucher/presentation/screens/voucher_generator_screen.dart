import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:fuelanchor/core/constants/app_colors.dart';

/// Screen for fleet operators to generate fuel vouchers for drivers
class VoucherGeneratorScreen extends ConsumerStatefulWidget {
  const VoucherGeneratorScreen({super.key});

  @override
  ConsumerState<VoucherGeneratorScreen> createState() =>
      _VoucherGeneratorScreenState();
}

class _VoucherGeneratorScreenState
    extends ConsumerState<VoucherGeneratorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _driverIdController = TextEditingController();
  final _notesController = TextEditingController();
  
  String? _generatedVoucherCode;
  bool _isGenerating = false;
  DateTime? _expiryDate;

  @override
  void dispose() {
    _amountController.dispose();
    _driverIdController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _generateVoucher() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      // Generate voucher code (in real implementation, call blockchain service)
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      final voucherCode = 'FV-${DateTime.now().millisecondsSinceEpoch}';
      
      setState(() {
        _generatedVoucherCode = voucherCode;
        _expiryDate = DateTime.now().add(const Duration(days: 30));
        _isGenerating = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Voucher generated successfully!'),
            ],
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate voucher: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _resetForm() {
    setState(() {
      _generatedVoucherCode = null;
      _expiryDate = null;
    });
    _amountController.clear();
    _driverIdController.clear();
    _notesController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Fuel Voucher'),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.navy.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.navy.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.confirmation_number, 
                      color: AppColors.navy, 
                      size: 32
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Create Fuel Voucher',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Generate a redeemable fuel voucher for your driver',
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

              // Amount input
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Voucher Amount (FUEL)',
                  hintText: 'Enter amount in FUEL tokens',
                  prefixIcon: const Icon(Icons.account_balance_wallet, 
                    color: AppColors.navy
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.navy, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Driver ID input
              TextFormField(
                controller: _driverIdController,
                decoration: InputDecoration(
                  labelText: 'Driver ID / Public Key',
                  hintText: 'Enter driver\'s Stellar address',
                  prefixIcon: const Icon(Icons.person, color: AppColors.navy),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.navy, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter driver ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Notes input
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  label: const Text('Notes (Optional)'),
                  hintText: 'Add notes about this voucher',
                  prefixIcon: const Icon(Icons.note, color: AppColors.navy),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.navy, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Generate button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isGenerating ? null : _generateVoucher,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isGenerating
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline),
                            SizedBox(width: 8),
                            Text(
                              'Generate Voucher',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              // Generated voucher display
              if (_generatedVoucherCode != null) ...[
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.success, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Success header
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, 
                            color: AppColors.success, 
                            size: 32
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Voucher Generated!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // QR Code
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: QrImageView(
                          data: _generatedVoucherCode!,
                          version: QrVersions.auto,
                          size: 200,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Voucher code
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SelectableText(
                          _generatedVoucherCode!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                            color: AppColors.navy,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Details
                      _buildDetailRow('Amount', '${_amountController.text} FUEL'),
                      _buildDetailRow('Driver', _driverIdController.text),
                      if (_expiryDate != null)
                        _buildDetailRow(
                          'Expires', 
                          _expiryDate!.toString().split(' ')[0]
                        ),

                      const SizedBox(height: 20),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _resetForm,
                              icon: const Icon(Icons.refresh),
                              label: const Text('New Voucher'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.all(12),
                                side: const BorderSide(color: AppColors.navy),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Share voucher
                              },
                              icon: const Icon(Icons.share),
                              label: const Text('Share'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.navy,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
