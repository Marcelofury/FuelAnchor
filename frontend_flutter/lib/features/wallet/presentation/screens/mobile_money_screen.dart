import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fuelanchor/core/constants/app_colors.dart';
import '../../../auth/providers/providers.dart';
import '../../../wallet/providers/wallet_providers.dart';

/// Simulates a Mobile Money deposit into a Stellar Testnet wallet.
/// Uses a 3-step Virtual Mint: Friendbot â†’ Trustline â†’ Token Issuance.
/// Replaces the real Relworx / M-Pesa gateway while on Testnet.
class MobileMoneyScreen extends ConsumerStatefulWidget {
  const MobileMoneyScreen({super.key});

  @override
  ConsumerState<MobileMoneyScreen> createState() => _MobileMoneyScreenState();
}

class _MobileMoneyScreenState extends ConsumerState<MobileMoneyScreen> {
  bool _isLoading = false;
  int _currentStep = 0; // 0=idle, 1=friendbot, 2=trustline, 3=issuance, 4=done
  String? _errorMessage;
  String? _successMessage;

  Future<void> _runSimulation() async {
    setState(() {
      _isLoading = true;
      _currentStep = 0;
      _errorMessage = null;
      _successMessage = null;
    });

    final stellarService = ref.read(stellarServiceProvider);
    final keypairResult = await stellarService.getStoredKeypair();

    await keypairResult.fold(
      (failure) async {
        setState(() {
          _errorMessage = 'No wallet found. Please register first.';
          _isLoading = false;
        });
      },
      (keypair) async {
        setState(() => _currentStep = 1);
        final result = await stellarService.simulateMobileMoneyDeposit(
          userAddress: keypair.accountId,
          userSecret: keypair.secretSeed,
          amount: '50000',
        );
        result.fold(
          (failure) => setState(() {
            _errorMessage = failure.message;
            _isLoading = false;
          }),
          (message) {
            ref.read(walletBalanceNotifierProvider.notifier).refresh();
            setState(() {
              _currentStep = 4;
              _successMessage = message;
              _isLoading = false;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        title: const Text('Testnet Deposit Simulation'),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.navy, Color(0xFF1A3A5C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.account_balance_wallet,
                      color: AppColors.electricGreen, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'Simulate Mobile Money Deposit',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Executes 3 real Testnet blockchain transactions to mint 50,000 UGX into your wallet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.electricGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.electricGreen.withOpacity(0.5)),
                    ),
                    child: const Text(
                      'âš¡ STELLAR TESTNET â€” No real money',
                      style: TextStyle(
                        color: AppColors.electricGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Step indicators
            const Text(
              'What happens when you tap:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 16),
            _StepCard(
              stepNumber: 1,
              title: 'Fund with XLM (Gas)',
              subtitle: 'Friendbot gives your account XLM to pay network fees',
              icon: Icons.bolt,
              isActive: _currentStep >= 1,
              isDone: _currentStep > 1,
              isLoading: _isLoading && _currentStep == 1,
            ),
            const SizedBox(height: 12),
            _StepCard(
              stepNumber: 2,
              title: 'Establish UGX Trustline',
              subtitle: 'Your account signs a permission to hold UGX tokens',
              icon: Icons.handshake,
              isActive: _currentStep >= 2,
              isDone: _currentStep > 2,
              isLoading: _isLoading && _currentStep == 2,
            ),
            const SizedBox(height: 12),
            _StepCard(
              stepNumber: 3,
              title: 'Issue 50,000 UGX Tokens',
              subtitle: 'Manager account mints and sends UGX tokens to your wallet',
              icon: Icons.local_gas_station,
              isActive: _currentStep >= 3,
              isDone: _currentStep == 4,
              isLoading: _isLoading && _currentStep == 3,
            ),
            const SizedBox(height: 28),

            // Error
            if (_errorMessage != null) ...
              [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[300]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

            // Success
            if (_successMessage != null) ...
              [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[300]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: TextStyle(color: Colors.green[800]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

            // Action button
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _runSimulation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.electricGreen,
                  foregroundColor: AppColors.navy,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation(AppColors.navy),
                        ),
                      )
                    : const Icon(Icons.play_arrow_rounded),
                label: Text(
                  _isLoading ? 'Running Blockchain Steps...' : 'Simulate 50,000 UGX Deposit',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Production info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'In production, this button is replaced by a real M-Pesa / MTN MoMo'
                      ' payment prompt. The same 3 blockchain steps happen automatically'
                      ' after your mobile money confirmation arrives at our backend.',
                      style: TextStyle(
                          fontSize: 12, color: Colors.blue[800]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.stepNumber,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isActive,
    required this.isDone,
    required this.isLoading,
  });

  final int stepNumber;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isActive;
  final bool isDone;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final color = isDone
        ? Colors.green
        : isActive
            ? AppColors.electricGreen
            : Colors.grey;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDone
              ? Colors.green[300]!
              : isActive
                  ? AppColors.electricGreen
                  : Colors.grey[300]!,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation(AppColors.electricGreen),
                    ),
                  )
                : Icon(
                    isDone ? Icons.check_circle : icon,
                    color: color,
                    size: 22,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Step $stepNumber â€” $title',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isActive ? AppColors.navy : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

