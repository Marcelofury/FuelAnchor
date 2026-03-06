import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fuelanchor/core/constants/app_colors.dart';
import 'package:fuelanchor/core/providers/biometric_providers.dart';

/// Biometric Settings Screen
/// Allows users to enable/disable biometric authentication
class BiometricSettingsScreen extends ConsumerWidget {
  const BiometricSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final biometricAvailable = ref.watch(isBiometricAvailableProvider);
    final biometricEnabled = ref.watch(isBiometricEnabledProvider);
    final biometricType = ref.watch(biometricTypeNameProvider);
    final authState = ref.watch(biometricAuthNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Biometric Authentication'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: biometricAvailable.when(
        data: (available) {
          if (!available) {
            return _buildUnavailableView();
          }

          return biometricEnabled.when(
            data: (enabled) => _buildSettingsView(
              context,
              ref,
              enabled,
              biometricType,
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _buildErrorView(error.toString()),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorView(error.toString()),
      ),
    );
  }

  Widget _buildUnavailableView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fingerprint_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Biometric Not Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your device does not support biometric authentication or it has not been set up.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'To use this feature:\n'
              '1. Go to Settings\n'
              '2. Set up fingerprint or face recognition\n'
              '3. Return to FuelAnchor',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsView(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
    AsyncValue<String> biometricType,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Info Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.fingerprint,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Secure & Convenient',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    biometricType.when(
                      data: (type) => Text(
                        'Available: $type',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Enable/Disable Toggle
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: SwitchListTile(
            title: const Text(
              'Enable Biometric Login',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              enabled
                  ? 'Biometric authentication is active'
                  : 'Use biometrics to unlock the app',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            value: enabled,
            activeThumbColor: AppColors.success,
            onChanged: (value) async {
              if (value) {
                await _enableBiometric(context, ref);
              } else {
                await _disableBiometric(context, ref);
              }
            },
          ),
        ),
        const SizedBox(height: 16),

        // Features List
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What You Get',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildFeatureItem(
                  Icons.lock_outline,
                  'Quick Unlock',
                  'Access your wallet instantly',
                ),
                _buildFeatureItem(
                  Icons.security,
                  'Enhanced Security',
                  'Extra layer of protection',
                ),
                _buildFeatureItem(
                  Icons.payment,
                  'Secure Payments',
                  'Verify transactions with biometrics',
                ),
                _buildFeatureItem(
                  Icons.settings,
                  'Settings Protection',
                  'Protect sensitive settings changes',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Test Button (only show when enabled)
        if (enabled)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Icon(
                Icons.verified_user,
                color: AppColors.accent,
              ),
              title: const Text(
                'Test Biometric',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Verify your authentication works'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                await _testBiometric(context, ref);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _enableBiometric(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(biometricAuthNotifierProvider.notifier);
    await notifier.enableBiometric();

    if (!context.mounted) return;

    final state = ref.read(biometricAuthNotifierProvider);
    state.when(
      data: (enabled) {
        if (enabled) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Biometric authentication enabled'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      },
      loading: () {},
      error: (error, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  Future<void> _disableBiometric(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(biometricAuthNotifierProvider.notifier);
    await notifier.disableBiometric();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Biometric authentication disabled'),
        backgroundColor: Colors.grey,
      ),
    );
  }

  Future<void> _testBiometric(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(biometricAuthNotifierProvider.notifier);
    final success = await notifier.authenticate('Test your biometric authentication');

    if (!context.mounted) return;

    if (success) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success),
              SizedBox(width: 8),
              Text('Success!'),
            ],
          ),
          content: const Text('Biometric authentication is working correctly.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication failed or cancelled'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}
