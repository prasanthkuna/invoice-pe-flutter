import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/payment_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/user_card.dart';

// Mock provider for cards (will be replaced with real provider post-PCC)
final cardsProvider = StateProvider<List<UserCard>>(
  (ref) => [
    UserCard(
      id: '1',
      userId: 'user1',
      cardToken: 'token_1234',
      cardLastFour: '1234',
      cardType: CardType.credit,
      cardNetwork: 'VISA',
      isDefault: true,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    UserCard(
      id: '2',
      userId: 'user1',
      cardToken: 'token_5678',
      cardLastFour: '5678',
      cardType: CardType.debit,
      cardNetwork: 'MASTERCARD',
      isDefault: false,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
  ],
);

class CardListScreen extends ConsumerWidget {
  const CardListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(cardsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cards'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PhonePe Card Management Info
            _PhonePeCardInfoCard(),

            const SizedBox(height: 24),

            // Header
            Text(
              'Payment Methods',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AppTheme.primaryText,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.3),

            const SizedBox(height: 8),

            Text(
              'Securely managed by PhonePe with bank-grade security',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.secondaryText,
              ),
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 32),

            // PCC Notice
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.warningColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.security,
                        color: AppTheme.warningColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'PCC Certification Required',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.warningColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Advanced card management features will be available after PCC certification. Currently showing demo cards for UI testing.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.primaryText,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),

            const SizedBox(height: 32),

            // Cards List
            if (cards.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.credit_card_outlined,
                      size: 64,
                      color: AppTheme.secondaryText.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Cards Added',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add your first payment card to get started',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.secondaryText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.3),
            ] else ...[
              ...cards.asMap().entries.map((entry) {
                final index = entry.key;
                final card = entry.value;
                return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: _CardItem(
                        card: card,
                        onTap: () => _showCardDetails(context, card),
                        onDelete: () => _deleteCard(context, ref, card),
                      ),
                    )
                    .animate(delay: Duration(milliseconds: 800 + (index * 200)))
                    .fadeIn()
                    .slideX(begin: 0.3);
              }),
            ],

            const SizedBox(height: 32),

            // Add Card Button (Disabled for PCC)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: null, // Disabled until PCC certification
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cardBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: AppTheme.secondaryText.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_card,
                      color: AppTheme.secondaryText.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Add New Card (Available Post-PCC)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.secondaryText.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 1200.ms).slideY(begin: 0.5),
          ],
        ),
      ),
    );
  }

  void _showCardDetails(BuildContext context, UserCard card) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Card Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.primaryText,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _DetailRow('Card Type', card.cardType.name.toUpperCase()),
            _DetailRow('Network', card.cardNetwork ?? 'Unknown'),
            _DetailRow('Last Four', '**** ${card.cardLastFour}'),
            _DetailRow('Status', card.isActive ? 'Active' : 'Inactive'),
            _DetailRow('Default', card.isDefault ? 'Yes' : 'No'),
            _DetailRow('Added', _formatDate(card.createdAt)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryAccent,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteCard(BuildContext context, WidgetRef ref, UserCard card) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text(
          'Delete Card',
          style: TextStyle(color: AppTheme.primaryText),
        ),
        content: Text(
          'Are you sure you want to delete this card ending in ${card.cardLastFour}?',
          style: const TextStyle(color: AppTheme.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.secondaryText),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              final cards = ref.read(cardsProvider);
              ref.read(cardsProvider.notifier).state = cards
                  .where((c) => c.id != card.id)
                  .toList();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Card deleted successfully'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _CardItem extends StatelessWidget {
  const _CardItem({
    required this.card,
    required this.onTap,
    required this.onDelete,
  });
  final UserCard card;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: card.cardType == CardType.credit
                ? [AppTheme.primaryAccent, const Color(0xFF1E3A8A)]
                : [AppTheme.secondaryAccent, const Color(0xFF92400E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  card.cardNetwork ?? 'CARD',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    if (card.isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'DEFAULT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              '**** **** **** ${card.cardLastFour}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  card.cardType.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatDate(card.createdAt),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.month.toString().padLeft(2, '0')}/${date.year.toString().substring(2)}';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.secondaryText,
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// PhonePe Card Management Info Widget
class _PhonePeCardInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryAccent.withOpacity(0.1),
            AppTheme.primaryAccent.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryAccent.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Security Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.security,
              color: AppTheme.primaryAccent,
              size: 32,
            ),
          ),

          const SizedBox(height: 16),

          // Title
          Text(
            'Secure Card Management',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.primaryText,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Description
          Text(
            'Your cards are securely managed by PhonePe with bank-grade security, automatic tokenization, and RBI compliance.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.secondaryText,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          // Manage Cards Button - DISABLED for PhonePe Demo
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: null, // DISABLED for demo submission
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.cardBackground,
                foregroundColor: AppTheme.secondaryText,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: AppTheme.secondaryText.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
              icon: const Icon(Icons.payment),
              label: const Text(
                'Manage Cards via PhonePe',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Info Text
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: AppTheme.secondaryText,
              ),
              const SizedBox(width: 6),
              Text(
                'Card management will be available after PhonePe integration',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.secondaryText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Initiate card management via PhonePe
void _initiateCardManagement(BuildContext context) async {
  try {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Start a ₹1 payment to access PhonePe card management
    // This will show PhonePe's native card management interface
    await PaymentService.processPaymentV3(
      vendorId: 'card_management',
      vendorName: 'Card Management',
      amount: 1.0, // ₹1 for card management access
    );

    // Close loading dialog
    if (context.mounted) {
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Card management completed via PhonePe'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (error) {
    // Close loading dialog
    if (context.mounted) {
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Card management failed: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
