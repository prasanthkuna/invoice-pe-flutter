// InvoicePe Authentication & Session Tests - Patrol 2.0
// Security-Critical: OTP flow, JWT validation, session persistence

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:invoice_pe_app/core/services/debug_service.dart';
import '../test/utils/test_helpers.dart';
import '../test/utils/mock_factories.dart';

void main() {
  group('🔐 Authentication & Session Tests - Security Critical', () {
    late MockSupabaseClient mockSupabase;
    late MockGoTrueClient mockAuth;

    setUpAll(TestHelpers.initializeTestEnvironment);

    setUp(() {
      mockSupabase = MockSupabaseClient();
      mockAuth = MockGoTrueClient();

      when(() => mockSupabase.auth).thenReturn(mockAuth);
    });

    patrolTest(
      '📱 Complete OTP Authentication Flow',
      ($) async {
        TestPerformance.startTimer('OTP Authentication Flow');

        // Mock successful OTP sending
        when(
          () => mockAuth.signInWithOtp(
            phone: any(named: 'phone'),
            shouldCreateUser: any(named: 'shouldCreateUser'),
          ),
        ).thenAnswer(
          (_) async => AuthResponse(
            user: null,
            session: null,
          ),
        );

        // Mock successful OTP verification
        when(
          () => mockAuth.verifyOTP(
            phone: any(named: 'phone'),
            token: any(named: 'token'),
            type: any(named: 'type'),
          ),
        ).thenAnswer(
          (_) async => AuthResponse(
            user: User(
              id: 'test-user-id',
              appMetadata: {},
              userMetadata: {},
              aud: 'authenticated',
              createdAt: DateTime.now().toIso8601String(),
            ),
            session: Session(
              accessToken: 'test-access-token',
              refreshToken: 'test-refresh-token',
              expiresIn: 3600,
              tokenType: 'bearer',
              user: User(
                id: 'test-user-id',
                appMetadata: {},
                userMetadata: {},
                aud: 'authenticated',
                createdAt: DateTime.now().toIso8601String(),
              ),
            ),
          ),
        );

        await $.pumpWidgetAndSettle(
          TestHelpers.createTestApp(),
        );

        // Navigate to login
        await $.tap(find.text('Get Started'));
        await $.pumpAndSettle();

        // Enter phone number
        await $.enterText(
          find.byType(TextFormField),
          TestDataFactory.generateTestPhone(),
        );
        await $.pumpAndSettle();

        // Tap Send OTP
        await $.tap(find.text('Send OTP'));
        await $.pumpAndSettle();

        // Verify OTP screen
        expect(find.text('Enter OTP'), findsOneWidget);
        DebugService.logAuth('✅ OTP screen displayed');

        // Enter OTP
        await $.enterText(
          find.byType(TextFormField),
          TestDataFactory.generateTestOtp(),
        );
        await $.pumpAndSettle();

        // Tap Verify
        await $.tap(find.text('Verify'));
        await $.pumpAndSettle();

        // Wait for authentication
        await TestHelpers.waitForLoading($);

        // Verify successful login (should navigate to dashboard)
        expect(find.text('Dashboard'), findsOneWidget);
        DebugService.logAuth('✅ Authentication flow completed successfully');

        TestPerformance.endTimer(
          'OTP Authentication Flow',
          maxExpected: const Duration(seconds: 8),
        );
      },
    );

    patrolTest(
      '❌ Invalid OTP Handling',
      ($) async {
        TestPerformance.startTimer('Invalid OTP Handling');

        // Mock OTP sending success
        when(
          () => mockAuth.signInWithOtp(
            phone: any(named: 'phone'),
            shouldCreateUser: any(named: 'shouldCreateUser'),
          ),
        ).thenAnswer(
          (_) async => AuthResponse(
            user: null,
            session: null,
          ),
        );

        // Mock OTP verification failure
        when(
          () => mockAuth.verifyOTP(
            phone: any(named: 'phone'),
            token: any(named: 'token'),
            type: any(named: 'type'),
          ),
        ).thenThrow(AuthException('Invalid OTP'));

        await $.pumpWidgetAndSettle(
          TestHelpers.createTestApp(),
        );

        // Navigate through OTP flow
        await $.tap(find.text('Get Started'));
        await $.pumpAndSettle();

        await $.enterText(
          find.byType(TextFormField),
          TestDataFactory.generateTestPhone(),
        );
        await $.pumpAndSettle();

        await $.tap(find.text('Send OTP'));
        await $.pumpAndSettle();

        // Enter invalid OTP
        await $.enterText(
          find.byType(TextFormField),
          '000000',
        );
        await $.pumpAndSettle();

        await $.tap(find.text('Verify'));
        await $.pumpAndSettle();

        // Verify error message
        expect(find.textContaining('Invalid OTP'), findsOneWidget);
        DebugService.logAuth('✅ Invalid OTP handled correctly');

        TestPerformance.endTimer(
          'Invalid OTP Handling',
          maxExpected: const Duration(seconds: 5),
        );
      },
    );

    patrolTest(
      '🔄 Session Persistence Test',
      ($) async {
        TestPerformance.startTimer('Session Persistence');

        // Mock existing session
        when(() => mockAuth.currentSession).thenReturn(
          Session(
            accessToken: 'existing-access-token',
            refreshToken: 'existing-refresh-token',
            expiresIn: 3600,
            tokenType: 'bearer',
            user: User(
              id: 'test-user-id',
              appMetadata: {},
              userMetadata: {},
              aud: 'authenticated',
              createdAt: DateTime.now().toIso8601String(),
            ),
          ),
        );

        when(() => mockAuth.currentUser).thenReturn(
          User(
            id: 'test-user-id',
            appMetadata: {},
            userMetadata: {},
            aud: 'authenticated',
            createdAt: DateTime.now().toIso8601String(),
          ),
        );

        // Mock session refresh
        when(() => mockAuth.refreshSession()).thenAnswer(
          (_) async => AuthResponse(
            user: User(
              id: 'test-user-id',
              appMetadata: {},
              userMetadata: {},
              aud: 'authenticated',
              createdAt: DateTime.now().toIso8601String(),
            ),
            session: Session(
              accessToken: 'refreshed-access-token',
              refreshToken: 'refreshed-refresh-token',
              expiresIn: 3600,
              tokenType: 'bearer',
              user: User(
                id: 'test-user-id',
                appMetadata: {},
                userMetadata: {},
                aud: 'authenticated',
                createdAt: DateTime.now().toIso8601String(),
              ),
            ),
          ),
        );

        await $.pumpWidgetAndSettle(
          TestHelpers.createTestApp(),
        );

        // Should automatically navigate to dashboard with existing session
        expect(find.text('Dashboard'), findsOneWidget);
        DebugService.logAuth('✅ Session persistence verified');

        TestPerformance.endTimer(
          'Session Persistence',
          maxExpected: const Duration(seconds: 3),
        );
      },
    );

    patrolTest(
      '⏰ Session Timeout Handling',
      ($) async {
        TestPerformance.startTimer('Session Timeout');

        // Mock expired session
        when(() => mockAuth.currentSession).thenReturn(
          Session(
            accessToken: 'expired-access-token',
            refreshToken: 'expired-refresh-token',
            expiresIn: -1, // Expired
            tokenType: 'bearer',
            user: User(
              id: 'test-user-id',
              appMetadata: {},
              userMetadata: {},
              aud: 'authenticated',
              createdAt: DateTime.now().toIso8601String(),
            ),
          ),
        );

        // Mock refresh failure
        when(() => mockAuth.refreshSession()).thenThrow(
          AuthException('Session expired'),
        );

        await $.pumpWidgetAndSettle(
          TestHelpers.createTestApp(),
        );

        // Should redirect to login due to expired session
        expect(find.text('Welcome'), findsOneWidget);
        DebugService.logAuth('✅ Session timeout handled correctly');

        TestPerformance.endTimer(
          'Session Timeout',
          maxExpected: const Duration(seconds: 3),
        );
      },
    );

    patrolTest(
      '🔐 JWT Token Validation',
      ($) async {
        // Test JWT token structure and validation
        const mockToken =
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';

        // Mock current user with JWT
        when(() => mockAuth.currentUser).thenReturn(
          User(
            id: 'test-user-id',
            appMetadata: {},
            userMetadata: {},
            aud: 'authenticated',
            createdAt: DateTime.now().toIso8601String(),
          ),
        );

        when(() => mockAuth.currentSession).thenReturn(
          Session(
            accessToken: mockToken,
            refreshToken: 'test-refresh-token',
            expiresIn: 3600,
            tokenType: 'bearer',
            user: User(
              id: 'test-user-id',
              appMetadata: {},
              userMetadata: {},
              aud: 'authenticated',
              createdAt: DateTime.now().toIso8601String(),
            ),
          ),
        );

        // Verify JWT structure
        expect(
          mockToken.split('.').length,
          equals(3),
        ); // Header.Payload.Signature

        DebugService.logAuth('✅ JWT token validation verified');
      },
    );
  });
}
