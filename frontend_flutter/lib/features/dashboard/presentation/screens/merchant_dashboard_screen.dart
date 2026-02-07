import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../auth/providers/providers.dart';
import '../../../wallet/providers/wallet_providers.dart';

class MerchantDashboardScreen extends ConsumerWidget {
  const MerchantDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final publicKeyAsync = ref.watch(userPublicKeyProvider);
    final balanceAsync = ref.watch(walletBalanceNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Merchant Dashboard'),
        backgroundColor: AppColors.darkNavy,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(userRoleNotifierProvider.notifier).clearRole();
              context.go('/login');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(walletBalanceNotifierProvider.notifier).refresh();
            await ref.read(userPublicKeyProvider.notifier).refresh();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Earnings Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.electricGreen.withOpacity(0.2),
                        AppColors.darkNavy,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.electricGreen.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.account_balance_wallet,
                            color: AppColors.electricGreen,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Total Earnings',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppColors.slate,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      balanceAsync.when(
                        data: (balance) => Text(
                          balance != null ? '${balance.balance} FUEL' : '0 FUEL',
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                color: AppColors.electricGreen,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        loading: () => const CircularProgressIndicator(
                          color: AppColors.electricGreen,
                        ),
                        error: (error, _) => const Text(
                          'Error loading balance',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // QR Code Section
                Text(
                  'Payment QR Code',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.lightSlate,
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Customers scan this code to pay',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.slate,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // QR Code Container
                publicKeyAsync.when(
                  data: (publicKey) {
                    if (publicKey == null) {
                      return Container(
                        padding: const EdgeInsets.all(48),
                        decoration: BoxDecoration(
                          color: AppColors.darkNavy,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            'No wallet found',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ),
                      );
                    }

                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.electricGreen.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          QrImageView(
                            data: publicKey,
                            version: QrVersions.auto,
                            size: 250,
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.navy,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              publicKey,
                              style: const TextStyle(
                                color: AppColors.electricGreen,
                                fontSize: 10,
                                fontFamily: 'monospace',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => Container(
                    padding: const EdgeInsets.all(48),
                    decoration: BoxDecoration(
                      color: AppColors.darkNavy,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.electricGreen,
                      ),
                    ),
                  ),
                  error: (error, _) => Container(
                    padding: const EdgeInsets.all(48),
                    decoration: BoxDecoration(
                      color: AppColors.darkNavy,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        'Error loading QR code',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Today's Transactions (Placeholder)
                Text(
                  "Today's Transactions",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.lightSlate,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 16),
                const _TransactionTile(
                  amount: '45.50',
                  vehicle: 'Fleet Vehicle #1234',
                  time: '2 hours ago',
                ),
                const SizedBox(height: 12),
                const _TransactionTile(
                  amount: '67.20',
                  vehicle: 'Rider #5678',
                  time: '4 hours ago',
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.darkNavy,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'View All Transactions',
                      style: TextStyle(
                        color: AppColors.electricGreen,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

class _TransactionTile extends StatelessWidget {
  final String amount;
  final String vehicle;
  final String time;

  const _TransactionTile({
    required this.amount,
    required this.vehicle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.slate.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.electricGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.trending_up,
              color: AppColors.electricGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle,
                  style: const TextStyle(
                    color: AppColors.lightSlate,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    color: AppColors.slate,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+$amount FUEL',
            style: const TextStyle(
              color: AppColors.electricGreen,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
