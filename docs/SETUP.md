# InvoicePe Setup Guide

## Prerequisites

Before setting up InvoicePe, ensure you have the following installed:

- **Flutter SDK**: 3.32.6 or higher
- **Dart SDK**: 3.8 or higher  
- **Android Studio**: Latest stable version (for Android development)
- **Xcode**: Latest stable version (for iOS development, macOS only)
- **Git**: Version control system

## Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/prasanthkuna/invoice-pe-flutter.git
cd invoice-pe-flutter

# 2. Environment setup
cp .env.example .env
# Edit .env with your configuration (see Environment Configuration below)

# 3. Install dependencies and run
flutter pub get
flutter run
```

## Environment Configuration

### Supabase Backend Configuration

Create a Supabase project and configure the following environment variables in your `.env` file:

```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
PHONEPE_MERCHANT_ID=your_merchant_id
PHONEPE_SALT_KEY=your_salt_key
MOCK_PAYMENT_MODE=true
```

### PhonePe Payment Gateway Configuration

For payment functionality, configure your PhonePe merchant credentials:

```env
PHONEPE_MERCHANT_ID=your_phonepe_merchant_id
PHONEPE_SALT_KEY=your_phonepe_salt_key
MOCK_PAYMENT_MODE=true  # Set to false for production
```

## Development Commands

### Building and Running
```bash
# Development mode with hot reload
flutter run

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release

# Run tests
flutter test

# Code analysis
flutter analyze
```

### Backend Development
```bash
# Deploy Supabase functions
supabase functions deploy

# Run local Supabase
supabase start
```

## Verification

After setup, verify the installation:

- ✅ Application launches without errors
- ✅ User authentication works
- ✅ Dashboard displays properly
- [ ] Can make mock payments
- [ ] Transactions appear in database

## Troubleshooting

### Common Issues

**Application fails to start:**
```bash
flutter clean && flutter pub get
flutter run
```

**No keyboard on inputs?**
- Restart emulator
- Check Android manifest settings

**Supabase connection failed?**
- Verify .env credentials
- Check network connection

## 📱 Platform Requirements

- **Flutter**: 3.32.6+
- **Dart**: 3.8+
- **Android**: API 21+
- **iOS**: 12.0+

---
**Tesla Standard**: Setup once. Run everywhere. Ship fast.
