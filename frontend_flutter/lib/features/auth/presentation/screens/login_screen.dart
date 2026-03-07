import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/config/supabase_config.dart';
import '../../domain/entities/user_profile.dart';
import '../../providers/providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isBiometricLogin = false;
  bool _passwordVisible = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
        // No existing keypair - stay on login screen
      },
      (keypair) async {
        // Has existing keypair, check for role and profile
        final role = ref.read(userRoleNotifierProvider);
        if (mounted && role != null) {
          // Load profile and navigate
          await ref.read(userProfileNotifierProvider.notifier).refresh();
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
      case UserRole.fleetManager:
        context.go('/fleet-tower');
        break;
      case UserRole.merchant:
        context.go('/merchant-dashboard');
        break;
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Check if Supabase is configured
      if (!SupabaseConfig.isConfigured) {
        throw Exception('Supabase is not configured. Please contact administrator.');
      }

      // 2. Sign in with Supabase
      final email = SupabaseService.usernameToEmail(_usernameController.text);
      final authResponse = await SupabaseService.signIn(
        email: email,
        password: _passwordController.text,
      );

      if (authResponse.user == null) {
        throw Exception('Login failed. Please check your credentials.');
      }

      // 3. Store user info in secure storage
      const storage = FlutterSecureStorage();
      await storage.write(key: 'supabase_user_id', value: authResponse.user!.id);
      await storage.write(key: 'auth_username', value: _usernameController.text);

      // 4. Fetch user profile from Supabase
      final profileData = await SupabaseService.getProfile(authResponse.user!.id);
      if (profileData == null) {
        throw Exception('User profile not found. Please contact support.');
      }
      
      // 5. Parse role from profile
      final roleString = profileData['role'] as String;
      final role = UserRole.values.firstWhere(
        (r) => r.name == roleString,
        orElse: () => UserRole.rider,
      );
      
      // 6. Set role locally
      ref.read(userRoleNotifierProvider.notifier).setRole(role);
      
      // 7. Create local profile cache from Supabase data
      final profile = UserProfile(
        publicKey: profileData['stellar_public_key'] as String,
        role: role,
        name: profileData['full_name'] as String,
        phone: profileData['phone_number'] as String,
        vehicleId: null, // Can be fetched from role-specific tables if needed
        fleetName: null,
        stationId: null,
        stationName: null,
        nationalId: null,
      );
      
      // 8. Save profile locally
      await ref.read(userProfileNotifierProvider.notifier).saveProfile(profile);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successful!'),
            duration: Duration(seconds: 1),
            backgroundColor: AppColors.electricGreen,
          ),
        );
        _navigateToDashboard(role);
      }
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
            child: Form(
              key: _formKey,
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
                    'Enter your credentials to continue',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 30),
                  
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
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your username';
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
                      fillColor: Colors.white,
                    ),
                    obscureText: !_passwordVisible,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Login button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
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
                              'LOGIN',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Divider with "OR"
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[400])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[400])),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Biometric Login (kept as quick login option)
                  GestureDetector(
                    onTap: _isBiometricLogin ? null : () {
                      // Quick login using stored credentials and biometric
                      setState(() => _isBiometricLogin = true);
                      _checkExistingAccount().then((_) {
                        if (mounted) setState(() => _isBiometricLogin = false);
                      });
                    },
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
                          'QUICK LOGIN',
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
      ),
    );
  }
}