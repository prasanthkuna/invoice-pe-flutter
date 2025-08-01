# InvoicePe Debug Guide - Tesla Standard 🚀

> "The best debug is no debug. Automate everything. Fix root causes."

## Critical Info
- **Supabase Project**: ixwwtabatwskafyvlwnm (ap-southeast-1)
- **Flutter**: 3.32.6
- **Security**: 3-Tier Architecture (App/Edge/Auto)
- **Platforms**: Android/iOS/Web/Windows/macOS/Linux
- **Beta Mode**: Mock payments enabled (MOCK_PAYMENT_MODE=true)

## 🚨 CRITICAL RELEASE BUILD FIX (SOLVED)

### "Cannot use 'ref' after the widget was disposed" Error
**Issue**: Release builds crash with Riverpod ref errors after OTP verification
**Root Cause**: ref.read() called after async operations in release builds (timing difference vs debug)
**Solution**: Store notifier references BEFORE async operations (Official Riverpod pattern)

```dart
// ❌ WRONG - Crashes in release builds
async function() {
  await someOperation();
  ref.read(provider.notifier).state = value; // Widget disposed during await
}

// ✅ CORRECT - Works in all builds
async function() {
  final notifier = ref.read(provider.notifier); // Store BEFORE async
  await someOperation();
  notifier.state = value; // Use stored notifier
}
```

