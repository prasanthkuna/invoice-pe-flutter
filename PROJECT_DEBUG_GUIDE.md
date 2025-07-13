# 🛠️ InvoicePe Project Debug Guide - Elon Edition 2025

> **"The best debug guide is no debug guide. Automate everything, eliminate noise, fix once."**

## 📋 **Project Information**
- **Project**: InvoicePe Flutter App (PCI DSS Ready)
- **Repository**: https://github.com/prasanthkuna/invoice-pe-flutter.git
- **Supabase Project**: kaaarzacpimrrcgvkbwt
- **Database Password**: invoicepeflutter
- **Flutter Version**: 3.32.6 (installed at C:\tools\flutter)
- **Tech Stack**: Modern 2025 - PhonePe SDK 3.0.0, very_good_analysis 9.0.0, Patrol 3.11.0

## 🔧 **Environment Setup Commands**

### **Flutter Commands**
```powershell
# Check Flutter version
& "C:\tools\flutter\bin\flutter.bat" --version

# Run Flutter analyze
& "C:\tools\flutter\bin\flutter.bat" analyze

# Run Flutter doctor
& "C:\tools\flutter\bin\flutter.bat" doctor

# Get dependencies
& "C:\tools\flutter\bin\flutter.bat" pub get

# Build runner for dart_mappable
& "C:\tools\flutter\bin\flutter.bat" packages pub run build_runner build --delete-conflicting-outputs

# Clean project
& "C:\tools\flutter\bin\flutter.bat" clean

# Run app on Android emulator
& "C:\tools\flutter\bin\flutter.bat" run

# Build APK
& "C:\tools\flutter\bin\flutter.bat" build apk

# Check outdated packages
& "C:\tools\flutter\bin\flutter.bat" pub outdated

# Modern Dart tooling (Elon's favorites)
dart fix --apply                    # Auto-fix issues
dart format .                       # Format code
dart analyze                        # Analyze without Flutter overhead
```

### **Supabase Commands**
```powershell
# Check Supabase CLI version
& "$env:USERPROFILE\scoop\shims\supabase.exe" --version

# Link to project
& "$env:USERPROFILE\scoop\shims\supabase.exe" link --project-ref your-project-id --password your-database-password

# Pull database schema
& "$env:USERPROFILE\scoop\shims\supabase.exe" db pull --schema public

# Push migrations
& "$env:USERPROFILE\scoop\shims\supabase.exe" db push

# Reset database (careful!)
& "$env:USERPROFILE\scoop\shims\supabase.exe" db reset

# Create new migration
& "$env:USERPROFILE\scoop\shims\supabase.exe" migration new migration_name

# Start local development
& "$env:USERPROFILE\scoop\shims\supabase.exe" start

# Stop local development
& "$env:USERPROFILE\scoop\shims\supabase.exe" stop

# Check project status
& "$env:USERPROFILE\scoop\shims\supabase.exe" status

# Deploy Edge Functions
& "$env:USERPROFILE\scoop\shims\supabase.exe" functions deploy

# View logs
& "$env:USERPROFILE\scoop\shims\supabase.exe" logs
```

### **Scoop Commands**
```powershell
# List installed packages
scoop list

# Update Supabase CLI
scoop update supabase

# Update all packages
scoop update *

# Check for updates
scoop status

# Install new package
scoop install package_name

# Uninstall package
scoop uninstall package_name
```

## 🔍 **Debugging Commands**

### **Git Configuration for Flutter**
```powershell
# Fix Git ownership issues for Flutter
git config --global --add safe.directory C:/tools/flutter
```

### **🚀 Elon's PATH Management (Foundation Fix)**
```powershell
# STEP 1: Diagnose PATH issues
$env:PATH -split ';' | Where-Object { $_ -like '*flutter*' -or $_ -like '*dart*' -or $_ -like '*git*' }

# STEP 2: Verify Flutter installation
Test-Path "C:\tools\flutter\bin\flutter.bat"

# STEP 3: Add Flutter to current session (CRITICAL)
$env:PATH = "C:\tools\flutter\bin;" + $env:PATH

# STEP 4: Verify commands work
flutter --version
dart --version
git --version

# STEP 5: Check Scoop path (if using Scoop)
$env:PATH -split ';' | Where-Object { $_ -like '*scoop*' }
```

