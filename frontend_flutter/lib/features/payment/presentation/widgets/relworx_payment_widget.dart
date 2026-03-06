/// Relworx Mobile Money Payment Widget
/// Handles MTN and Airtel Uganda mobile money payments through Relworx gateway
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../core/config/api_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/utils/logger.dart';

class RelworxPaymentWidget extends ConsumerStatefulWidget {
  final double amount;
  final String narration;
  final VoidCallback? onSuccess;
  final VoidCallback? onCancel;

  const RelworxPaymentWidget({
    super.key,
    required this.amount,
    required this.narration,
    this.onSuccess,
    this.onCancel,
  });

  @override
  ConsumerState<RelworxPaymentWidget> createState() => _RelworxPaymentWidgetState();
}

class _RelworxPaymentWidgetState extends ConsumerState<RelworxPaymentWidget> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isProcessing = false;
  String? _selectedProvider;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  /// Detect provider from phone number
  String? _detectProvider(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    
    if (cleanPhone.startsWith('256')) {
      final local = cleanPhone.substring(3);
      if (local.startsWith('77') || local.startsWith('78')) return 'MTN Uganda';
      if (local.startsWith('75') || local.startsWith('70')) return 'Airtel Uganda';
    } else if (cleanPhone.startsWith('07')) {
      if (cleanPhone.startsWith('077') || cleanPhone.startsWith('078')) return 'MTN Uganda';
      if (cleanPhone.startsWith('075') || cleanPhone.startsWith('070')) return 'Airtel Uganda';
    }
    
    return null;
  }

  /// Validate phone number with Relworx
  Future<bool> _validatePhone(String phone) async {
    try {
      final supabase = SupabaseService.client;
      final session = supabase.auth.currentSession;
      
      if (session == null) {
        throw Exception('No authenticated session');
      }

      final response = await http.post(
        Uri.parse(ApiConfig.relworxValidatePhone),
        headers: ApiConfig.headers(authToken: session.accessToken),
        body: jsonEncode({'phone': phone}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['valid'] == true;
      }
      
      return false;
    } catch (e) {
      AppLogger.error('Phone validation error', e);
      return false;
    }
  }

  /// Process payment collection
  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final phone = _phoneController.text.trim();
      
      // Validate phone first
      final isValid = await _validatePhone(phone);
      if (!isValid) {
        setState(() {
          _errorMessage = 'Invalid phone number or not registered with mobile money';
          _isProcessing = false;
        });
        return;
      }

      // Get auth token
      final supabase = SupabaseService.client;
      final session = supabase.auth.currentSession;
      
      if (session == null) {
        throw Exception('No authenticated session');
      }

      // Request payment collection
      final response = await http.post(
        Uri.parse(ApiConfig.relworxCollect),
        headers: ApiConfig.headers(authToken: session.accessToken),
        body: jsonEncode({
          'phone': phone,
          'amount': widget.amount.toInt(),
          'currency': 'UGX',
          'narration': widget.narration,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        final transactionRef = data['data']['transactionRef'];
        
        if (mounted) {
          // Show success dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => _PaymentPendingDialog(
              phone: phone,
              amount: widget.amount,
              transactionRef: transactionRef,
              onSuccess: widget.onSuccess,
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Payment failed. Please try again.';
        });
      }
    } catch (e) {
      AppLogger.error('Payment processing error', e);
      setState(() {
        _errorMessage = 'Network error. Please check your connection and try again.';
      });
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.electricGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.phone_android, color: AppColors.electricGreen),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mobile Money Payment',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'MTN & Airtel Uganda',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onCancel,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Amount display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.navy.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.navy.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Amount to Pay:',
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    'UGX ${widget.amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.electricGreen,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Phone number input
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Mobile Money Number',
                hintText: '0771234567 or +256771234567',
                prefixIcon: const Icon(Icons.phone),
                suffixIcon: _selectedProvider != null
                    ? Chip(
                        label: Text(
                          _selectedProvider!,
                          style: const TextStyle(fontSize: 10),
                        ),
                        backgroundColor: _selectedProvider == 'MTN Uganda'
                            ? Colors.yellow[700]
                            : Colors.red[600],
                        labelStyle: const TextStyle(color: Colors.white),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                final provider = _detectProvider(value);
                if (provider == null) {
                  return 'Please enter a valid MTN or Airtel number';
                }
                return null;
              },
              onChanged: (value) {
                final provider = _detectProvider(value);
                if (provider != _selectedProvider) {
                  setState(() => _selectedProvider = provider);
                }
              },
            ),
            const SizedBox(height: 12),

            // Info text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You will receive a prompt on your phone to authorize this payment',
                      style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                    ),
                  ),
                ],
              ),
            ),
            
            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 16, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(fontSize: 12, color: Colors.red[900]),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Pay button
            ElevatedButton(
              onPressed: _isProcessing ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.electricGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Pay Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog shown while waiting for payment confirmation
class _PaymentPendingDialog extends StatefulWidget {
  final String phone;
  final double amount;
  final String transactionRef;
  final VoidCallback? onSuccess;

  const _PaymentPendingDialog({
    required this.phone,
    required this.amount,
    required this.transactionRef,
    this.onSuccess,
  });

  @override
  State<_PaymentPendingDialog> createState() => _PaymentPendingDialogState();
}

class _PaymentPendingDialogState extends State<_PaymentPendingDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Payment Pending'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.electricGreen),
          const SizedBox(height: 20),
          Text(
            'Check your phone (${widget.phone})',
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter your PIN to authorize the payment',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  'Amount: UGX ${widget.amount.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ref: ${widget.transactionRef}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            // TODO: Implement status checking
          },
          child: const Text('Check Status'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
