/// Modern Result<T> pattern for type-safe error handling
/// Eliminates nullable chaos and provides compile-time safety
/// 
/// Usage:
/// ```dart
/// final result = await someOperation();
/// switch (result) {
///   case Success(data: final data) => handleSuccess(data);
///   case Failure(error: final error) => handleError(error);
/// }
/// ```

/// Base sealed class for Result pattern
sealed class Result<T> {
  const Result();
  
  /// Check if result is successful
  bool get isSuccess => this is Success<T>;
  
  /// Check if result is failure
  bool get isFailure => this is Failure<T>;
  
  /// Get data if success, null if failure
  T? get dataOrNull => switch (this) {
    Success(data: final data) => data,
    Failure() => null,
  };
  
  /// Get error if failure, null if success
  String? get errorOrNull => switch (this) {
    Success() => null,
    Failure(error: final error) => error,
  };
  
  /// Transform success data, keep failure unchanged
  Result<R> map<R>(R Function(T data) transform) => switch (this) {
    Success(data: final data) => Success(transform(data)),
    Failure(error: final error) => Failure(error),
  };
  
  /// Handle both success and failure cases
  R fold<R>(
    R Function(T data) onSuccess,
    R Function(String error) onFailure,
  ) => switch (this) {
    Success(data: final data) => onSuccess(data),
    Failure(error: final error) => onFailure(error),
  };
}

/// Success case with data
final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
  
  @override
  String toString() => 'Success($data)';
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> && runtimeType == other.runtimeType && data == other.data;
  
  @override
  int get hashCode => data.hashCode;
}

/// Failure case with error message
final class Failure<T> extends Result<T> {
  final String error;
  const Failure(this.error);
  
  @override
  String toString() => 'Failure($error)';
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T> && runtimeType == other.runtimeType && error == other.error;
  
  @override
  int get hashCode => error.hashCode;
}

/// Convenience constructors
extension ResultConstructors<T> on Result<T> {
  /// Create success result
  static Result<T> success<T>(T data) => Success(data);
  
  /// Create failure result
  static Result<T> failure<T>(String error) => Failure(error);
  
  /// Create result from nullable value
  static Result<T> fromNullable<T>(T? value, String errorMessage) =>
      value != null ? Success(value) : Failure(errorMessage);
}

/// Async Result helpers
extension AsyncResult<T> on Future<Result<T>> {
  /// Transform async result
  Future<Result<R>> mapAsync<R>(Future<R> Function(T data) transform) async {
    final result = await this;
    return switch (result) {
      Success(data: final data) => Success(await transform(data)),
      Failure(error: final error) => Failure(error),
    };
  }
  
  /// Handle async result
  Future<R> foldAsync<R>(
    Future<R> Function(T data) onSuccess,
    Future<R> Function(String error) onFailure,
  ) async {
    final result = await this;
    return switch (result) {
      Success(data: final data) => await onSuccess(data),
      Failure(error: final error) => await onFailure(error),
    };
  }
}

/// Exception handling helpers
extension ResultFromException<T> on Result<T> {
  /// Create result from potentially throwing operation
  static Future<Result<T>> fromAsync<T>(Future<T> Function() operation) async {
    try {
      final data = await operation();
      return Success(data);
    } catch (error) {
      return Failure(error.toString());
    }
  }
  
  /// Create result from synchronous operation
  static Result<T> fromSync<T>(T Function() operation) {
    try {
      final data = operation();
      return Success(data);
    } catch (error) {
      return Failure(error.toString());
    }
  }
}
