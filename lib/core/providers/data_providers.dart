import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/models/vendor.dart';
import '../../shared/models/invoice.dart';
import '../../shared/models/transaction.dart';
import '../../shared/models/user_profile.dart';
import '../services/vendor_service.dart';
import '../services/invoice_service.dart';
import '../services/transaction_service.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';

// Auth Providers
final authStateProvider = StreamProvider<AuthState>((ref) {
  return AuthService.authStateStream;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (state) => state.session?.user,
    loading: AuthService.getCurrentUser, // Return current user during loading
    error: (error, stackTrace) => null,
  );
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  // Also check if there's a current session even if user is null during loading
  return user != null || AuthService.getCurrentUser() != null;
});

// Profile Providers
final currentProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  if (!isAuthenticated) return null;

  try {
    return await ProfileService.getCurrentProfile();
  } catch (error) {
    throw Exception('Failed to load profile: $error');
  }
});

final dashboardMetricsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  if (!isAuthenticated) return {};

  try {
    return await ProfileService.getDashboardMetrics();
  } catch (error) {
    throw Exception('Failed to load dashboard metrics: $error');
  }
});

// Vendor Providers
final vendorsProvider = FutureProvider<List<Vendor>>((ref) async {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  if (!isAuthenticated) return [];

  try {
    return await VendorService.getVendors();
  } catch (error) {
    throw Exception('Failed to load vendors: $error');
  }
});

final FutureProviderFamily<Vendor, String> vendorProvider =
    FutureProvider.family<Vendor, String>((
      ref,
      vendorId,
    ) async {
      final isAuthenticated = ref.watch(isAuthenticatedProvider);
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      try {
        final vendor = await VendorService.getVendor(vendorId);
        if (vendor == null) {
          throw Exception('Vendor not found: $vendorId');
        }
        return vendor;
      } catch (error) {
        throw Exception('Failed to load vendor: $error');
      }
    });

// Invoice Providers
final invoicesProvider = FutureProvider<List<Invoice>>((ref) async {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  if (!isAuthenticated) return [];

  try {
    return await InvoiceService.getInvoices();
  } catch (error) {
    throw Exception('Failed to load invoices: $error');
  }
});

final FutureProviderFamily<Invoice, String> invoiceProvider =
    FutureProvider.family<Invoice, String>((
      ref,
      invoiceId,
    ) async {
      final isAuthenticated = ref.watch(isAuthenticatedProvider);
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      try {
        return await InvoiceService.getInvoice(invoiceId);
      } catch (error) {
        throw Exception('Failed to load invoice: $error');
      }
    });

final pendingInvoicesProvider = FutureProvider<List<Invoice>>((ref) async {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  if (!isAuthenticated) return [];

  try {
    return await InvoiceService.getInvoicesByStatus(InvoiceStatus.pending);
  } catch (error) {
    throw Exception('Failed to load pending invoices: $error');
  }
});

// Transaction Providers
final transactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  if (!isAuthenticated) return [];

  try {
    return await TransactionService.getTransactions();
  } catch (error) {
    throw Exception('Failed to load transactions: $error');
  }
});

final recentTransactionsProvider = FutureProvider<List<Transaction>>((
  ref,
) async {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  if (!isAuthenticated) return [];

  try {
    return await TransactionService.getRecentTransactions(limit: 5);
  } catch (error) {
    throw Exception('Failed to load recent transactions: $error');
  }
});

final FutureProviderFamily<Transaction, String> transactionProvider =
    FutureProvider.family<Transaction, String>((
      ref,
      transactionId,
    ) async {
      final isAuthenticated = ref.watch(isAuthenticatedProvider);
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      try {
        final transaction = await TransactionService.getTransaction(
          transactionId,
        );
        if (transaction == null) {
          throw Exception('Transaction not found: $transactionId');
        }
        return transaction;
      } catch (error) {
        throw Exception('Failed to load transaction: $error');
      }
    });

// Computed Providers for Dashboard
final totalRewardsProvider = Provider<double>((ref) {
  final metricsAsync = ref.watch(dashboardMetricsProvider);
  return metricsAsync.when(
    data: (metrics) => (metrics['totalRewards'] as num?)?.toDouble() ?? 0.0,
    loading: () => 0.0,
    error: (error, stackTrace) => 0.0,
  );
});

