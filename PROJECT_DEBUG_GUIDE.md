# 🛠️ InvoicePe Project Debug Guide

## 📋 **Project Information**
- **Project**: InvoicePe Flutter App
- **Repository**: https://github.com/prasanthkuna/invoice-pe-flutter.git
- **Supabase Project**: your-project-id
- **Database Password**: your-database-password
- **Flutter Version**: 3.32.6 (installed at C:\tools\flutter)

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

### **PATH Management**
```powershell
# Check current PATH
$env:PATH -split ';'

# Add Flutter to current session
$env:PATH = "C:\tools\flutter\bin;" + $env:PATH

# Check Flutter in PATH
where flutter

# Check Scoop path
$env:PATH -split ';' | Where-Object { $_ -like '*scoop*' }
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

## 🔗 **Quick Links**
- **Supabase Dashboard**: https://supabase.com/dashboard/project/your-project-id
- **GitHub Repository**: https://github.com/prasanthkuna/invoice-pe-flutter
- **Flutter Documentation**: https://docs.flutter.dev/
- **Supabase Documentation**: https://supabase.com/docs

---
*Last Updated: 2025-07-12*
*Flutter 3.32.6 | Supabase CLI 2.24.3 | Project Status: Phase 4 Ready*
