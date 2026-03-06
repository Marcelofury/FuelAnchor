import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fuelanchor/core/providers/geofencing_providers.dart';
import 'package:fuelanchor/core/constants/app_colors.dart';

/// Widget to validate proximity before allowing payment
class GeofencedPaymentButton extends ConsumerStatefulWidget {
  final double stationLatitude;
  final double stationLongitude;
  final String stationName;
  final double amount;
  final VoidCallback onPaymentAuthorized;
  final double? maxDistance;

  const GeofencedPaymentButton({
    super.key,
    required this.stationLatitude,
    required this.stationLongitude,
    required this.stationName,
    required this.amount,
    required this.onPaymentAuthorized,
    this.maxDistance,
  });

  @override
  ConsumerState<GeofencedPaymentButton> createState() =>
      _GeofencedPaymentButtonState();
}

class _GeofencedPaymentButtonState
    extends ConsumerState<GeofencedPaymentButton> {
  bool _isValidating = false;
  String? _errorMessage;
  double? _distance;

  Future<void> _validateAndPay() async {
    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    try {
      final geofencingService = ref.read(geofencingServiceProvider);

      // Validate transaction location
      final result = await geofencingService.validateTransactionLocation(
        stationLat: widget.stationLatitude,
        stationLon: widget.stationLongitude,
        maxDistanceMeters: widget.maxDistance,
      );

      result.fold(
        (failure) {
          setState(() {
            _errorMessage = failure.message;
            _isValidating = false;
          });
          
          // Show error dialog
          _showErrorDialog(failure.message);
        },
        (locationData) {
          setState(() {
            _distance = locationData['distance'] as double;
            _isValidating = false;
          });

          // Payment authorized - call callback
          widget.onPaymentAuthorized();
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to validate location: $e';
        _isValidating = false;
      });
      
      _showErrorDialog('Location validation failed. Please try again.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_off, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Location Required'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            Text(
              'Please ensure you are at ${widget.stationName} to complete this transaction.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _validateAndPay(); // Retry
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final geofencingService = ref.watch(geofencingServiceProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Distance indicator
        if (_distance != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Distance: ${geofencingService.formatDistance(_distance!)}',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Error message
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Payment button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isValidating ? null : _validateAndPay,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: _isValidating
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Validating Location...'),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.my_location, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Pay ${widget.amount.toStringAsFixed(2)} FUEL',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        // Info text
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Text(
                'Location verified transactions only',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