## 🎯 **Elon's Dart Tooling Mastery**

> **"Each tool has a purpose. Use them in sequence for maximum automation."**

### **The Optimal Fix Sequence**
```powershell
# STEP 1: Reconnaissance (See the battlefield)
flutter analyze

# STEP 2: Automation (Let AI fix what it can)
dart fix --apply

# STEP 3: Polish (Clean formatting)
dart format .

# STEP 4: Verification (Confirm success)
flutter analyze
```

### **Tool Power Comparison**
| Tool | Purpose | Power | Safety | Use Case |
|------|---------|-------|--------|----------|
| `flutter analyze` | Diagnosis | Read-only | 100% | See issues |
| `dart fix --apply` | Automation | High | 95% | Fix logic issues |
| `dart format` | Polish | Low | 100% | Fix formatting |

### **Why dart fix --apply is Superior**
- ✅ Removes unused imports (major error reducer)
- ✅ Fixes deprecated APIs (future-proofing)
- ✅ Adds type annotations (type safety)
- ✅ Fixes lint violations (code quality)
- ✅ PLUS formatting (includes dart format)

## 🚀 **Elon's Aggressive Dependency Modernization**

> **"Don't fix old tech - jump to the future. Break things forward, not backward."**

### **Modern Package Versions (2025 Stack)**
```yaml
# Payment & Core
phonepe_payment_sdk: ^3.0.0        # 2.0.3 → 3.0.0 (Latest payment tech)
mobile_scanner: ^7.0.1             # 5.2.3 → 7.0.1 (Modern QR scanning)
reactive_forms: ^18.1.1            # 17.0.1 → 18.1.1 (Latest forms)

# Testing Revolution
very_good_analysis: ^9.0.0         # 6.0.0 → 9.0.0 (Latest lint rules)
bloc_test: ^10.0.0                 # 9.1.7 → 10.0.0 (Modern testing)
patrol: ^3.11.0                    # Revolutionary integration testing

# State Management
bloc: ^9.0.0                       # 8.1.4 → 9.0.0 (Latest state management)
```

### **Dependency Upgrade Strategy**
```powershell
# STEP 1: Check current versions
flutter pub outdated

# STEP 2: Aggressive upgrade (Elon style)
# Edit pubspec.yaml with latest versions above

# STEP 3: Clean foundation
flutter clean
flutter pub get

# STEP 4: Fix breaking changes
dart fix --apply
dart format .

# STEP 5: Verify success
flutter analyze
```

### **Dependency Override Cleanup**
```yaml
# Minimal overrides (Elon-style cleanup)
dependency_overrides:
  # Keep only essential Flutter 3.32/Dart 3.8 compatibility
  meta: ^1.17.0
  material_color_utilities: ^0.13.0
  vector_math: ^2.2.0
  # Remove all others - let new versions resolve naturally
```

## 🛠️ **Import & Syntax Error Resolution**

### **Ambiguous Import Fixes**
```dart
// Problem: Ambiguous import
import '../test/utils/test_helpers.dart';

// Solution: Use import aliases
import '../test/utils/test_helpers.dart' as test_helpers;

// Usage:
test_helpers.SecurityTestData.xssTestPayloads
```

### **Common Syntax Fixes**
```powershell
# Fix missing closing braces
# Check for unmatched { } in integration tests

# Fix const constructor issues
# Add 'const' keyword where required

# Fix type mismatches
# Update double to String for validation methods
```

### **Project Structure Check**
```powershell
# Check if Flutter project
Test-Path "pubspec.yaml"

# Check Supabase config
Test-Path "supabase/config.toml"

# List migrations
Get-ChildItem "supabase/migrations" -Name

# Check lib structure
Get-ChildItem "lib" -Recurse -Directory | Select-Object Name
```

