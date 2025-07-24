import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/vendor.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/providers/data_providers.dart';
import '../../../../core/utils/navigation_helper.dart';

class VendorListScreen extends ConsumerWidget {
  const VendorListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredVendors = ref.watch(filteredVendorsProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    // If not authenticated, show login prompt
    if (!isAuthenticated) {
      return Scaffold(
        backgroundColor: AppTheme.primaryBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 64,
                color: AppTheme.primaryAccent,
              ),
              const SizedBox(height: 16),
              const Text(
                'Please log in to view vendors',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/auth'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryAccent,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Log In'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendors'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Show search
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) =>
                  ref.read(searchQueryProvider.notifier).state = value,
              style: const TextStyle(color: AppTheme.primaryText),
              decoration: InputDecoration(
                hintText: 'Search vendors...',
                hintStyle: const TextStyle(color: AppTheme.secondaryText),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppTheme.secondaryText,
                ),
                filled: true,
                fillColor: AppTheme.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.3),

          // Vendors List
          Expanded(
            child: filteredVendors.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryAccent,
                  ),
                ),
              ),
              error: (error, stackTrace) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading vendors',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.red,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: const TextStyle(color: AppTheme.secondaryText),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.refresh(filteredVendorsProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryAccent,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (filteredVendors) => filteredVendors.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.business_outlined,
                            size: 64,
                            color: AppTheme.secondaryText.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            searchQuery.isEmpty
                                ? 'No vendors yet'
                                : 'No vendors found',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: AppTheme.secondaryText,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            searchQuery.isEmpty
                                ? 'Add your first vendor to get started'
                                : 'Try a different search term',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppTheme.secondaryText.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredVendors.length,
                      itemBuilder: (context, index) {
                        final vendor = filteredVendors[index];
                        return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: _VendorCard(
                                vendor: vendor,
                                onTap: () => context.push('/pay/${vendor.id}'),
                              ),
                            )
                            .animate(delay: Duration(milliseconds: 100 * index))
                            .fadeIn()
                            .slideX(begin: 0.3);
                      },
                    ),
            ),
          ),
        ],
      ),

      // Add Vendor FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await NavigationHelper.safePush<bool>(
            context,
            '/vendors/create',
          );
          if (result == true) {
            ref.invalidate(vendorsProvider);
          }
        },
        backgroundColor: AppTheme.primaryAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Vendor',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ).animate().scale(delay: 600.ms),
    );
  }
}

class _VendorCard extends StatelessWidget {
  const _VendorCard({
    required this.vendor,
    required this.onTap,
  });
  final Vendor vendor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryAccent.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Vendor Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      vendor.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.primaryAccent,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Vendor Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vendor.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.primaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vendor.upiId ??
                            '${vendor.accountNumber} • ${vendor.ifscCode}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),

                // Action Buttons
                Row(
                  children: [
                    // Edit Button
                    GestureDetector(
                      onTap: () => context.push('/vendors/${vendor.id}/edit'),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryText.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: AppTheme.secondaryText,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Pay Button
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Pay',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Stats
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Paid',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.secondaryText,
                        ),
                      ),
                      Text(
                        '₹${vendor.totalPaid.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.primaryText,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transactions',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.secondaryText,
                        ),
                      ),
                      Text(
                        vendor.transactionCount.toString(),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.primaryText,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
