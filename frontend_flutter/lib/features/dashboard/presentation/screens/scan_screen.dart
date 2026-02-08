import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/constants/app_colors.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    setState(() => _isProcessing = true);

    final String? code = barcodes.first.rawValue;
    if (code != null) {
      await cameraController.stop();
      
      if (mounted) {
        // Show payment confirmation dialog
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => _PaymentConfirmationDialog(
            vehicleId: code,
          ),
        );

        if (result == true) {
          // Payment confirmed, navigate back
          if (mounted) {
            Navigator.pop(context);
          }
        } else {
          // Resume scanning
          await cameraController.start();
          setState(() => _isProcessing = false);
        }
      }
    } else {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Scan Vehicle QR'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(cameraController.torchEnabled ? Icons.flash_on : Icons.flash_off),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_android),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: _handleBarcode,
          ),
          // Scanning overlay
          CustomPaint(
            painter: _ScannerOverlayPainter(),
            child: Container(),
          ),
          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Align QR code within the frame',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                if (_isProcessing)
                  const CircularProgressIndicator(
                    color: AppColors.electricGreen,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final scanAreaSize = size.width * 0.7;
    final left = (size.width - scanAreaSize) / 2;
    final top = (size.height - scanAreaSize) / 2;

    // Draw overlay with transparent center
    canvas.drawPath(
      Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize),
          const Radius.circular(16),
        ))
        ..fillType = PathFillType.evenOdd,
      paint,
    );

    // Draw corner brackets
    final bracketPaint = Paint()
      ..color = AppColors.electricGreen
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const bracketLength = 30.0;

    // Top-left corner
    canvas.drawLine(Offset(left, top + bracketLength), Offset(left, top), bracketPaint);
    canvas.drawLine(Offset(left, top), Offset(left + bracketLength, top), bracketPaint);

    // Top-right corner
    canvas.drawLine(Offset(left + scanAreaSize - bracketLength, top), 
                     Offset(left + scanAreaSize, top), bracketPaint);
    canvas.drawLine(Offset(left + scanAreaSize, top), 
                     Offset(left + scanAreaSize, top + bracketLength), bracketPaint);

    // Bottom-left corner
    canvas.drawLine(Offset(left, top + scanAreaSize - bracketLength), 
                     Offset(left, top + scanAreaSize), bracketPaint);
    canvas.drawLine(Offset(left, top + scanAreaSize), 
                     Offset(left + bracketLength, top + scanAreaSize), bracketPaint);

    // Bottom-right corner
    canvas.drawLine(Offset(left + scanAreaSize, top + scanAreaSize - bracketLength), 
                     Offset(left + scanAreaSize, top + scanAreaSize), bracketPaint);
    canvas.drawLine(Offset(left + scanAreaSize - bracketLength, top + scanAreaSize), 
                     Offset(left + scanAreaSize, top + scanAreaSize), bracketPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PaymentConfirmationDialog extends StatefulWidget {
  final String vehicleId;

  const _PaymentConfirmationDialog({required this.vehicleId});

  @override
  State<_PaymentConfirmationDialog> createState() => _PaymentConfirmationDialogState();
}

class _PaymentConfirmationDialogState extends State<_PaymentConfirmationDialog> {
  final TextEditingController _litersController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _litersController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _confirmPayment() async {
    if (_litersController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter fuel volume and amount')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    // TODO: Process payment via Stellar blockchain
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isProcessing = false);

    if (mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment processed successfully!'),
          backgroundColor: AppColors.electricGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Confirm Fueling',
        style: TextStyle(
          color: AppColors.navy,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vehicle ID: ${widget.vehicleId}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _litersController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Fuel Volume (Liters)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.water_drop),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (UGX)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _confirmPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.electricGreen,
            foregroundColor: AppColors.navy,
          ),
          child: _isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Confirm'),
        ),
      ],
    );
  }
}
