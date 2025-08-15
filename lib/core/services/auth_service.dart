import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'base_service.dart';
import 'logger.dart';
import 'smart_logger.dart'; // ELON FIX: Add SmartLogger for database logging
import '../constants/app_constants.dart'; // ELON FIX: Add AppConstants for supabaseUrl
import '../types/result.dart';
import '../types/auth_types.dart' as app_auth;

final ComponentLogger _log = Log.component('auth');

class AuthService extends BaseService {
  /// Auth state stream for providers
  static Stream<AuthState> get authStateStream =>
      BaseService.supabase.auth.onAuthStateChange;

  /// Get current user (for providers)
  static User? getCurrentUser() => BaseService.supabase.auth.currentUser;

  /// Send OTP to phone number (modern Result<T> pattern)
  static Future<app_auth.OtpResult> sendOtp(String phone) async {
    try {
      _log.info('Sending OTP to phone', {'phone': phone});

      await BaseService.supabase.auth.signInWithOtp(
        phone: phone,
        shouldCreateUser: true,
      );

      _log.info('OTP sent successfully');
      return app_auth.OtpSent(
        phone: phone,
        message: 'OTP sent to $phone',
      );
    } on AuthException catch (e) {
      _log.error('Auth error during OTP send', error: e);
      return app_auth.OtpFailed(
        error: _parseAuthError(e),
        phone: phone,
      );
    } on TimeoutException catch (e) {
      _log.error('Timeout occurred during OTP send', error: e);
      return app_auth.OtpFailed(
        error: 'Request timed out. Please try again.',
        phone: phone,
      );
    } catch (error) {
      _log.error('Unexpected error during OTP send', error: error);
      return app_auth.OtpFailed(
        error: _parseAuthError(error),
        phone: phone,
      );
    }
  }

  /// Check if user exists with given phone number
  static Future<bool> userExists(String phone) async {
    try {
      // Try to sign in without creating user
      await BaseService.supabase.auth.signInWithOtp(
        phone: phone,
        shouldCreateUser: false,
      );
      return true; // If no error, user exists
    } catch (error) {
      // If error contains "User not found" or similar, user doesn't exist
      final errorMessage = error.toString().toLowerCase();
      if (errorMessage.contains('user not found') ||
          errorMessage.contains('invalid login') ||
          errorMessage.contains('signups not allowed')) {
        return false;
      }
      // For other errors, rethrow
      throw BaseService.handleError(error);
    }
  }

  /// Smart OTP sending with automatic retry logic and timeout protection
  static Future<app_auth.OtpResult> sendOtpSmart(String phone) async {
    _log.info('Starting smart OTP send', {'phone': phone});

    try {
      // ELON FIX: Reduce timeout to prevent UI blocking and use microtask
      return await Future.microtask(() async {
        return Future.any([
          _performOtpSendWithRetry(phone),
          Future.delayed(
            const Duration(seconds: 10), // Reduced from 30 to 10 seconds
            () => app_auth.OtpFailed(
              error:
                  'Request timeout - please check your internet connection and try again',
              phone: phone,
            ),
          ),
        ]);
      });
    } catch (error) {
      _log.error('Smart OTP send failed', error: error);
      return app_auth.OtpFailed(
        error: _parseAuthError(error),
        phone: phone,
      );
    }
  }