## 📊 **Data Model Alignment Status**

### **✅ Completed Fixes**
- TransactionStatus enum: `{initiated, success, failure}`
- Added userId fields to all models
- Fixed nullable vendorId/vendorName fields
- Database schema includes 'draft' status
- Service layer mappings updated

### **🔧 Current Architecture**
- **State Management**: Riverpod 2.6.1
- **Data Models**: dart_mappable 4.5.0
- **Routing**: go_router 16.0.0
- **Backend**: Supabase with PostgreSQL 17
- **Authentication**: OTP via Twilio Verify

## 🚨 **Common Issues & Solutions**

### **Flutter Analyze Issues**
```powershell
# If analysis hangs
taskkill /f /im dart.exe
& "C:\tools\flutter\bin\flutter.bat" clean
& "C:\tools\flutter\bin\flutter.bat" pub get
& "C:\tools\flutter\bin\flutter.bat" analyze
```

### **Supabase Connection Issues**
```powershell
# Check if project is paused
& "$env:USERPROFILE\scoop\shims\supabase.exe" projects list

# Re-link if needed
& "$env:USERPROFILE\scoop\shims\supabase.exe" link --project-ref your-project-id --password your-database-password
```

### **Build Issues**
```powershell
# Clean and rebuild
& "C:\tools\flutter\bin\flutter.bat" clean
& "C:\tools\flutter\bin\flutter.bat" pub get
& "C:\tools\flutter\bin\flutter.bat" packages pub run build_runner build --delete-conflicting-outputs
```

## 📈 **Performance Monitoring**
```powershell
# Check analysis time
Measure-Command { & "C:\tools\flutter\bin\flutter.bat" analyze }

# Check build time
Measure-Command { & "C:\tools\flutter\bin\flutter.bat" build apk }
```

## 🚀 **Elon's Complete Automated Fix Workflow**

> **"The best workflow is the one that fixes everything automatically. Copy, paste, execute."**

### **🔥 Nuclear Option: Complete Reset & Modernization**
```powershell
# PHASE 0: Foundation Reset (30 seconds)
flutter clean
flutter pub get

# PHASE 1: PATH Fix (if needed)
$env:PATH = "C:\tools\flutter\bin;" + $env:PATH
flutter --version  # Verify

# PHASE 2: Automated Fixes (2 minutes)
dart fix --apply
dart format .

# PHASE 3: Verification (30 seconds)
flutter analyze

# PHASE 4: Build Test (1 minute)
flutter build apk --debug
```

### **🎯 Emergency Troubleshooting Sequence**
```powershell
# If flutter analyze shows 100+ errors:
# 1. Check PATH
$env:PATH -split ';' | Where-Object { $_ -like '*flutter*' }

# 2. Add Flutter to PATH
$env:PATH = "C:\tools\flutter\bin;" + $env:PATH

# 3. Clean and reset
flutter clean
flutter pub get

# 4. Run automated fixes
dart fix --apply
dart format .

# 5. Check results
flutter analyze
```

### **📊 Success Metrics**
- **Before**: 170+ errors with old dependencies
- **After**: 0-5 errors with modern stack
- **Time**: 5 minutes total automation
- **Approach**: Break forward, not backward

## 🔗 **Quick Links**
- **Supabase Dashboard**: https://supabase.com/dashboard/project/kaaarzacpimrrcgvkbwt
- **GitHub Repository**: https://github.com/prasanthkuna/invoice-pe-flutter
- **Flutter Documentation**: https://docs.flutter.dev/
- **Supabase Documentation**: https://supabase.com/docs
- **Elon's Testing Strategy**: InvoicePe_TESTING_STRATEGY.md

---
*Last Updated: 2025-07-13 - Elon Edition*
*Flutter 3.32.6 | Modern Stack 2025 | PhonePe SDK 3.0.0 | very_good_analysis 9.0.0*
*Status: Revolutionary Modernization Complete ✅*
