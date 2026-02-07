import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class MerchantSuccessOverlay extends StatelessWidget {
  final String liters;
  final String transactionHash;

  const MerchantSuccessOverlay({
    super.key,
    required this.liters,
    required this.transactionHash,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.electricGreen,
      body: SafeArea(
        child: Stack(
          children: [
            // Close Button
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            // Content
            Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Success Icon
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: Icon(
                        Icons.check,
                        size: 100,
                        color: AppColors.electricGreen,
                      ),
                    ),
                    SizedBox(height: 40),
                    // Payment Confirmed
                    Text(
                      'PAYMENT CONFIRMED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 32),
                    // Dispense Amount
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                        children: [
                          TextSpan(text: 'DISPENSE:\n'),
                          TextSpan(
                            text: '$liters LITERS',
                            style: TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 48),
                    // FuelAnchor Verified
                    Text(
                      'FUELANCHOR VERIFIED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 80),
                    // Transaction Verified
                    Text(
                      'TRANSACTION VERIFIED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Blockchain Hash: $transactionHash',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 60),
                    // Done Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.electricGreen,
                          padding: EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'DONE',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
