import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/dashboard/presentation/screens/rider_dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/fleet_dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/merchant_dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/profile_screen.dart';
import '../../features/dashboard/presentation/screens/history_screen.dart';
import '../../features/dashboard/presentation/screens/support_screen.dart';
import '../../features/dashboard/presentation/screens/settings_screen.dart';
import '../../features/dashboard/presentation/screens/scan_screen.dart';
import '../../features/dashboard/presentation/screens/settlement_screen.dart';
import '../../features/dashboard/presentation/screens/nearby_stations_screen.dart';
import '../../features/dashboard/presentation/screens/edit_profile_screen.dart';
import '../../features/dashboard/presentation/screens/change_password_screen.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
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
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/history',
        name: 'history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/support',
        name: 'support',
        builder: (context, state) => const SupportScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/scan',
        name: 'scan',
        builder: (context, state) => const ScanScreen(),
      ),
      GoRoute(
        path: '/settlement',
        name: 'settlement',
        builder: (context, state) => const SettlementScreen(),
      ),
      GoRoute(
        path: '/nearby-stations',
        name: 'nearbyStations',
        builder: (context, state) => const NearbyStationsScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        name: 'editProfile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/change-password',
        name: 'changePassword',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
}