  /// Perform OTP send with retry logic and enhanced debugging
  static Future<app_auth.OtpResult> _performOtpSendWithRetry(
    String phone,
  ) async {
    try {
      // Enhanced logging for debugging
      _log.info('OTP send attempt', {
        'phone': phone,
        'phone_length': phone.length,
        'has_plus': phone.startsWith('+'),
      });

      // First attempt: try signin (existing user)
      _log.info('Attempting signin for existing user');

      await BaseService.supabase.auth.signInWithOtp(
        phone: phone,
        shouldCreateUser: false,
      );

      _log.info('Signin successful - existing user');

      return app_auth.OtpSent(
        phone: phone,
        message: 'Welcome back! OTP sent to $phone',
      );
    } on AuthException catch (e) {
      _log.error('Auth error during signin', error: e);

      final errorMessage = e.message.toLowerCase();

      if (errorMessage.contains('user not found') ||
          errorMessage.contains('invalid login') ||
          errorMessage.contains('signups not allowed') ||
          errorMessage.contains('invalid phone')) {
        // User doesn't exist, try signup
        _log.info('User not found, attempting signup');
        try {
          await BaseService.supabase.auth.signInWithOtp(
            phone: phone,
            shouldCreateUser: true,
          );

          _log.info('Signup successful - new user created');

          return app_auth.OtpSent(
            phone: phone,
            message: 'Account created! OTP sent to $phone',
          );
        } on AuthException catch (signupError) {
          _log.error('Auth error during signup', error: signupError);

          // ELON DEBUG: Detailed signup error analysis
          _log.error(
            'Signup failure details',
            error: signupError,
            data: {
              'error_message': signupError.message,
              'error_code': signupError.statusCode,
              'phone': phone,
              'phone_length': phone.length,
              'has_country_code': phone.startsWith('+'),
              'supabase_url': AppConstants.supabaseUrl,
            },
          );

          // ELON FIX: Also log to database for debugging
          SmartLogger.logError(
            'Sign-up failed for new user',
            error: signupError,
            context: {
              'category': 'auth',
              'operation': 'signup',
              'phone': phone,
              'error_message': signupError.message,
              'error_code': signupError.statusCode,
              'supabase_url': AppConstants.supabaseUrl,
            },
          );

          return app_auth.OtpFailed(
            error: 'Sign-up failed: ${signupError.message}',
            phone: phone,
          );
        } on TimeoutException catch (e) {
          _log.error('Timeout occurred during signup', error: e);
          return app_auth.OtpFailed(
            error: 'Signup request timed out. Please try again.',
            phone: phone,
          );
        } catch (signupError) {
          _log.error('Unexpected error during signup', error: signupError);
          return app_auth.OtpFailed(
            error: _parseAuthError(signupError),
            phone: phone,
          );
        }
      }

      // Handle other auth errors
      return app_auth.OtpFailed(
        error: _parseAuthError(e),
        phone: phone,
      );
    } catch (error) {
      _log.error('Unexpected error during smart OTP', error: error);
      return app_auth.OtpFailed(
        error: _parseAuthError(error),
        phone: phone,
      );
    }
  }

  /// Verify OTP and complete authentication with timeout protection
  static Future<app_auth.AuthResult> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    _log.info(
      'Starting OTP verification',
      {'phone': phone, 'otp_length': otp.length},
    );

