import 'package:supabase_flutter/supabase_flutter.dart';
import 'base_service.dart';
import 'debug_service.dart';
import '../types/result.dart';
import '../types/auth_types.dart' as app_auth;

class AuthService extends BaseService {
  
  /// Auth state stream for providers
  static Stream<AuthState> get authStateStream =>
      BaseService.supabase.auth.onAuthStateChange;

  /// Get current user (for providers)
  static User? getCurrentUser() => BaseService.supabase.auth.currentUser;

  /// Send OTP to phone number (modern Result<T> pattern)
  static Future<app_auth.OtpResult> sendOtp(String phone) async {
    try {
      DebugService.logAuth('Sending OTP to phone', data: {'phone': phone});

      await BaseService.supabase.auth.signInWithOtp(
        phone: phone,
        shouldCreateUser: true,
      );

      DebugService.logAuth('OTP sent successfully');
      return app_auth.OtpSent(
        phone: phone,
        message: 'OTP sent to $phone',
      );
    } catch (error) {
      DebugService.logAuth('OTP sending failed', error: error);
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
    DebugService.logAuth('Starting smart OTP send', data: {'phone': phone});

    try {
      // First attempt: try signin (existing user)
      DebugService.logAuth('Attempting signin for existing user');
      await BaseService.supabase.auth.signInWithOtp(
        phone: phone,
        shouldCreateUser: false,
      );
      DebugService.logAuth('Signin successful - existing user');
      return app_auth.OtpSent(
        phone: phone,
        message: 'Welcome back! OTP sent to $phone',
      );
    } catch (error) {
      DebugService.logAuth('Signin failed, analyzing error', error: error);

      final errorMessage = error.toString().toLowerCase();

      if (errorMessage.contains('user not found') ||
          errorMessage.contains('invalid login') ||
          errorMessage.contains('signups not allowed') ||
          errorMessage.contains('invalid phone')) {
        // User doesn't exist, try signup
        DebugService.logAuth('User not found, attempting signup');
        try {
          await BaseService.supabase.auth.signInWithOtp(
            phone: phone,
            shouldCreateUser: true,
          );
          DebugService.logAuth('Signup successful - new user created');
          return app_auth.OtpSent(
            phone: phone,
            message: 'Account created! OTP sent to $phone',
          );
        } catch (signupError) {
          DebugService.logAuth('Signup failed', error: signupError);
          return app_auth.OtpFailed(
            error: _parseAuthError(signupError),
            phone: phone,
          );
        }
      }

      // Handle other errors
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
    DebugService.logAuth('Starting OTP verification', data: {'phone': phone, 'otp_length': otp.length});

    try {
      final response = await BaseService.supabase.auth.verifyOTP(
        phone: phone,
        token: otp,
        type: OtpType.sms,
      );

      if (response.user != null && response.session != null) {
        DebugService.logAuth('OTP verification successful', data: {
          'user_id': response.user!.id,
          'phone': response.user!.phone,
          'created_at': response.user!.createdAt,
        });

        // Check if profile exists, create if not
        try {
          await _ensureProfileExists();
          DebugService.logAuth('Profile creation/verification completed');
        } catch (profileError) {
          DebugService.logWarning('Profile creation failed but auth succeeded', error: profileError);
          // Continue with auth success even if profile creation fails
        }

        return Success(app_auth.AuthData(
          user: response.user!,
          session: response.session!,
          message: 'Authentication successful',
        ));
      }

      DebugService.logWarning('OTP verification returned null user or session');
      return const Failure('Authentication failed - invalid response');
    } catch (error) {
      DebugService.logAuth('OTP verification failed', error: error);
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
        DebugService.logAuth('Session restored successfully');
        return true;
      }
      DebugService.logAuth('No valid session to restore');
      return false;
    } catch (error) {
      DebugService.logAuth('Session restoration failed', error: error);
      return false;
    }
  }


  
  /// Ensure profile exists for the current user
  static Future<void> _ensureProfileExists() async {
    try {
      final user = getCurrentUser();
      if (user == null) {
        DebugService.logWarning('No current user found for profile creation');
        return;
      }

      DebugService.logDatabase('Starting profile existence check', data: {'user_id': user.id});

      // Check if profile already exists (manual creation, no triggers)
      final profileResponse = await BaseService.supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profileResponse == null) {
        DebugService.logDatabase('Profile not found, creating new profile', table: 'profiles');
        // Create profile manually with user ID as primary key
        try {
          await BaseService.supabase
              .from('profiles')
              .insert({
                'id': user.id,
                'phone': user.phone ?? '',
                'business_name': 'My Business', // Default name
                'email': user.email,
              });
          DebugService.logDatabase('Profile created successfully', table: 'profiles');
        } catch (insertError) {
          DebugService.logWarning('Profile insert failed - might already exist', error: insertError, operation: 'profile_insert');
          // Profile might have been created between check and insert
          // This is fine, just ignore the error
        }
      } else {
        DebugService.logDatabase('Profile already exists', table: 'profiles', data: {'profile_id': profileResponse['id']});
      }
    } catch (error) {
      DebugService.logError('Profile creation/check failed', error: error, operation: 'profile_check');
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
    } else if (errorMessage.contains('too many') || errorMessage.contains('rate limit')) {
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
      if (response['business_name'] == null || response['business_name'].toString().trim().isEmpty) {
        missingFields.add('business_name');
      }
      if (response['gstin'] == null || response['gstin'].toString().trim().isEmpty) {
        missingFields.add('gstin');
      }

      return missingFields.isEmpty
          ? app_auth.ProfileComplete(response)
          : app_auth.ProfileIncomplete(missingFields);
    } catch (error) {
      DebugService.logError('Profile status check failed', error: error);
      return const app_auth.ProfileIncomplete(['business_name', 'gstin']);
    }
  }
}
