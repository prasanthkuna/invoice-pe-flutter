import 'package:supabase_flutter/supabase_flutter.dart';

/// Base service class with common functionality for all data services
abstract class BaseService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  
  /// Get the current Supabase client instance
  static SupabaseClient get supabase => _supabase;
  
  /// Get the current authenticated user ID
  static String? get currentUserId => _supabase.auth.currentUser?.id;
  
  /// Check if user is authenticated
  static bool get isAuthenticated => currentUserId != null;
  
  /// Ensure user is authenticated, throw exception if not
  static void ensureAuthenticated() {
    if (!isAuthenticated) {
      throw Exception('User not authenticated');
    }
  }
  
  /// Handle Supabase errors and convert to user-friendly messages
  static Exception handleError(Object error) {
    if (error is PostgrestException) {
      switch (error.code) {
        case '23505': // Unique constraint violation
          return Exception('Record already exists');
        case '23503': // Foreign key constraint violation
          return Exception('Referenced record not found');
        case '42501': // Insufficient privilege (RLS)
          return Exception('Access denied');
        default:
          return Exception('Database error: ${error.message}');
      }
    }
    
    if (error is AuthException) {
      return Exception('Authentication error: ${error.message}');
    }
    
    return Exception('Unexpected error: $error');
  }
}
