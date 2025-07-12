import 'package:supabase_flutter/supabase_flutter.dart';
import 'result.dart';

/// Authentication result types using modern sealed classes
/// Eliminates nullable chaos and provides compile-time safety

/// Base authentication result
typedef AuthResult = Result<AuthData>;

/// Authentication data container
class AuthData {
  final User user;
  final Session session;
  final String? message;
  
  const AuthData({
    required this.user,
    required this.session,
    this.message,
  });
  
  @override
  String toString() => 'AuthData(user: ${user.id}, message: $message)';
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthData &&
          runtimeType == other.runtimeType &&
          user.id == other.user.id &&
          session.accessToken == other.session.accessToken;
  
  @override
  int get hashCode => user.id.hashCode ^ session.accessToken.hashCode;
}

/// OTP sending result
sealed class OtpResult {
  const OtpResult();
}

/// OTP sent successfully
final class OtpSent extends OtpResult {
  final String phone;
  final String message;
  
  const OtpSent({
    required this.phone,
    this.message = 'OTP sent successfully',
  });
  
  @override
  String toString() => 'OtpSent(phone: $phone, message: $message)';
}

/// OTP sending failed
final class OtpFailed extends OtpResult {
  final String error;
  final String? phone;
  
  const OtpFailed({
    required this.error,
    this.phone,
  });
  
  @override
  String toString() => 'OtpFailed(error: $error, phone: $phone)';
}

/// Profile completion status
sealed class ProfileStatus {
  const ProfileStatus();
}

/// Profile is complete
final class ProfileComplete extends ProfileStatus {
  final Map<String, dynamic> profile;
  
  const ProfileComplete(this.profile);
  
  @override
  String toString() => 'ProfileComplete($profile)';
}

/// Profile is incomplete
final class ProfileIncomplete extends ProfileStatus {
  final List<String> missingFields;
  
  const ProfileIncomplete(this.missingFields);
  
  @override
  String toString() => 'ProfileIncomplete(missing: $missingFields)';
}

/// Authentication state for providers
sealed class AuthState {
  const AuthState();
}

/// User is authenticated
final class Authenticated extends AuthState {
  final User user;
  final Session session;
  final ProfileStatus profileStatus;
  
  const Authenticated({
    required this.user,
    required this.session,
    required this.profileStatus,
  });
  
  @override
  String toString() => 'Authenticated(user: ${user.id}, profile: $profileStatus)';
}

/// User is not authenticated
final class Unauthenticated extends AuthState {
  final String? reason;
  
  const Unauthenticated([this.reason]);
  
  @override
  String toString() => 'Unauthenticated(reason: $reason)';
}

/// Authentication is loading
final class AuthLoading extends AuthState {
  final String? message;
  
  const AuthLoading([this.message]);
  
  @override
  String toString() => 'AuthLoading(message: $message)';
}

/// Authentication error
final class AuthError extends AuthState {
  final String error;
  
  const AuthError(this.error);
  
  @override
  String toString() => 'AuthError(error: $error)';
}

/// Convenience extensions for AuthResult
extension AuthResultExtensions on AuthResult {
  /// Check if authentication was successful
  bool get isAuthenticated => isSuccess;
  
  /// Get user if authenticated
  User? get user => dataOrNull?.user;
  
  /// Get session if authenticated
  Session? get session => dataOrNull?.session;
  
  /// Get auth message
  String? get message => dataOrNull?.message ?? errorOrNull;
}

/// Convenience extensions for OtpResult
extension OtpResultExtensions on OtpResult {
  /// Check if OTP was sent successfully
  bool get isSuccess => this is OtpSent;
  
  /// Get success message
  String? get successMessage => switch (this) {
    OtpSent(message: final message) => message,
    OtpFailed() => null,
  };
  
  /// Get error message
  String? get errorMessage => switch (this) {
    OtpSent() => null,
    OtpFailed(error: final error) => error,
  };
  
  /// Get phone number
  String? get phone => switch (this) {
    OtpSent(phone: final phone) => phone,
    OtpFailed(phone: final phone) => phone,
  };
}

/// Convenience extensions for ProfileStatus
extension ProfileStatusExtensions on ProfileStatus {
  /// Check if profile is complete
  bool get isComplete => this is ProfileComplete;
  
  /// Get missing fields if incomplete
  List<String> get missingFields => switch (this) {
    ProfileComplete() => [],
    ProfileIncomplete(missingFields: final fields) => fields,
  };
  
  /// Get profile data if complete
  Map<String, dynamic>? get profileData => switch (this) {
    ProfileComplete(profile: final profile) => profile,
    ProfileIncomplete() => null,
  };
}
