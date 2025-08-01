# CRUSH.md

Build/Test/Lint
- Deps: flutter pub get
- Codegen: dart run build_runner build --delete-conflicting-outputs
- Fix: dart fix --apply; Format: dart format --set-exit-if-changed .
- Analyze: flutter analyze --no-fatal-infos
- Test all: flutter test; Single file: flutter test test/services/auth_service_test.dart
- Single test by name: flutter test --plain-name "<test name>"
- Integration: flutter test integration_test; Patrol: dart run patrol test
- Clean: flutter clean && flutter pub get

Release/Deploy
- AAB (obfuscated, split debug info): flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info
- APK (size-optimized): flutter build apk --tree-shake-icons --split-per-abi
- Analyze size: flutter build apk --analyze-size
- Web/Windows: flutter build web; flutter build windows

Android/ADB Essentials (Windows paths shown)
- Devices: flutter devices; C:/Users/kunap/AppData/Local/Android/Sdk/platform-tools/adb.exe devices
- Emulator: C:/Users/kunap/AppData/Local/Android/Sdk/emulator/emulator.exe -list-avds; ... -avd Medium_Phone_API_36.0
- App control: adb install -r build/app/outputs/flutter-apk/app-debug.apk; adb shell am start -n com.invoicepe.invoice_pe_app.staging/com.invoicepe.invoice_pe_app.MainActivity; adb shell pm clear com.invoicepe.invoice_pe_app.staging
- Logs: adb logcat -s flutter -v time

Supabase
- Link: supabase link --project-ref ixwwtabatwskafyvlwnm
- Secrets: supabase secrets set --env-file supabase/functions/.env
- Functions: supabase functions deploy; supabase functions logs initiate-payment
- DB: supabase db remote commit

Project Conventions
- Lints: include very_good_analysis; implicit-casts/dynamic disabled; dead_code/unused_* are errors (analysis_options.yaml)
- Imports: prefer package: imports; group dart/third-party/local; avoid unused
- Formatting: use dart format; trailing commas encouraged; line length flexible per current config
- Types: explicit types for public APIs; favor final/const; avoid dynamic calls
- Naming: lowerCamel vars/functions; UpperCamel types; UPPER_SNAKE consts; files snake_case
- Errors: return Result<T> (lib/core/types/result.dart); domain errors via core/error/app_error.dart; log via core/services/logger.dart or smart_logger.dart; no prints in prod
- State: Riverpod; routing via core/router/app_router.dart; follow feature-first structure in lib/features/*
- Models: dart_mappable; rerun build_runner on model changes; ignore generated files
- Env: flutter_dotenv; never commit secrets; see .gitignore
- Testing: flutter_test, mocktail; integration in integration_test/

Docs & Debug
- Start: README.md; DEBUG.md for Windows/ADB and emulator -no-hw-keyboard
- CI mirrors: .github/workflows/flutter-ci.yml (build_runner, dart fix, format, analyze, test); auto-fixes in fix_options.yaml
- Architecture: ARCHITECTURAL_RESILIENCE_PLAN.md; OTP fix: OTP_TIMER_FIX_SOLUTION.md; Performance: PERFORMANCE_FIX_PLAN.md; Play deploy: PLAY_STORE_DEPLOYMENT_PLAN.md

Agent Tips
- Services in lib/core/services/*; models in lib/shared/models/*; providers in lib/core/providers/*; features under lib/features/*