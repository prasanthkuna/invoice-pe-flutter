import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'base_service.dart';
import 'logger.dart';
import '../types/result.dart';
import '../types/auth_types.dart' as app_auth;

final _log = Log.component('auth');

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

  /// Smart OTP sending with automatic retry logic (modern Result<T> pattern)
  static Future<app_auth.OtpResult> sendOtpSmart(String phone) async {
    _log.info('Starting smart OTP send', {'phone': phone});

    try {
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
          return app_auth.OtpFailed(
            error: _parseAuthError(signupError),
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

  /// Verify OTP and complete authentication (modern Result<T> pattern)
  static Future<app_auth.AuthResult> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    _log.info(
      'Starting OTP verification',
      {'phone': phone, 'otp_length': otp.length},
    );

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
          _log.error('Profile creation failed but auth succeeded', error: profileError);
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
          _log.info(
            'Profile insert failed - might already exist',
          );
          // Profile might have been created between check and insert
          // This is fine, just ignore the error
        }
      } else {
        _log.info(
          'Profile already exists',
          {'profile_id': profileResponse['id']},
        );
      }
    } catch (error) {
      _log.info(
        'Profile creation/check failed',
      );
      // Log error but don't throw - profile creation can be done later
      // Profile creation is handled by database triggers, so this is not critical
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
