// InvoicePe AuthService Tests - Mocktail Unit Tests
// Security-focused testing for authentication logic

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:invoice_pe_app/core/services/auth_service.dart';
import 'package:invoice_pe_app/core/services/debug_service.dart';
import 'package:invoice_pe_app/core/types/auth_types.dart' as auth_types;
import 'package:invoice_pe_app/core/types/result.dart';
import '../utils/test_helpers.dart';
import '../utils/mock_factories.dart';

void main() {
  group('🔐 AuthService Tests - Security Critical', () {
    late MockSupabaseClient mockSupabase;
    late MockGoTrueClient mockAuth;

    setUpAll(() async {
      TestHelpers.initializeTestEnvironment();
      DebugService.initialize();
    });

    setUp(() {
      mockSupabase = MockSupabaseClient();
      mockAuth = MockGoTrueClient();

      when(() => mockSupabase.auth).thenReturn(mockAuth);
    });

    group('OTP Authentication', () {
      test('✅ Send OTP successfully', () async {
        TestPerformance.startTimer('Send OTP');

        const testPhone = '+919876543210';

        // Mock successful OTP sending
        when(
          () => mockAuth.signInWithOtp(
            phone: testPhone,
            shouldCreateUser: true,
          ),
        ).thenAnswer(
          (_) async => AuthResponse(
            user: null,
            session: null,
          ),
        );

        final result = await AuthService.sendOtp(testPhone);

        expect(result, isA<auth_types.OtpSent>());

        if (result is auth_types.OtpSent) {
          expect(result.phone, equals(testPhone));
          expect(result.message.contains(testPhone), true);
        }

        verify(
          () => mockAuth.signInWithOtp(
            phone: testPhone,
            shouldCreateUser: true,
          ),
        ).called(1);

        TestPerformance.endTimer(
          'Send OTP',
          maxExpected: const Duration(seconds: 1),
        );
      });

      test('❌ Handle OTP sending failure', () async {
        const testPhone = '+919876543210';

        // Mock OTP sending failure
        when(
          () => mockAuth.signInWithOtp(
            phone: testPhone,
            shouldCreateUser: true,
          ),
        ).thenThrow(AuthException('Rate limit exceeded'));

        final result = await AuthService.sendOtp(testPhone);

        expect(result, isA<auth_types.OtpFailed>());

        if (result is auth_types.OtpFailed) {
          expect(result.phone, equals(testPhone));
          expect(result.error.contains('Rate limit'), true);
        }
      });

      test('✅ Verify OTP successfully', () async {
        TestPerformance.startTimer('Verify OTP');

        const testPhone = '+919876543210';
        const testOtp = '123456';

        final mockUser = User(
          id: 'test-user-id',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
        );

        // Mock successful OTP verification
        when(
          () => mockAuth.verifyOTP(
            phone: testPhone,
            token: testOtp,
            type: OtpType.sms,
          ),
        ).thenAnswer(
          (_) async => AuthResponse(
            user: mockUser,
            session: Session(
              accessToken: 'test-access-token',
              refreshToken: 'test-refresh-token',
              expiresIn: 3600,
              tokenType: 'bearer',
              user: mockUser,
            ),
          ),
        );

        final result = await AuthService.verifyOtp(
          phone: testPhone,
          otp: testOtp,
        );

        expect(result, isA<Success<auth_types.AuthData>>());

        if (result is Success<auth_types.AuthData>) {
          expect(result.data.user.id, equals('test-user-id'));
        }

        TestPerformance.endTimer(
          'Verify OTP',
          maxExpected: const Duration(seconds: 1),
        );
      });

      test('❌ Handle invalid OTP', () async {
        const testPhone = '+919876543210';
        const invalidOtp = '000000';

        // Mock OTP verification failure
        when(
          () => mockAuth.verifyOTP(
            phone: testPhone,
            token: invalidOtp,
            type: OtpType.sms,
          ),
        ).thenThrow(AuthException('Invalid OTP'));

        final result = await AuthService.verifyOtp(
          phone: testPhone,
          otp: invalidOtp,
        );

        expect(result, isA<Failure<auth_types.AuthData>>());

        if (result is Failure<auth_types.AuthData>) {
          expect(result.error.contains('Invalid'), true);
        }
      });
    });

    group('Session Management', () {
      test('✅ Restore valid session', () async {
        TestPerformance.startTimer('Session Restoration');

        final mockSession = Session(
          accessToken: 'valid-access-token',
          refreshToken: 'valid-refresh-token',
          expiresIn: 3600,
          tokenType: 'bearer',
          user: User(
            id: 'test-user-id',
            appMetadata: {},
            userMetadata: {},
            aud: 'authenticated',
            createdAt: DateTime.now().toIso8601String(),
          ),
        );

        when(() => mockAuth.currentSession).thenReturn(mockSession);

        final result = await AuthService.restoreSession();

        expect(result, true);

        TestPerformance.endTimer(
          'Session Restoration',
          maxExpected: const Duration(milliseconds: 100),
        );
      });

      test('❌ Handle expired session', () async {
        // Mock expired session
        when(() => mockAuth.currentSession).thenReturn(null);

        final result = await AuthService.restoreSession();

        expect(result, false);
      });

      test('✅ Check authentication status', () {
        final mockUser = User(
          id: 'test-user-id',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
        );

        when(() => mockAuth.currentUser).thenReturn(mockUser);

        final isAuthenticated = AuthService.isAuthenticated;

        expect(isAuthenticated, true);
      });

      test('❌ Handle unauthenticated state', () {
        when(() => mockAuth.currentUser).thenReturn(null);

        final isAuthenticated = AuthService.isAuthenticated;

        expect(isAuthenticated, false);
      });

      test('✅ Sign out successfully', () async {
        TestPerformance.startTimer('Sign Out');

        when(() => mockAuth.signOut()).thenAnswer((_) async {});

        await AuthService.signOut();

        verify(() => mockAuth.signOut()).called(1);

        TestPerformance.endTimer(
          'Sign Out',
          maxExpected: const Duration(milliseconds: 500),
        );
      });
    });

    group('Smart OTP Handling', () {
      test('✅ Smart OTP with user creation', () async {
        const testPhone = '+919876543210';

        // Mock initial failure (user not found)
        when(
          () => mockAuth.signInWithOtp(
            phone: testPhone,
            shouldCreateUser: false,
          ),
        ).thenThrow(AuthException('User not found'));

        // Mock successful signup
        when(
          () => mockAuth.signInWithOtp(
            phone: testPhone,
            shouldCreateUser: true,
          ),
        ).thenAnswer(
          (_) async => AuthResponse(
            user: null,
            session: null,
          ),
        );

        final result = await AuthService.sendOtpSmart(testPhone);

        expect(result, isA<auth_types.OtpSent>());

        if (result is auth_types.OtpSent) {
          expect(result.message.contains('created'), true);
        }

        // Verify both calls were made
        verify(
          () => mockAuth.signInWithOtp(
            phone: testPhone,
            shouldCreateUser: false,
          ),
        ).called(1);

        verify(
          () => mockAuth.signInWithOtp(
            phone: testPhone,
            shouldCreateUser: true,
          ),
        ).called(1);
      });
    });

    group('Error Handling', () {
      test('🛡️ Parse authentication errors correctly', () async {
        const testPhone = '+919876543210';

        final errorCases = [
          ('Rate limit exceeded', 'Rate limit'),
          ('Invalid phone number', 'Invalid phone'),
          ('Network error', 'Network'),
          ('Unknown error', 'Unknown'),
        ];

        for (final (error, expectedContains) in errorCases) {
          when(
            () => mockAuth.signInWithOtp(
              phone: testPhone,
              shouldCreateUser: true,
            ),
          ).thenThrow(AuthException(error));

          final result = await AuthService.sendOtp(testPhone);

          expect(result, isA<auth_types.OtpFailed>());

          if (result is auth_types.OtpFailed) {
            expect(
              result.error.toLowerCase().contains(
                expectedContains.toLowerCase(),
              ),
              true,
            );
          }
        }
      });
    });
  });
}
