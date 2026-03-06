import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/logger.dart';

/// Mobile Money Deposit Screen
/// Implements SEP-24 hosted deposit flow via WebView
class MobileMoneyDepositScreen extends ConsumerStatefulWidget {
  final String depositUrl;
  final double amount;
  final String currency;

  const MobileMoneyDepositScreen({
    super.key,
    required this.depositUrl,
    required this.amount,
    this.currency = 'UGX',
  });

  @override
  ConsumerState<MobileMoneyDepositScreen> createState() =>
      _MobileMoneyDepositScreenState();
}

class _MobileMoneyDepositScreenState
    extends ConsumerState<MobileMoneyDepositScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (progress == 100) {
              setState(() => _isLoading = false);
            }
          },
          onPageStarted: (String url) {
            AppLogger.info('Page started loading: $url');
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            AppLogger.info('Page finished loading: $url');
            setState(() => _isLoading = false);

            // Check if deposit is complete
            if (url.contains('success') || url.contains('complete')) {
              _handleDepositSuccess();
            } else if (url.contains('error') || url.contains('cancel')) {
              _handleDepositError(url);
            }
          },
          onWebResourceError: (WebResourceError error) {
            AppLogger.error('WebView error', error.description);
            setState(() {
              _error = error.description;
              _isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            // Allow all navigation for SEP-24 flow
            AppLogger.info('Navigating to: ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.depositUrl));
  }

  void _handleDepositSuccess() {
    AppLogger.info('Deposit completed successfully');
    Navigator.pop(context, {'success': true, 'amount': widget.amount});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Deposit successful! Your wallet will be credited shortly.'),
        backgroundColor: AppColors.electricGreen,
        duration: Duration(seconds: 5),
      ),
    );
  }

  void _handleDepositError(String url) {
    AppLogger.error('Deposit failed or cancelled', url);
    setState(() => _error = 'Deposit was cancelled or failed');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        title: Text(
          'Deposit ${widget.amount} ${widget.currency}',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Cancel Deposit?'),
                content: const Text(
                  'Are you sure you want to cancel this deposit? '
                  'Any progress will be lost.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Continue'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context, {'success': false}); // Close deposit screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Cancel Deposit'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: Stack(
        children: [
          if (_error != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error Loading Payment',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _error = null;
                        _initializeWebView();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else
            WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: AppColors.navy.withOpacity(0.9),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.electricGreen,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading payment gateway...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        color: AppColors.navy,
        padding: const EdgeInsets.all(16),
        child: const SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.security,
                    color: AppColors.electricGreen,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Secure payment powered by Stellar SEP-24',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Supported: M-Pesa, MTN Mobile Money, Airtel Money',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
