import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/constants/app_colors.dart';
import 'core/router/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: FuelAnchorApp(),
    ),
  );
}

class FuelAnchorApp extends ConsumerWidget {
  const FuelAnchorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'FuelAnchor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          primary: AppColors.navy,
          secondary: AppColors.electricGreen,
          surface: Colors.white,
          background: Color(0xFFF5F5F5),
          error: AppColors.error,
        ),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.light().textTheme,
        ),
        scaffoldBackgroundColor: Color(0xFFF5F5F5),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      routerConfig: router,
    );
  }
}
