import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/config/supabase_config.dart';
import '../../providers/providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;  bool _isBiometricLogin = false;

  @override
  void initState() {
    super.initState();
    _checkExistingAccount();
  }

  Future<void> _checkExistingAccount() async {
    final stellarService = ref.read(stellarServiceProvider);
    final keypairResult = await stellarService.getStoredKeypair();
    
    await keypairResult.fold(
      (failure) {
        // No existing keypair - check Supabase if configured
        if (SupabaseConfig.isConfigured && SupabaseService.isAuthenticated) {
          final role = ref.read(userRoleNotifierProvider);
          if (mounted && role != null) {
            _navigateToDashboard(role);
          }
        }
      },
      (keypair) async {
        // Has existing keypair, check for role
        final role = ref.read(userRoleNotifierProvider);
        if (mounted && role != null) {
          _navigateToDashboard(role);
        }
      },
    );
  }

  void _navigateToDashboard(UserRole role) {
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
      default:
        break;
    }
  }

  Future<void> _handleBiometricLogin() async {
    setState(() => _isBiometricLogin = true);
    
    try {
      final stellarService = ref.read(stellarServiceProvider);
      final keypairResult = await stellarService.getStoredKeypair();
      
      await keypairResult.fold(
        (failure) {
          throw Exception('No account found. Please register first.');
        },
        (keypair) async {
          final role = ref.read(userRoleNotifierProvider);
          if (mounted) {
            if (role != null) {
              _navigateToDashboard(role);
            } else {
              throw Exception('User role not found. Please register.');
            }
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBiometricLogin = false);
      }
    }
  }
  Future<void> _handleLogin(UserRole role) async {
    setState(() => _isLoading = true);

    try {
      final stellarService = ref.read(stellarServiceProvider);
      
      // Check if keypair exists
      final keypairResult = await stellarService.getStoredKeypair();
      
      await keypairResult.fold(
        (failure) async {
          // No keypair - need to register
          throw Exception('No account found. Please register first.');
        },
        (keyPair) async {
          // Has keypair - set role and login
          ref.read(userRoleNotifierProvider.notifier).setRole(role);
          
          if (mounted) {
            _navigateToDashboard(role);
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: AppColors.error,
          ),
        );
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.navy),
                    onPressed: () => context.go('/'),
                  ),
                ),
                const SizedBox(height: 20),
                // Logo
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.electricGreen,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.anchor,
                    size: 50,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 20),
                // App Name
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 32,
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
                const SizedBox(height: 40),
                // Welcome Text
                const Text(
                  'Welcome back',
                  style: TextStyle(
                    fontSize: 24,
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
                const SizedBox(height: 30),
                // Rider Access Card
                _AccessCard(
                  title: 'Rider Access',
                  subtitle: 'Scan and pay for fuel',
                  icon: Icons.motorcycle,
                  onTap: _isLoading ? null : () => _handleLogin(UserRole.rider),
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 30),
                // Biometric Login
                GestureDetector(
                  onTap: _isBiometricLogin ? null : _handleBiometricLogin,
                  child: Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: Colors.grey[300]!, width: 2),
                        ),
                        child: _isBiometricLogin
                            ? const Center(
                                child: SizedBox(
                                  width: 30,
                                  height: 30,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(AppColors.electricGreen),
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.fingerprint,
                                size: 40,
                                color: Colors.grey[800],
                              ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'BIOMETRIC LOGIN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Verified Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 18, color: AppColors.navy),
                      SizedBox(width: 8),
                      Text(
                        'VERIFIED BY STELLAR',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Don\'t have an account? ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/register'),
                      child: const Text(
                        'Register',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.electricGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Footer Links
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'HELP CENTER',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 30),
                    Text(
                      'ENGLISH (US)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
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
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 4),
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
            const Icon(
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
