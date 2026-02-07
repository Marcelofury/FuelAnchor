import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/enums/user_role.dart';
import '../../providers/providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  UserRole? _selectedRole;
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a role')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final stellarService = ref.read(stellarServiceProvider);
      
      // Check if keypair exists, if not generate one
      final keypairResult = await stellarService.getStoredKeypair();
      
      await keypairResult.fold(
        (failure) async {
          // No keypair found, generate new one
          final generateResult = await stellarService.generateAndStoreKeypair();
          await generateResult.fold(
            (error) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${error.message}')),
              );
            },
            (keyPair) async {
              // Fund the account on testnet
              await stellarService.fundTestnetAccount();
            },
          );
        },
        (keyPair) async {
          // Keypair exists, continue
        },
      );

      if (!mounted) return;

      // Set the user role
      ref.read(userRoleNotifierProvider.notifier).setRole(_selectedRole!);

      // Navigate to appropriate dashboard
      switch (_selectedRole!) {
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // App Logo/Title
              Text(
                AppStrings.appName,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppColors.electricGreen,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Fuel Payments on Stellar',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.slate,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 64),

              // Role Selection Title
              Text(
                AppStrings.selectRole,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.lightSlate,
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Role Cards
              _RoleCard(
                role: UserRole.rider,
                isSelected: _selectedRole == UserRole.rider,
                onTap: () => setState(() => _selectedRole = UserRole.rider),
                icon: Icons.pedal_bike,
              ),
              const SizedBox(height: 16),
              _RoleCard(
                role: UserRole.fleetDriver,
                isSelected: _selectedRole == UserRole.fleetDriver,
                onTap: () => setState(() => _selectedRole = UserRole.fleetDriver),
                icon: Icons.local_shipping,
              ),
              const SizedBox(height: 16),
              _RoleCard(
                role: UserRole.merchant,
                isSelected: _selectedRole == UserRole.merchant,
                onTap: () => setState(() => _selectedRole = UserRole.merchant),
                icon: Icons.store,
              ),
              const SizedBox(height: 48),

              // Login Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.electricGreen,
                  foregroundColor: AppColors.navy,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.navy,
                        ),
                      )
                    : const Text(
                        AppStrings.login,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final UserRole role;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData icon;

  const _RoleCard({
    required this.role,
    required this.isSelected,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.lightNavy : AppColors.darkNavy,
          border: Border.all(
            color: isSelected ? AppColors.electricGreen : AppColors.slate.withOpacity(0.2),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? AppColors.electricGreen : AppColors.slate,
            ),
            const SizedBox(width: 16),
            Text(
              role.displayName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.electricGreen : AppColors.lightSlate,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.electricGreen,
              ),
          ],
        ),
      ),
    );
  }
}