**Fixed Files**: phone_auth_screen.dart, otp_screen.dart, quick_payment_screen.dart
**Status**: ✅ RESOLVED - 38.9MB release build working perfectly
**Source**: [Riverpod GitHub Discussion #3043](https://github.com/rrousselGit/riverpod/discussions/3043)

## 🎯 The Only Commands You Need

### 0. CRITICAL: Analyze Before Building (Elon Standard)
```powershell
# ALWAYS analyze changed files before building to catch errors early
dart analyze lib/features/payment/presentation/screens/
dart analyze lib/core/services/payment_service.dart

# Quick analysis of specific files
flutter analyze lib/path/to/changed_file.dart

# Fix any issues found before proceeding to build
```

### 1. Nuclear Reset (Fixes 99% of Issues)
```powershell
# Complete clean install - Windows PowerShell
flutter clean
Remove-Item pubspec.lock -ErrorAction SilentlyContinue
Remove-Item .dart_tool -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item .flutter-plugins -ErrorAction SilentlyContinue
Remove-Item .flutter-plugins-dependencies -ErrorAction SilentlyContinue
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# Automated fixes - removes unused imports, dead code, etc.
dart fix --apply

# Format code
dart format .

# Final analysis
flutter analyze

# Generate app icons (if changed)
dart run flutter_launcher_icons
```

### 1.5. Quick Fix (Just remove unused imports)
```powershell
# Fast fix for common issues
dart fix --apply --code=unused_import
dart fix --apply --code=dead_code
dart fix --apply --code=unused_local_variable
```

### 2. Device Management & ADB Commands
```powershell
# List all devices
flutter devices
C:\Users\kunap\AppData\Local\Android\Sdk\platform-tools\adb.exe devices

# Run on specific device
flutter run -d windows     # Windows desktop
flutter run -d chrome      # Web browser
flutter run -d emulator-5554  # Android emulator
flutter run -d [device-id]    # Your connected device
```

### 2.1. Emulator Management (Essential Commands)
```powershell
# List available AVDs
C:\Users\kunap\AppData\Local\Android\Sdk\emulator\emulator.exe -list-avds

# Start emulator (our main AVD)
C:\Users\kunap\AppData\Local\Android\Sdk\emulator\emulator.exe -avd Medium_Phone_API_36.0

# Check emulator status
C:\Users\kunap\AppData\Local\Android\Sdk\platform-tools\adb.exe devices

# Kill all emulators (if stuck)
C:\Users\kunap\AppData\Local\Android\Sdk\platform-tools\adb.exe kill-server
C:\Users\kunap\AppData\Local\Android\Sdk\platform-tools\adb.exe start-server
```

### 2.2. App Management (InvoicePe Specific)
```powershell
# Install/Update app
C:\Users\kunap\AppData\Local\Android\Sdk\platform-tools\adb.exe install -r build\app\outputs\flutter-apk\app-debug.apk

# Launch InvoicePe app
C:\Users\kunap\AppData\Local\Android\Sdk\platform-tools\adb.exe shell am start -n com.invoicepe.invoice_pe_app.staging/com.invoicepe.invoice_pe_app.MainActivity

# Force stop app (if frozen)
C:\Users\kunap\AppData\Local\Android\Sdk\platform-tools\adb.exe shell am force-stop com.invoicepe.invoice_pe_app.staging

# Clear app data (reset app)
C:\Users\kunap\AppData\Local\Android\Sdk\platform-tools\adb.exe shell pm clear com.invoicepe.invoice_pe_app.staging

# Uninstall app
C:\Users\kunap\AppData\Local\Android\Sdk\platform-tools\adb.exe uninstall com.invoicepe.invoice_pe_app.staging
```

### 2.3. Debugging Commands
```powershell
# View app logs (real-time)
C:\Users\kunap\AppData\Local\Android\Sdk\platform-tools\adb.exe logcat -s flutter -v time

# View app logs (filtered)
C:\Users\kunap\AppData\Local\Android\Sdk\platform-tools\adb.exe logcat | findstr "InvoicePe"

# Check app info
C:\Users\kunap\AppData\Local\Android\Sdk\platform-tools\adb.exe shell pm list packages | findstr invoice

# Take screenshot
C:\Users\kunap\AppData\Local\Android\Sdk\platform-tools\adb.exe shell screencap -p /sdcard/screenshot.png
C:\Users\kunap\AppData\Local\Android\Sdk\platform-tools\adb.exe pull /sdcard/screenshot.png
```

### 3. PATH Fix (If Flutter/Supabase Not Found)
```powershell
# Flutter PATH
$env:PATH = "C:\tools\flutter\bin;" + $env:PATH

# Supabase PATH (Scoop installation)
$env:PATH = "$env:USERPROFILE\scoop\apps\supabase\current;" + $env:PATH
```

### 3. Security Check
```powershell
# Verify no credential leaks
Select-String -Path "lib\**\*.dart" -Pattern "PHONEPE_|TWILIO_|JWT_SECRET"
```

### 4. Fix Supabase PATH (One-time setup)
```powershell
# Add Supabase to global PATH (run once)
[Environment]::SetEnvironmentVariable("PATH", [Environment]::GetEnvironmentVariable("PATH", "User") + ";$env:USERPROFILE\scoop\apps\supabase\current", "User")

# Restart PowerShell or refresh PATH
$env:PATH = [Environment]::GetEnvironmentVariable("PATH", "User")
```

### 5. Supabase Edge Functions
```powershell
# Deploy secrets
supabase secrets set --env-file supabase/functions/.env

# Deploy functions
supabase functions deploy

# Check logs
supabase functions logs initiate-payment
```

### 6. Efficient Development Workflow (Elon Standard)
```powershell
# STEP 1: Analyze first (catch errors early)
dart analyze lib/path/to/changed_files.dart

# STEP 2: Hot reload mode (fastest development)
flutter run -d emulator-5554

# STEP 3: Only build when ready for testing
flutter build apk --debug
adb install -r build\app\outputs\flutter-apk\app-debug.apk

# STEP 4: Production build
flutter build apk --release
```

## Fix Sequence (Copy & Run)
```powershell
# The Complete Fix - 2 minutes total
flutter clean
flutter pub get
dart fix --apply
dart format .

# CRITICAL: Analyze before building
flutter analyze

# Only run tests if analysis passes
flutter test
```

## Beta Testing Commands (Elon Workflow)
```powershell
# STEP 1: Analyze first
dart analyze lib/

# STEP 2: Hot reload development
flutter run -d emulator-5554

# STEP 3: Test mock payments (default mode)
# App runs in mock mode by default - no environment changes needed

# STEP 4: Build only when ready
flutter build apk --debug

# STEP 5: Production builds
flutter build apk --release
flutter build appbundle
flutter build web
flutter build windows
```

## 🎯 BUILD OPTIMIZATION STRATEGY (SOLVED)

### Release Build Configuration
**Issue**: Aggressive R8 optimization caused app hangs in release builds
**Solution**: Disabled R8 minification for stable 38.9MB builds

```kotlin
// android/app/build.gradle.kts - Release configuration
release {
    isMinifyEnabled = false     // DISABLED - was causing main thread hang
    isShrinkResources = false   // DISABLED - to isolate the issue
    isDebuggable = false
    // ProGuard disabled for now
}
```

**Results**:
- ✅ Working release build: 38.9MB (arm64-v8a)
- ✅ No app hangs or crashes
- ✅ All features functional
- 🎯 Target achieved: Under 40MB for fintech app

### Size Optimization Achieved
- **Font tree-shaking**: 99.7% reduction (257KB → 848B)
- **Icon optimization**: 99.6% reduction (1.6MB → 6.6KB)
- **Split APKs**: Device-specific downloads ~25-30MB
- **App Bundle**: Play Store auto-optimization

## Emergency Fixes (Copy & Paste)

### Emulator Not Responding
```powershell
# Nuclear option - restart everything
C:\Users\kunap\AppData\Local\Android\Sdk\platform-tools\adb.exe kill-server
taskkill /f /im qemu-system-x86_64.exe
C:\Users\kunap\AppData\Local\Android\Sdk\platform-tools\adb.exe start-server
C:\Users\kunap\AppData\Local\Android\Sdk\emulator\emulator.exe -avd Medium_Phone_API_36.0
```

### App Stuck/Frozen
```powershell
# Force restart app
C:\Users\kunap\AppData\Local\Android\Sdk\platform-tools\adb.exe shell am force-stop com.invoicepe.invoice_pe_app.staging
C:\Users\kunap\AppData\Local\Android\Sdk\platform-tools\adb.exe shell am start -n com.invoicepe.invoice_pe_app.staging/com.invoicepe.invoice_pe_app.MainActivity
```

### Complete Reset (Nuclear Option)
```powershell
# Reset everything - use when nothing works
C:\Users\kunap\AppData\Local\Android\Sdk\platform-tools\adb.exe shell pm clear com.invoicepe.invoice_pe_app.staging
flutter clean
flutter pub get
flutter build apk --debug
C:\Users\kunap\AppData\Local\Android\Sdk\platform-tools\adb.exe install -r build\app\outputs\flutter-apk\app-debug.apk
```

## Common Fixes

### Import Errors
```dart
// Before
import '../test/utils/test_helpers.dart';

// After
import '../test/utils/test_helpers.dart' as test_helpers;
```

### Analyze Hanging
```powershell
taskkill /f /im dart.exe
flutter clean && flutter pub get
```

### Supabase Connection
```powershell
supabase link --project-ref ixwwtabatwskafyvlwnm
supabase db remote commit
supabase functions deploy
```

### ADB Connection Issues
```powershell
# ADB not recognizing device
C:\Users\kunap\AppData\Local\Android\Sdk\platform-tools\adb.exe kill-server
C:\Users\kunap\AppData\Local\Android\Sdk\platform-tools\adb.exe start-server
C:\Users\kunap\AppData\Local\Android\Sdk\platform-tools\adb.exe devices

# Device offline
C:\Users\kunap\AppData\Local\Android\Sdk\platform-tools\adb.exe reconnect

# Multiple devices (specify target)
C:\Users\kunap\AppData\Local\Android\Sdk\platform-tools\adb.exe -s emulator-5554 install -r build\app\outputs\flutter-apk\app-debug.apk
```

### Environment Variables
```powershell
# Check current settings
cat .env | Select-String "MOCK_PAYMENT_MODE"

# Toggle payment mode
(Get-Content .env) -replace 'MOCK_PAYMENT_MODE=true', 'MOCK_PAYMENT_MODE=false' | Set-Content .env
```

## Security Tiers
1. **App (.env)** - Local secrets only
2. **Edge (supabase/functions/.env)** - Production secrets
3. **Auto (Supabase)** - Automatically injected

## Success Metrics
- Errors: 0 (zero tolerance)
- Build time: <45 seconds
- Test coverage: >95%
- App startup: <2 seconds
- Payment flow: <20 seconds
- All platforms: ✅
- Emulator boot: <60 seconds
- App install: <10 seconds
- Hot reload: <3 seconds

## Quick Links
- Supabase: https://supabase.com/dashboard/project/ixwwtabatwskafyvlwnm
- GitHub: https://github.com/prasanthkuna/invoice-pe-flutter
- Codemagic: Check build status
- PhonePe Docs: https://developer.phonepe.com/docs

## 🚀 RELEASE BUILD TESTING (WORKING)

### Complete Release Testing Workflow
```powershell
# 1. Clean build
flutter clean && flutter pub get

# 2. Build fixed release version
flutter build apk --release --split-per-abi

# 3. Install on emulator
adb install build\app\outputs\flutter-apk\app-arm64-v8a-release.apk

# 4. Monitor logs during testing
adb logcat -s flutter

# 5. Test critical flows
# - Login with OTP verification ✅
# - Payment processing ✅
# - Navigation between screens ✅
# - All features working ✅
```

**Status**: ✅ 38.9MB release build fully functional - no "ref after disposed" errors

---
**Tesla Standard**: Fix once. Automate forever. Ship fast.
