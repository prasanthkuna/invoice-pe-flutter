import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/providers/app_providers.dart';
import 'core/services/logger.dart';
import 'core/services/environment_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize AI-friendly logging
  Log.init();

  // CRITICAL PATH: Only absolute essentials before showing UI
  // 1. Environment (fast, local)
  await EnvironmentService.initialize();

  // 2. Minimal Supabase init (no session check)
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
    debug: false,
  );

  // 3. Show UI immediately!
  runApp(
    const ProviderScope(
      child: InvoicePeApp(),
    ),
  );

  // DEFERRED: Everything else happens after first frame
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    // Log app startup with structured data
    Log.component('app').info('startup', {
      'environment': AppConstants.environment,
      'debug_mode': AppConstants.debugMode,
      'version': 'v1.0.0',
    });
    
    // Add breadcrumb for tracking
    Log.addBreadcrumb('app.main.post_frame_callback');
    
    // Defer PhonePe initialization to first payment
    // This saves ~500ms on startup
    
    // Session restoration happens in splash screen
    // No need to block here
  });
}

class InvoicePeApp extends ConsumerWidget {
  const InvoicePeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final isDarkMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // Theme Configuration (UX Requirements)
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // Router Configuration (TRD Requirements)
      routerConfig: router,
    );
  }
}
