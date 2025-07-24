import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import screens
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/auth/presentation/screens/phone_auth_screen.dart';
import '../../features/auth/presentation/screens/phone_input_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/business_info_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/vendors/presentation/screens/vendor_list_screen.dart';
import '../../features/vendors/presentation/screens/vendor_create_screen.dart';
import '../../features/vendors/presentation/screens/vendor_edit_screen.dart';
import '../../features/transactions/presentation/screens/transaction_list_screen.dart';
import '../../features/transactions/presentation/screens/transaction_detail_screen.dart';
import '../../features/invoices/presentation/screens/invoice_create_screen.dart';
import '../../features/cards/presentation/screens/card_list_screen.dart';
import '../../features/payment/presentation/screens/payment_screen.dart';
import '../../features/payment/presentation/screens/payment_success_screen.dart';
import '../../features/payment/presentation/screens/quick_payment_screen.dart';

// Temporary placeholder screen
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({required this.title, super.key});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            const Text('Screen under development'),
          ],
        ),
      ),
    );
  }
}

// Router Configuration (TRD Requirements) - Elon-style: No provider dependencies in redirect
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      // TESLA FIX: Use direct auth check instead of provider to prevent infinite loops
      final currentUser = Supabase.instance.client.auth.currentUser;
      final isAuthenticated = currentUser != null;

      final isAuthRoute =
          state.matchedLocation.startsWith('/auth') ||
          state.matchedLocation == '/welcome' ||
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/otp' ||
          state.matchedLocation == '/setup-profile';
      final isSplashRoute = state.matchedLocation == '/splash';

      // Allow splash screen to handle initial routing
      if (isSplashRoute) {
        return null;
      }

      // If not authenticated and not on auth route, redirect to auth
      if (!isAuthenticated && !isAuthRoute) {
        return '/auth';
      }

      // If authenticated and on auth route, redirect to dashboard
      if (isAuthenticated && isAuthRoute) {
        return '/dashboard';
      }

      return null; // No redirect needed
    },
    routes: [
      // Root redirect
      GoRoute(
        path: '/',
        redirect: (_, state) => '/dashboard',
      ),

      // Splash Screen
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Authentication Flow
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const PhoneAuthScreen(),
      ),
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const PhoneInputScreen(),
      ),
      GoRoute(
        path: '/otp',
        name: 'otp',
        builder: (context, state) => OtpScreen(
          phone: state.extra as String? ?? '+91',
        ),
      ),
      GoRoute(
        path: '/setup-profile',
        name: 'setup-profile',
        builder: (context, state) => const BusinessInfoScreen(),
      ),

      // Main App Flow
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/vendors',
        name: 'vendors',
        builder: (context, state) => const VendorListScreen(),
      ),
      GoRoute(
        path: '/vendors/create',
        name: 'vendor-create',
        builder: (context, state) => const VendorCreateScreen(),
      ),
      GoRoute(
        path: '/vendors/:id/edit',
        name: 'vendor-edit',
        builder: (context, state) {
          final vendorId = state.pathParameters['id']!;
          return VendorEditScreen(vendorId: vendorId);
        },
      ),
      GoRoute(
        path: '/pay/:vendorId',
        name: 'payment',
        builder: (context, state) {
          final vendorId = state.pathParameters['vendorId']!;
          return PaymentScreen(vendorId: vendorId);
        },
      ),
      GoRoute(
        path: '/payment/:invoiceId',
        name: 'invoice-payment',
        builder: (context, state) {
          final invoiceId = state.pathParameters['invoiceId']!;
          return PaymentScreen(invoiceId: invoiceId);
        },
      ),
      GoRoute(
        path: '/quick-pay',
        name: 'quick-payment',
        builder: (context, state) => const QuickPaymentScreen(),
      ),
      GoRoute(
        path: '/transactions',
        name: 'transactions',
        builder: (context, state) => const TransactionListScreen(),
      ),
      GoRoute(
        path: '/transactions/:id',
        name: 'transaction-detail',
        builder: (context, state) {
          final transactionId = state.pathParameters['id']!;
          return TransactionDetailScreen(transactionId: transactionId);
        },
      ),
      GoRoute(
        path: '/invoices/create',
        name: 'invoice-create',
        builder: (context, state) => const InvoiceCreateScreen(),
      ),
      GoRoute(
        path: '/cards',
        name: 'cards',
        builder: (context, state) => const CardListScreen(),
      ),
      GoRoute(
        path: '/payment-success',
        name: 'payment-success',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return PaymentSuccessScreen(paymentData: extra);
        },
      ),
      GoRoute(
        path: '/reports',
        name: 'reports',
        builder: (context, state) => const PlaceholderScreen(title: 'Reports'),
      ),
    ],

    // Error handling
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text('Error: ${state.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

// Navigation Extensions
extension AppRouterExtension on BuildContext {
  void goToAuth() => go('/auth');
  void goToWelcome() => go('/welcome');
  void goToLogin() => go('/login');
  void goToOtp() => go('/otp');
  void goToSetupProfile() => go('/setup-profile');
  void goToDashboard() => go('/dashboard');
  void goToVendors() => go('/vendors');
  void goToVendorCreate() => go('/vendors/create');
  void goToVendorEdit(String vendorId) => go('/vendors/$vendorId/edit');
  void goToPayment(String vendorId) => go('/pay/$vendorId');
  void goToQuickPayment() => go('/quick-pay');
  void goToTransactions() => go('/transactions');
  void goToInvoiceCreate() => go('/invoices/create');
  void goToCards() => go('/cards');
  void goToPaymentSuccess() => go('/payment-success');
  void goToReports() => go('/reports');
}
