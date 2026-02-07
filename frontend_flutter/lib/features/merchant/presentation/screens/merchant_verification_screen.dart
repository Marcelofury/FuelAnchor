import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class MerchantVerificationScreen extends StatelessWidget {
  final String amount;
  final String customer;
  final String product;
  final String volume;
  final String transactionHash;

  const MerchantVerificationScreen({
    super.key,
    required this.amount,
    required this.customer,
    required this.product,
    required this.volume,
    required this.transactionHash,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Icon
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                  border: Border.all(color: AppColors.electricGreen, width: 6),
                ),
                child: Center(
                  child: Icon(
                    Icons.check,
                    size: 80,
                    color: AppColors.electricGreen,
                  ),
                ),
              ),
              SizedBox(height: 40),
              // Payment Confirmed Text
              Text(
                'Payment Confirmed',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              // Amount
              Text(
                amount,
                style: TextStyle(
                  color: AppColors.electricGreen,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 48),
              // Transaction Details Card
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.navy.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[800]!, width: 1),
                ),
                child: Column(
                  children: [
                    _DetailRow(label: 'Customer', value: customer),
                    SizedBox(height: 16),
                    _DetailRow(label: 'Product', value: product),
                    SizedBox(height: 16),
                    _DetailRow(label: 'Volume', value: volume),
                  ],
                ),
              ),
              Spacer(),
              // Next Transaction Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electricGreen,
                    foregroundColor: AppColors.navy,
                    padding: EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Next Transaction',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Blockchain Hash Link
              GestureDetector(
                onTap: () {
                  // Open blockchain explorer
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.link, color: AppColors.electricGreen, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'View Blockchain Hash: $transactionHash',
                      style: TextStyle(
                        color: AppColors.electricGreen,
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.electricGreen,
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
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 16,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
