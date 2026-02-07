import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFB8E5DC),
              Color(0xFFD4F1E8),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                Spacer(flex: 2),
                // Card Illustration
                Container(
                  width: 320,
                  height: 480,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 40,
                        spreadRadius: 0,
                        offset: Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // QR/Card Display Area
                        Container(
                          height: 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF7CD4C4),
                                Color(0xFF5CC4B0),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: CustomPaint(
                                painter: _QRPatternPainter(),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 32),
                        // Green Indicator Dot
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.electricGreen,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.electricGreen.withOpacity(0.4),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        Spacer(),
                        // Anchor Logo
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.electricGreen,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Stack(
                            children: [
                              // Anchor icon stylized
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Container(
                                      width: 4,
                                      height: 32,
                                      color: Colors.white,
                                    ),
                                    SizedBox(height: 4),
                                    // Anchor bottom curves
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            border: Border(
                                              left: BorderSide(color: Colors.white, width: 4),
                                              bottom: BorderSide(color: Colors.white, width: 4),
                                            ),
                                            borderRadius: BorderRadius.only(
                                              bottomLeft: Radius.circular(12),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            border: Border(
                                              right: BorderSide(color: Colors.white, width: 4),
                                              bottom: BorderSide(color: Colors.white, width: 4),
                                            ),
                                            borderRadius: BorderRadius.only(
                                              bottomRight: Radius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24),
                        // FuelAnchor Text
                        Text(
                          'FUELANCHOR',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.electricGreen,
                            letterSpacing: 2,
                          ),
                        ),
                        SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                Spacer(flex: 1),
                // Main Heading
                Text(
                  'Secure Energy\nManagement',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: AppColors.electricGreen,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 16),
                // Subtitle
                Text(
                  'The blockchain-powered standard for\nmodern fuel distribution',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF7CD4C4),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Spacer(flex: 2),
                // Enter Platform Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.go('/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.electricGreen,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Enter Platform',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(width: 12),
                        Icon(Icons.arrow_forward, size: 22),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 32),
                // Status Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Network Status
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NETWORK STATUS',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.electricGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Operational',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.electricGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(width: 60),
                    // Protocol
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PROTOCOL',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'v4.2-Stable',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF7CD4C4),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 20),
        child: FloatingActionButton(
          mini: true,
          backgroundColor: Colors.white,
          elevation: 2,
          onPressed: () {
            setState(() {
              _isDarkMode = !_isDarkMode;
            });
          },
          child: Icon(
            _isDarkMode ? Icons.light_mode : Icons.dark_mode,
            color: AppColors.navy,
            size: 20,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// Custom painter for QR-like pattern
class _QRPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final blockSize = size.width / 8;

    // Draw pixelated pattern
    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 8; j++) {
        // Create pseudo-random pattern based on position
        if ((i + j) % 3 == 0 || (i * j) % 5 == 0) {
          canvas.drawRect(
            Rect.fromLTWH(
              i * blockSize + 2,
              j * blockSize + 2,
              blockSize - 4,
              blockSize - 4,
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
