import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:fuelanchor/core/constants/app_colors.dart';

/// Screen for drivers/riders to redeem fuel vouchers
class VoucherRedemptionScreen extends ConsumerStatefulWidget {
  const VoucherRedemptionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<VoucherRedemptionScreen> createState() =>
      _VoucherRedemptionScreenState();
}

class _VoucherRedemptionScreenState
    extends ConsumerState<VoucherRedemptionScreen> {
  final _voucherCodeController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController();
  
  bool _isScanning = false;
  bool _isRedeeming = false;
  Map<String, dynamic>? _voucherDetails;

  @override
  void dispose() {
    _voucherCodeController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _verifyVoucher(String voucherCode) async {
    setState(() {
      _isRedeeming = true;
    });

    try {
      // Verify voucher on blockchain (simulated)
      await Future.delayed(const Duration(seconds: 2));
      
      // Mock voucher details
      setState(() {
        _voucherDetails = {
          'code': voucherCode,
          'amount': 50.0,
          'issuer': 'Fleet Operator ABC',
          'issuedAt': DateTime.now().subtract(const Duration(days: 5)),
          'expiresAt': DateTime.now().add(const Duration(days: 25)),
          'status': 'valid',
        };
        _isRedeeming = false;
      });
    } catch (e) {
      setState(() {
        _isRedeeming = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to verify voucher: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _redeemVoucher() async {
    if (_voucherDetails == null) return;

    setState(() {
      _isRedeeming = true;
    });

    try {
      // Redeem voucher on blockchain (simulated)
      await Future.delayed(const Duration(seconds: 3));
      
      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
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
              children: [
                Text(
                  '${_voucherDetails!['amount']} FUEL tokens have been added to your wallet!',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.account_balance_wallet, 
                        color: AppColors.success, 
                        size: 48
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '+${_voucherDetails!['amount']} FUEL',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // Return to previous screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }

      setState(() {
        _isRedeeming = false;
        _voucherDetails = null;
        _voucherCodeController.clear();
      });
    } catch (e) {
      setState(() {
        _isRedeeming = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Redemption failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleScanner() {
    setState(() {
      _isScanning = !_isScanning;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Redeem Voucher'),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.keyboard : Icons.qr_code_scanner),
            onPressed: _toggleScanner,
            tooltip: _isScanning ? 'Enter code manually' : 'Scan QR code',
          ),
        ],
      ),
      body: _isScanning ? _buildScanner() : _buildManualEntry(),
    );
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              if (barcode.rawValue != null) {
                _voucherCodeController.text = barcode.rawValue!;
                _verifyVoucher(barcode.rawValue!);
                _toggleScanner();
                break;
              }
            }
          },
        ),
        Positioned(
          top: 20,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Scan the voucher QR code',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.electricGreen,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManualEntry() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.electricGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.electricGreen.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.redeem, color: AppColors.electricGreen, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Redeem Fuel Voucher',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.electricGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Scan QR code or enter voucher code manually',
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

          // Voucher code input
          TextField(
            controller: _voucherCodeController,
            decoration: InputDecoration(
              labelText: 'Voucher Code',
              hintText: 'Enter or scan voucher code',
              prefixIcon: Icon(Icons.confirmation_number, 
                color: AppColors.navy
              ),
              suffixIcon: _voucherCodeController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () => _verifyVoucher(_voucherCodeController.text),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.navy, width: 2),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // Verify button
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: (_voucherCodeController.text.isEmpty || _isRedeeming)
                  ? null
                  : () => _verifyVoucher(_voucherCodeController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isRedeeming && _voucherDetails == null
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.verified),
                        SizedBox(width: 8),
                        Text(
                          'Verify Voucher',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          // Voucher details
          if (_voucherDetails != null) ...[
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Voucher Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _voucherDetails!['status'].toString().toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Amount display
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.electricGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.account_balance_wallet, 
                            color: AppColors.electricGreen, 
                            size: 48
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_voucherDetails!['amount']} FUEL',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: AppColors.electricGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Details
                  _buildDetailRow(
                    'Issued By',
                    _voucherDetails!['issuer'],
                    Icons.business,
                  ),
                  _buildDetailRow(
                    'Issued At',
                    _formatDate(_voucherDetails!['issuedAt']),
                    Icons.calendar_today,
                  ),
                  _buildDetailRow(
                    'Expires',
                    _formatDate(_voucherDetails!['expiresAt']),
                    Icons.event,
                  ),

                  const SizedBox(height: 24),

                  // Redeem button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isRedeeming ? null : _redeemVoucher,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isRedeeming
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.redeem, size: 24),
                                SizedBox(width: 8),
                                Text(
                                  'Redeem Now',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