final totalPaymentsProvider = Provider<double>((ref) {
  final metricsAsync = ref.watch(dashboardMetricsProvider);
  return metricsAsync.when(
    data: (metrics) => (metrics['totalPayments'] as num?)?.toDouble() ?? 0.0,
    loading: () => 0.0,
    error: (error, stackTrace) => 0.0,
  );
});

final totalTransactionsProvider = Provider<int>((ref) {
  final metricsAsync = ref.watch(dashboardMetricsProvider);
  return metricsAsync.when(
    data: (metrics) => (metrics['totalTransactions'] as num?)?.toInt() ?? 0,
    loading: () => 0,
    error: (error, stackTrace) => 0,
  );
});

final vendorCountProvider = Provider<int>((ref) {
  final metricsAsync = ref.watch(dashboardMetricsProvider);
  return metricsAsync.when(
    data: (metrics) => (metrics['vendorCount'] as num?)?.toInt() ?? 0,
    loading: () => 0,
    error: (error, stackTrace) => 0,
  );
});

// Search and Filter Providers
final searchQueryProvider = StateProvider<String>((ref) => '');
final invoiceSearchQueryProvider = StateProvider<String>((ref) => '');
final transactionSearchQueryProvider = StateProvider<String>((ref) => '');

// Status Filter Providers
final selectedInvoiceStatusProvider = StateProvider<InvoiceStatus?>(
  (ref) => null,
);
final selectedTransactionStatusProvider = StateProvider<TransactionStatus?>(
  (ref) => null,
);

final filteredVendorsProvider = Provider<AsyncValue<List<Vendor>>>((ref) {
  final vendorsAsync = ref.watch(vendorsProvider);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase();

  return vendorsAsync.when(
    data: (vendors) {
      if (searchQuery.isEmpty) return AsyncValue.data(vendors);
      final filtered = vendors
          .where(
            (vendor) =>
                vendor.name.toLowerCase().contains(searchQuery) ||
                (vendor.email?.toLowerCase().contains(searchQuery) ?? false) ||
                (vendor.phone?.contains(searchQuery) ?? false),
          )
          .toList();
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: AsyncValue.error,
  );
});

final filteredInvoicesProvider = Provider<AsyncValue<List<Invoice>>>((ref) {
  final invoicesAsync = ref.watch(invoicesProvider);
  final searchQuery = ref.watch(invoiceSearchQueryProvider).toLowerCase();
  final selectedStatus = ref.watch(selectedInvoiceStatusProvider);

  return invoicesAsync.when(
    data: (invoices) {
      var filtered = invoices;

      // Filter by search query
      if (searchQuery.isNotEmpty) {
        filtered = filtered
            .where(
              (invoice) =>
                  invoice.vendorName.toLowerCase().contains(searchQuery) ||
                  invoice.invoiceNumber.toLowerCase().contains(searchQuery) ||
                  invoice.description.toLowerCase().contains(searchQuery),
            )
            .toList();
      }

      // Filter by status
      if (selectedStatus != null) {
        filtered = filtered
            .where((invoice) => invoice.status == selectedStatus)
            .toList();
      }

      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: AsyncValue.error,
  );
});

final filteredTransactionsProvider = Provider<AsyncValue<List<Transaction>>>((
  ref,
) {
  final transactionsAsync = ref.watch(transactionsProvider);
  final searchQuery = ref.watch(transactionSearchQueryProvider).toLowerCase();
  final selectedStatus = ref.watch(selectedTransactionStatusProvider);

  return transactionsAsync.when(
    data: (transactions) {
      var filtered = transactions;

      // Filter by search query
      if (searchQuery.isNotEmpty) {
        filtered = filtered
            .where(
              (transaction) =>
                  transaction.vendorName?.toLowerCase().contains(searchQuery) ==
                      true ||
                  (transaction.phonepeTransactionId?.toLowerCase().contains(
                        searchQuery,
                      ) ??
                      false),
            )
            .toList();
      }

      // Filter by status
      if (selectedStatus != null) {
        filtered = filtered
            .where((transaction) => transaction.status == selectedStatus)
            .toList();
      }

      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: AsyncValue.error,
  );
});
