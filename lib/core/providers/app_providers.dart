import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart';
import '../services/logger.dart';

final _log = Log.component('app');

// Supabase Client Provider
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Dio HTTP Client Provider
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();

  // Add centralized logging interceptor using DebugService
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final stopwatch = Stopwatch()..start();
        options.extra['_start_time'] = stopwatch;

        _log.info(
          '${options.method} ${options.path}',
          {
            'headers': options.headers,
            'query_params': options.queryParameters,
            'request_data': options.data?.toString().length ?? 0,
          },
        );
        handler.next(options);
      },
      onResponse: (response, handler) {
        final stopwatch =
            response.requestOptions.extra['_start_time'] as Stopwatch?;
        final duration = stopwatch?.elapsedMilliseconds;

        _log.info(
          '${response.requestOptions.method} ${response.requestOptions.path}',
          {
            'response_size': response.data?.toString().length ?? 0,
            'duration_ms': duration,
          },
        );
        handler.next(response);
      },
      onError: (error, handler) {
        final stopwatch =
            error.requestOptions.extra['_start_time'] as Stopwatch?;
        final duration = stopwatch?.elapsedMilliseconds;

        _log.error(
          '${error.requestOptions.method} ${error.requestOptions.path}',
          error: error,
          data: {
            'duration_ms': duration,
            'error_type': error.type.toString(),
          },
        );
        handler.next(error);
      },
    ),
  );

  // Add auth interceptor for Supabase
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final supabase = ref.read(supabaseClientProvider);
        final session = supabase.auth.currentSession;

        if (session != null) {
          options.headers['Authorization'] = 'Bearer ${session.accessToken}';
        }

        handler.next(options);
      },
    ),
  );

  return dio;
});

// Auth State Provider
final authStateProvider = StreamProvider<AuthState>((ref) {
  final supabase = ref.read(supabaseClientProvider);
  return supabase.auth.onAuthStateChange;
});

// Current User Provider
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (state) => state.session?.user,
    loading: () => null,
    error: (error, stackTrace) => null,
  );
});

// Loading State Provider (Global)
final loadingStateProvider = StateProvider<bool>((ref) => false);

// Error State Provider (Global)
final errorStateProvider = StateProvider<String?>((ref) => null);

// Theme Mode Provider
final themeModeProvider = StateProvider<bool>(
  (ref) => true,
); // true = dark mode

// Network Status Provider
final networkStatusProvider = StateProvider<bool>(
  (ref) => true,
); // true = connected
