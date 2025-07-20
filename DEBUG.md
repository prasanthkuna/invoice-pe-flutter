# InvoicePe Debug Guide - Tesla Standard 🚀

> "The best debug is no debug. Automate everything. Fix root causes."

## Critical Info
- **Supabase Project**: ixwwtabatwskafyvlwnm (ap-southeast-1)
- **Flutter**: 3.32.6
- **Security**: 3-Tier Architecture (App/Edge/Auto)
- **Platforms**: Android/iOS/Web/Windows/macOS/Linux
- **Beta Mode**: Mock payments enabled (MOCK_PAYMENT_MODE=true)

## 🎯 The Only Commands You Need

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

### 2. Device Management
```powershell
# List all devices
flutter devices

# Run on specific device
flutter run -d windows     # Windows desktop
flutter run -d chrome      # Web browser
flutter run -d emulator-5554  # Android emulator
flutter run -d [device-id]    # Your connected device
```

### 3. PATH Fix (If Flutter Not Found)
```powershell
$env:PATH = "C:\tools\flutter\bin;" + $env:PATH
```

### 3. Security Check
```powershell
# Verify no credential leaks
Select-String -Path "lib\**\*.dart" -Pattern "PHONEPE_|TWILIO_|JWT_SECRET"
```

### 4. Supabase Edge Functions
```powershell
# Deploy secrets
supabase secrets set --env-file supabase/functions/.env

# Deploy functions
supabase functions deploy

# Check logs
supabase functions logs initiate-payment
```

### 5. Build & Run
```powershell
# Debug build
flutter build apk --debug

# Run on device
flutter run
```

## Fix Sequence (Copy & Run)
```powershell
# The Complete Fix - 2 minutes total
flutter clean
flutter pub get
dart fix --apply
dart format .
flutter analyze
flutter test
```

## Beta Testing Commands
```powershell
# Test mock payments
$env:MOCK_PAYMENT_MODE="true"
flutter run

# Test real payments (PhonePe UAT)
$env:MOCK_PAYMENT_MODE="false"
flutter run

# Build release APK
flutter build apk --release

# Build for all platforms
flutter build apk
flutter build appbundle
flutter build web
flutter build windows
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

## Quick Links
- Supabase: https://supabase.com/dashboard/project/ixwwtabatwskafyvlwnm
- GitHub: https://github.com/prasanthkuna/invoice-pe-flutter
- Codemagic: Check build status
- PhonePe Docs: https://developer.phonepe.com/docs

---
**Tesla Standard**: Fix once. Automate forever. Ship fast.
