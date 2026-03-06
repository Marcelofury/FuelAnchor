import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:fuelanchor/core/constants/app_colors.dart';

/// WebView screen for SEP-24 hosted deposit/withdrawal flow
/// Used for mobile money integration (M-Pesa, MTN MoMo, Airtel Money)
class Sep24WebViewScreen extends StatefulWidget {
  final String url;
  final String title;
  final Function(Map<String, dynamic>)? onSuccess;
  final Function(String)? onError;
  final Function()? onCancel;

  const Sep24WebViewScreen({
    super.key,
    required this.url,
    required this.title,
    this.onSuccess,
    this.onError,
    this.onCancel,
  });

  @override
  State<Sep24WebViewScreen> createState() => _Sep24WebViewScreenState();
}

class _Sep24WebViewScreenState extends State<Sep24WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _progress = progress / 100;
              _isLoading = progress < 100;
            });
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
            _checkForCallbackUrl(url);
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            _checkForCallbackUrl(url);
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _errorMessage = 'Failed to load page: ${error.description}';
              _isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            // Check for callback URL patterns
            if (request.url.contains('/callback') ||
                request.url.contains('/success') ||
                request.url.contains('/complete')) {
              _handleCompletion(request.url);
              return NavigationDecision.prevent;
            }

            if (request.url.contains('/cancel') ||
                request.url.contains('/error')) {
              _handleCancel(request.url);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  void _checkForCallbackUrl(String url) {
    // Parse URL for completion status
    final uri = Uri.parse(url);
    
    // SEP-24 success pattern
    if (uri.queryParameters.containsKey('transaction_id')) {
      _handleCompletion(url);
    }
    
    // Error pattern
    if (uri.queryParameters.containsKey('error')) {
      final error = uri.queryParameters['error'] ?? 'Unknown error';
      _handleError(error);
    }
  }

  void _handleCompletion(String url) {
    final uri = Uri.parse(url);
    final transactionId = uri.queryParameters['transaction_id'];
    final amount = uri.queryParameters['amount'];
    final status = uri.queryParameters['status'];

    if (widget.onSuccess != null) {
      widget.onSuccess!({
        'transactionId': transactionId,
        'amount': amount,
        'status': status ?? 'completed',
        'url': url,
      });
    }

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Transaction completed successfully!'),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 3),
      ),
    );

    // Close after short delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context, true);
      }
    });
  }

  void _handleError(String error) {
    if (widget.onError != null) {
      widget.onError!(error);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $error'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _handleCancel(String url) {
    if (widget.onCancel != null) {
      widget.onCancel!();
    }

    Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Cancel Transaction?'),
                content: const Text(
                  'Are you sure you want to cancel this transaction?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Continue'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      _handleCancel(widget.url);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _controller.reload();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Stack(
        children: [
          // WebView
          WebViewWidget(controller: _controller),

          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: _progress > 0 ? _progress : null,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading...',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                      ),
                    ),
                    if (_progress > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${(_progress * 100).toInt()}%',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // Progress bar at top
          if (_isLoading && _progress > 0)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),

          // Error message
          if (_errorMessage != null)
            Container(
              color: Colors.white,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Connection Error',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.red[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _errorMessage = null;
                          });
                          _controller.reload();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        color: Colors.grey[100],
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Secure payment powered by Stellar',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