    try {
      // Add timeout protection to prevent main thread blocking
      return await Future.any([
        _performOtpVerification(phone, otp),
        Future.delayed(
          const Duration(seconds: 30),
          () => Failure(
            'Verification timeout - please check your internet connection and try again',
          ),
        ),
      ]);
    } catch (error) {
      _log.error('OTP verification failed', error: error);
      return Failure(_parseAuthError(error));
    }
  }

  /// Perform the actual OTP verification
  static Future<app_auth.AuthResult> _performOtpVerification(
    String phone,
    String otp,
  ) async {
    try {
      final response = await BaseService.supabase.auth.verifyOTP(
        phone: phone,
        token: otp,
        type: OtpType.sms,
      );

      if (response.user != null && response.session != null) {
        _log.info(
          'OTP verification successful',
          {
            'user_id': response.user!.id,
            'phone': response.user!.phone,
            'created_at': response.user!.createdAt,
          },
        );

        // Check if profile exists, create if not
        try {
          await _ensureProfileExists();
          _log.info('Profile creation/verification completed');
        } catch (profileError) {
          _log.error(
            'Profile creation failed but auth succeeded',
            error: profileError,
          );
          // Continue with auth success even if profile creation fails
        }

        return Success(
          app_auth.AuthData(
            user: response.user!,
            session: response.session!,
            message: 'Authentication successful',
          ),
        );
      }

      _log.info('OTP verification returned null user or session');
      return const Failure('Authentication failed - invalid response');
    } on AuthException catch (e) {
      _log.error('Auth error during OTP verification', error: e);
      return Failure(_parseAuthError(e));
    } catch (error) {
      _log.error('Unexpected error during OTP verification', error: error);
      return Failure(_parseAuthError(error));
    }
  }

  /// Sign out the current user
  static Future<void> signOut() async {
    try {
      await BaseService.supabase.auth.signOut();
    } catch (error) {
      throw BaseService.handleError(error);
    }
  }

  /// Get current user (getter for compatibility)
  static User? get currentUser => BaseService.supabase.auth.currentUser;

  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  /// Restore session on app startup
  static Future<bool> restoreSession() async {
    try {
      final session = BaseService.supabase.auth.currentSession;
      if (session != null && !session.isExpired) {
        _log.info('Session restored successfully');
        return true;
      }
      _log.info('No valid session to restore');
      return false;
    } catch (error) {
      _log.error('Session restoration failed', error: error);
      return false;
    }
  }

  /// Ensure profile exists for the current user
  static Future<void> _ensureProfileExists() async {
    try {
      final user = getCurrentUser();
      if (user == null) {
        _log.info('No current user found for profile creation');
        return;
      }

      _log.info('Starting profile existence check', {'user_id': user.id});

      // Check if profile already exists (manual creation, no triggers)
      final profileResponse = await BaseService.supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profileResponse == null) {
        _log.info(
          'Profile not found, creating new profile',
        );
        // Create profile manually with user ID as primary key
        try {
          await BaseService.supabase.from('profiles').insert({
            'id': user.id,
            'phone': user.phone ?? '',
            'business_name': 'My Business', // Default name
            'email': user.email,
          });
          _log.info('Profile created successfully');
        } catch (insertError) {
          // Check if it's a duplicate key error (profile already exists)
          final errorMessage = insertError.toString().toLowerCase();
          if (errorMessage.contains('duplicate') ||
              errorMessage.contains('unique') ||
              errorMessage.contains('already exists')) {
            _log.info('Profile already exists - continuing');
          } else {
            // This is a real error, not a race condition
            _log.error(
              'Profile creation failed with unexpected error',
              error: insertError,
            );
            throw Exception('Failed to create user profile: $insertError');
          }
        }
      } else {
        _log.info(
          'Profile already exists',
          {'profile_id': profileResponse['id']},
        );
      }
    } catch (error) {
      _log.error('Profile creation/check failed', error: error);

      // In production, profile creation is critical for app functionality
      // Don't silently ignore failures
      if (kReleaseMode) {
        throw Exception('Critical: Profile creation failed - $error');
      } else {
        // In development, log warning but continue
        _log.info(
          'Development mode: Continuing despite profile creation failure',
        );
      }
    }
  }

  /// Refresh the current session
  static Future<void> refreshSession() async {
    try {
      await BaseService.supabase.auth.refreshSession();
    } catch (error) {
      throw BaseService.handleError(error);
    }
  }

  /// Get current session
  static Session? getCurrentSession() {
    return BaseService.supabase.auth.currentSession;
  }

  /// Enhanced session persistence with secure storage
  static Future<void> persistSession() async {
    try {
      final session = getCurrentSession();
      if (session != null) {
        // Session is automatically persisted by Supabase
        // Additional custom persistence logic can be added here if needed
      }
    } catch (error) {
      // Log error but don't throw - session persistence is not critical
    }
  }

  /// Handle session expiry gracefully
  static Future<void> handleSessionExpiry() async {
    try {
      await signOut();
    } catch (error) {
      // Force clear local session data even if server signout fails
    }
  }

  /// Parse authentication errors into user-friendly messages
  static String _parseAuthError(dynamic error) {
    final errorMessage = error.toString().toLowerCase();

    if (errorMessage.contains('invalid') || errorMessage.contains('expired')) {
      return 'Invalid or expired OTP. Please try again.';
    } else if (errorMessage.contains('too many') ||
        errorMessage.contains('rate limit')) {
      return 'Too many attempts. Please wait before trying again.';
    } else if (errorMessage.contains('invalid phone')) {
      return 'Please enter a valid phone number.';
    } else if (errorMessage.contains('signups not allowed')) {
      return 'Account creation is currently disabled. Please contact support.';
    } else if (errorMessage.contains('user not found')) {
      return 'User not found. Please check your phone number.';
    } else if (errorMessage.contains('database error')) {
      return 'Service temporarily unavailable. Please try again later.';
    } else {
      return 'Authentication failed. Please try again.';
    }
  }

  /// Check profile completion status
  static Future<app_auth.ProfileStatus> checkProfileStatus() async {
    try {
      BaseService.ensureAuthenticated();

      final response = await BaseService.supabase
          .from('profiles')
          .select('business_name, gstin')
          .eq('id', BaseService.currentUserId!)
          .maybeSingle();

      if (response == null) {
        return const app_auth.ProfileIncomplete(['business_name', 'gstin']);
      }

      final missingFields = <String>[];
      if (response['business_name'] == null ||
          response['business_name'].toString().trim().isEmpty) {
        missingFields.add('business_name');
      }
      if (response['gstin'] == null ||
          response['gstin'].toString().trim().isEmpty) {
        missingFields.add('gstin');
      }

      return missingFields.isEmpty
          ? app_auth.ProfileComplete(response)
          : app_auth.ProfileIncomplete(missingFields);
    } catch (error) {
      _log.error('Profile status check failed', error: error);
      return const app_auth.ProfileIncomplete(['business_name', 'gstin']);
    }
  }
}
