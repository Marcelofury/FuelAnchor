import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/enums/user_role.dart';
import '../../providers/providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleLogin(UserRole role) async {
    setState(() => _isLoading = true);

    try {
      final stellarService = ref.read(stellarServiceProvider);
      
      // Check if keypair exists, if not generate one
      final keypairResult = await stellarService.getStoredKeypair();
      
      await keypairResult.fold(
        (failure) async {
          final generateResult = await stellarService.generateAndStoreKeypair();
          await generateResult.fold(
            (error) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${error.message}')),
              );
            },
            (keyPair) async {
              await stellarService.fundTestnetAccount();
            },
          );
        },
        (keyPair) async {},
      );

      if (!mounted) return;

      ref.read(userRoleNotifierProvider.notifier).setRole(role);

      switch (role) {
        case UserRole.rider:
          context.go('/rider-dashboard');
          break;
        case UserRole.fleetDriver:
          context.go('/fleet-dashboard');
          break;
        case UserRole.merchant:
          context.go('/merchant-dashboard');
          break;
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 60),
              // Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.electricGreen,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  Icons.anchor,
                  size: 60,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 24),
              // App Name
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                  children: [
                    TextSpan(text: 'Fuel '),
                    TextSpan(
                      text: 'Anchor',
                      style: TextStyle(color: AppColors.electricGreen),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'BLOCKCHAIN FUEL MANAGEMENT',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.5,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 60),
              // Welcome Text
              Text(
                'Welcome back',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select your access portal to continue',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 40),
              // Driver Access Card
              _AccessCard(
                title: 'Driver Access',
                subtitle: 'Fuel up and manage trips',
                icon: Icons.local_shipping,
                onTap: _isLoading ? null : () => _handleLogin(UserRole.fleetDriver),
              ),
              const SizedBox(height: 16),
              // Merchant Access Card
              _AccessCard(
                title: 'Merchant Access',
                subtitle: 'Manage sales and inventory',
                icon: Icons.store,
                onTap: _isLoading ? null : () => _handleLogin(UserRole.merchant),
              ),
              const Spacer(),
              // Biometric Login
              Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[300]!, width: 2),
                    ),
                    child: Icon(
                      Icons.fingerprint,
                      size: 48,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'BIOMETRIC LOGIN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Verified Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, size: 20, color: AppColors.navy),
                    SizedBox(width: 8),
                    Text(
                      'VERIFIED BY STELLAR',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Footer Links
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'HELP CENTER',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(width: 40),
                  Text(
                    'ENGLISH (US)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccessCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  const _AccessCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.electricGreen,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 40,
              color: AppColors.navy,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.navy.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 24,
              color: AppColors.navy,
            ),
          ],
        ),
      ),
    );
  }
}
