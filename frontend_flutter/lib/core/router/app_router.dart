import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/dashboard/presentation/screens/rider_dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/fleet_dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/merchant_dashboard_screen.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/rider-dashboard',
        name: 'riderDashboard',
        builder: (context, state) => const RiderDashboardScreen(),
      ),
      GoRoute(
        path: '/fleet-dashboard',
        name: 'fleetDashboard',
        builder: (context, state) => const FleetDashboardScreen(),
      ),
      GoRoute(
        path: '/merchant-dashboard',
        name: 'merchantDashboard',
        builder: (context, state) => const MerchantDashboardScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
}
