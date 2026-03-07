import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/user_profile.dart';
import '../../providers/providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _idController = TextEditingController(); // For Fleet: Vehicle ID, Merchant: Station ID
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  UserRole _selectedRole = UserRole.rider;
  bool _isLoading = false;
  bool _agreedToTerms = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _idController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to terms and conditions')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Check if Supabase is configured
      if (!SupabaseConfig.isConfigured) {
        throw Exception('Supabase is not configured. Please contact administrator.');
      }

      final stellarService = ref.read(stellarServiceProvider);
      
      // 2. Generate Stellar keypair first
      final keypairResult = await stellarService.generateAndStoreKeypair();
      
      await keypairResult.fold(
        (failure) {
          throw Exception(failure.message);
        },
        (keypair) async {
          // 3. Fund testnet account (optional - continue even if it fails)
          try {
            final fundResult = await stellarService.fundTestnetAccount();
            fundResult.fold(
              (failure) {
                AppLogger.warning('Testnet funding failed: ${failure.message}. Continuing with registration.');
              },
              (_) {
                AppLogger.info('Testnet account funded successfully');
              },
            );
          } catch (e) {
            AppLogger.warning('Testnet funding error: $e. Continuing with registration.');
          }
          
// 4. Create user account in Supabase database (REQUIRED)
          String supabaseUserId;
          
          try {
            // Create user directly in database with username/password
            supabaseUserId = await SupabaseService.createUser(
              username: _usernameController.text,
              password: _passwordController.text,
              fullName: _nameController.text,
              phoneNumber: _phoneController.text,
              role: _selectedRole.name,
              stellarPublicKey: keypair.accountId,
            );
            
            // Store user info in secure storage
            const storage = FlutterSecureStorage();
            await storage.write(key: 'supabase_user_id', value: supabaseUserId);
            await storage.write(key: 'auth_username', value: _usernameController.text);

            // Create role-specific profile
            final Map<String, dynamic> roleData = {};
            if (_selectedRole == UserRole.rider) {
              roleData['national_id'] = _idController.text;
            } else if (_selectedRole == UserRole.fleetDriver) {
              roleData['vehicle_id'] = _idController.text;
            } else if (_selectedRole == UserRole.fleetManager) {
              roleData['fleet_name'] = _idController.text;
            } else if (_selectedRole == UserRole.merchant) {
              roleData['station_id'] = _idController.text;
              roleData['station_name'] = _nameController.text;
            }

            if (roleData.isNotEmpty) {
              await SupabaseService.createRoleProfile(
                userId: supabaseUserId,
                role: _selectedRole.name,
                additionalData: roleData,
              );
            }
            
            AppLogger.info('Supabase user registered successfully: $supabaseUserId');
          } catch (e) {
            // Supabase error - registration fails
            throw Exception('Failed to register with Supabase: $e');
          }
          
          // 5. Set user role locally
          ref.read(userRoleNotifierProvider.notifier).setRole(_selectedRole);
          
          // 6. Save user profile locally (cache)
          final publicKey = await ref.read(stellarServiceProvider).getPublicKey();
          publicKey.fold(
            (failure) => AppLogger.warning('Failed to get public key for profile'),
            (pubKey) async {
              final profile = UserProfile(
                publicKey: pubKey,
                role: _selectedRole,
                name: _nameController.text,
                phone: _phoneController.text,
                vehicleId: _selectedRole == UserRole.fleetDriver ? _idController.text : null,
                fleetName: _selectedRole == UserRole.fleetManager ? _idController.text : null,
                stationId: _selectedRole == UserRole.merchant ? _idController.text : null,
                stationName: _selectedRole == UserRole.merchant ? _nameController.text : null,
                nationalId: _selectedRole == UserRole.rider ? _idController.text : null,
              );
              
              await ref.read(userProfileNotifierProvider.notifier).saveProfile(profile);
            },
          );
          
          if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Account created successfully!'),
                    duration: Duration(seconds: 2),
              ),
            );

            // Navigate to appropriate dashboard
            switch (_selectedRole) {
              case UserRole.rider:
                context.go('/rider-dashboard');
                break;
              case UserRole.fleetDriver:
                context.go('/fleet-dashboard');
                break;
              case UserRole.fleetManager:
                context.go('/fleet-tower');
                break;
              case UserRole.merchant:
                context.go('/merchant-dashboard');
                break;
            }
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: $e'),
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

  String _getIdFieldLabel() {
    switch (_selectedRole) {
      case UserRole.rider:
        return 'Vehicle Registration (Motorcycle/Bike)';
      case UserRole.fleetDriver:
        return 'Vehicle ID';
      case UserRole.fleetManager:
        return 'Company / Fleet Name';
      case UserRole.merchant:
        return 'Station ID';
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 24 : size.width * 0.1,
            vertical: 20,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.go('/login'),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Title
                Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 28 : 36,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Join FuelAnchor on the Stellar Network',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: AppColors.slate,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                // Role Selection
                const Text(
                  'I am a...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _RoleChip(
                      label: 'Rider',
                      icon: Icons.motorcycle,
                      selected: _selectedRole == UserRole.rider,
                      onTap: () => setState(() => _selectedRole = UserRole.rider),
                    ),
                    _RoleChip(
                      label: 'Fleet Driver',
                      icon: Icons.local_shipping,
                      selected: _selectedRole == UserRole.fleetDriver,
                      onTap: () => setState(() => _selectedRole = UserRole.fleetDriver),
                    ),
                    _RoleChip(
                      label: 'Fleet Manager',
                      icon: Icons.dashboard_customize,
                      selected: _selectedRole == UserRole.fleetManager,
                      onTap: () => setState(() => _selectedRole = UserRole.fleetManager),
                    ),
                    _RoleChip(
                      label: 'Merchant',
                      icon: Icons.store,
                      selected: _selectedRole == UserRole.merchant,
                      onTap: () => setState(() => _selectedRole = UserRole.merchant),
                    ),
                  ],
                ),
                
                const SizedBox(height: 30),
                
                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Phone field
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Username field
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    prefixIcon: const Icon(Icons.account_circle_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a username';
                    }
                    if (value.length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Password field
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _passwordVisible = !_passwordVisible;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  obscureText: !_passwordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Confirm Password field
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _confirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _confirmPasswordVisible = !_confirmPasswordVisible;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  obscureText: !_confirmPasswordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // ID field (Vehicle/Station/National ID)
                TextFormField(
                  controller: _idController,
                  decoration: InputDecoration(
                    labelText: _getIdFieldLabel(),
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your ${_getIdFieldLabel()}';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Terms checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _agreedToTerms,
                      onChanged: (value) => setState(() => _agreedToTerms = value ?? false),
                      activeColor: AppColors.electricGreen,
                    ),
                    const Expanded(
                      child: Text(
                        'I agree to FuelAnchor Terms and Stellar Network policies',
                        style: TextStyle(fontSize: 13, color: AppColors.slate),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 30),
                
                // Register button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electricGreen,
                    foregroundColor: AppColors.navy,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(AppColors.navy),
                          ),
                        )
                      : const Text(
                          'CREATE ACCOUNT',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                
                const SizedBox(height: 20),
                
                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: AppColors.slate),
                    ),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: AppColors.electricGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Blockchain badge
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.navy.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.navy.withOpacity(0.1)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_user, color: AppColors.electricGreen, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'SECURED BY STELLAR BLOCKCHAIN',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.electricGreen : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: selected ? AppColors.electricGreen : AppColors.slate.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selected ? AppColors.navy : AppColors.slate,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.navy : AppColors.slate,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
