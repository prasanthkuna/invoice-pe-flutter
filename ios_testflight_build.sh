#!/bin/bash
# InvoicePe iOS TestFlight Build Script
# Elon's Philosophy: "Automate the boring stuff, focus on the important stuff"

set -e  # Exit on any error

echo "🚀 Starting InvoicePe iOS TestFlight Build Process..."

# Configuration
TEAM_ID="VWZAFH2ZDV"
BUNDLE_ID="com.invoicepe.invoicePeApp.staging"
APP_NAME="InvoicePe Staging"
SCHEME="Runner"
WORKSPACE="ios/Runner.xcworkspace"

echo "📋 Build Configuration:"
echo "   Team ID: $TEAM_ID"
echo "   Bundle ID: $BUNDLE_ID"
echo "   App Name: $APP_NAME"
echo ""

# Step 1: Clean and prepare Flutter
echo "🧹 Cleaning Flutter project..."
flutter clean
flutter pub get

# Step 2: Generate code
echo "🔧 Generating code..."
dart run build_runner build --delete-conflicting-outputs

# Step 3: Build iOS
echo "📱 Building iOS app..."
flutter build ios --release --dart-define-from-file=.env.staging

# Step 4: Configure Xcode project
echo "⚙️  Configuring Xcode project..."

# Update bundle identifier in project.pbxproj
sed -i '' "s/com\.invoicepe\.invoicePeApp/com.invoicepe.invoicePeApp.staging/g" ios/Runner.xcodeproj/project.pbxproj

echo "✅ iOS build preparation complete!"
echo ""
echo "📋 Next Steps:"
echo "1. Open ios/Runner.xcworkspace in Xcode"
echo "2. Select 'Any iOS Device' as target"
echo "3. Set Team to: $TEAM_ID (Bharath's Team)"
echo "4. Product → Archive"
echo "5. Distribute App → App Store Connect"
echo "6. Upload to TestFlight"
echo ""
echo "🎯 TestFlight Setup:"
echo "1. Login to App Store Connect: https://appstoreconnect.apple.com"
echo "2. Use Apple ID: Bharath5262@gmail.com"
echo "3. Create new app with Bundle ID: $BUNDLE_ID"
echo "4. Upload build and invite testers"
echo ""
echo "🚀 Ready for TestFlight distribution!"
