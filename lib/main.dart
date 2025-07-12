import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/providers/app_providers.dart';
import 'core/services/debug_service.dart';
import 'core/services/payment_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables first
  try {
    await dotenv.load(fileName: '.env');
    debugPrint('✅ Environment variables loaded successfully');
  } catch (e) {
    debugPrint('⚠️ Failed to load .env file: $e');
    debugPrint('📝 Continuing with default values...');
  }

  // Initialize Debug Service
  DebugService.initialize();
  DebugService.logInfo('🚀 InvoicePe App Starting...');
  DebugService.logInfo('🌍 Environment: ${AppConstants.environment}');
  DebugService.logInfo('🔧 Debug Mode: ${AppConstants.debugMode}');

  // Initialize Supabase with centralized logging
  DebugService.logInfo('🔧 Initializing Supabase...');
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
    debug: false, // Use our centralized DebugService instead
  );
  DebugService.logInfo('✅ Supabase initialization completed');

  // Initialize PhonePe SDK
  try {
    await PaymentService.initializePhonePe();
    DebugService.logInfo('✅ PhonePe SDK initialization completed');
  } catch (e) {
    DebugService.logError('PhonePe SDK initialization failed', error: e);
    // Continue app startup even if PhonePe fails
  }

  // Try to restore existing session with enhanced logic
  try {
    // Enhanced session restoration will be handled by AuthService
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      // Session exists, try to refresh it
      await Supabase.instance.client.auth.refreshSession();
    }
  } catch (e) {
    // Session restoration failed, user will need to login again
    // This is handled gracefully by the splash screen
  }

  runApp(
    const ProviderScope(
      child: InvoicePeApp(),
    ),
  );
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


