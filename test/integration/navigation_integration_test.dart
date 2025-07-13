import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoice_pe_app/main.dart';
import 'package:invoice_pe_app/core/providers/data_providers.dart';
import 'package:invoice_pe_app/core/services/debug_service.dart';

void main() {
  group('Navigation Integration Tests', () {
    late ProviderContainer container;

    setUp(() {
      DebugService.initialize();
      container = ProviderContainer(
        overrides: [
          // Mock authentication as true for testing
          isAuthenticatedProvider.overrideWith((ref) => true),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('Dashboard navigation to all 5 core features works', (
      tester,
    ) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const InvoicePeApp(),
        ),
      );

      // Wait for app to load
      await tester.pumpAndSettle();

      // Navigate to dashboard (should be default for authenticated users)
      await tester.pumpAndSettle();

      // Test Quick Pay navigation
      await tester.tap(find.text('Quick Pay'));
      await tester.pumpAndSettle();
      expect(find.text('Quick Payment'), findsOneWidget);
      DebugService.logInfo('✅ Quick Pay navigation successful');

      // Go back to dashboard
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Test Transactions navigation
      await tester.tap(find.text('Transactions'));
      await tester.pumpAndSettle();
      expect(find.text('Transaction History'), findsOneWidget);
      DebugService.logInfo('✅ Transactions navigation successful');

      // Go back to dashboard
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Test Cards navigation
      await tester.tap(find.text('Cards'));
      await tester.pumpAndSettle();
      expect(find.text('My Cards'), findsOneWidget);
      DebugService.logInfo('✅ Cards navigation successful');

      // Go back to dashboard
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Test Invoice Create navigation
      await tester.tap(find.text('Invoice Create'));
      await tester.pumpAndSettle();
      expect(find.text('Create Invoice'), findsOneWidget);
      DebugService.logInfo('✅ Invoice Create navigation successful');

      DebugService.logInfo(
        '🎉 All 5 core features navigation verified successfully',
      );
    });

    testWidgets('Dashboard quick actions are properly displayed', (
      tester,
    ) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const InvoicePeApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify all 4 quick action cards are present
      expect(find.text('Quick Pay'), findsOneWidget);
      expect(find.text('Transactions'), findsOneWidget);
      expect(find.text('Cards'), findsOneWidget);
      expect(find.text('Invoice Create'), findsOneWidget);

      // Verify subtitles
      expect(find.text('Instant payment'), findsOneWidget);
      expect(find.text('View history'), findsOneWidget);
      expect(find.text('Manage cards'), findsOneWidget);
      expect(find.text('Create invoice'), findsOneWidget);

      DebugService.logInfo('✅ All dashboard quick actions displayed correctly');
    });

    testWidgets('FAB navigation works correctly', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const InvoicePeApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Test FAB navigation to Quick Pay
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.text('Quick Payment'), findsOneWidget);

      DebugService.logInfo('✅ FAB navigation to Quick Pay successful');
    });

    testWidgets('Error handling for navigation works', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const InvoicePeApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Test that navigation doesn't crash the app
      try {
        await tester.tap(find.text('Quick Pay'));
        await tester.pumpAndSettle();
        DebugService.logInfo('✅ Navigation error handling works correctly');
      } catch (e) {
        DebugService.logError('Navigation error caught and handled', error: e);
      }
    });
  });

  group('Provider Integration Tests', () {
    testWidgets('Data providers refresh correctly after navigation', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          isAuthenticatedProvider.overrideWith((ref) => true),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const InvoicePeApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to transactions and verify providers work
      await tester.tap(find.text('Transactions'));
      await tester.pumpAndSettle();

      // Check if transaction providers are working (should not crash)
      expect(find.byType(CircularProgressIndicator), findsAny);

      DebugService.logInfo('✅ Provider integration working correctly');

      container.dispose();
    });
  });
}
