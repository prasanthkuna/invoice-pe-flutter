# 🌳 InvoicePe - LLM Decision Trees
> **Systematic Problem Solving for AI Agents - Elon Standard Logic**

## 🎯 **MASTER DECISION TREE**

```
USER ISSUE REPORTED
├── 🔧 TECHNICAL ISSUE
│   ├── Build/Compilation → [BUILD_ISSUES]
│   ├── Runtime Error → [RUNTIME_ISSUES]
│   ├── UI/UX Problem → [UI_ISSUES]
│   └── Performance → [PERFORMANCE_ISSUES]
├── 📱 FUNCTIONALITY ISSUE
│   ├── Authentication → [AUTH_ISSUES]
│   ├── Payment Flow → [PAYMENT_ISSUES]
│   ├── Database → [DATABASE_ISSUES]
│   └── Navigation → [NAVIGATION_ISSUES]
└── 🚀 OPTIMIZATION REQUEST
    ├── App Size → [SIZE_OPTIMIZATION]
    ├── Performance → [PERFORMANCE_OPTIMIZATION]
    └── Build Process → [BUILD_OPTIMIZATION]
```

---

## 🔧 **[BUILD_ISSUES] - Compilation Problems**

```
BUILD FAILS
├── Dependency Issues
│   ├── pubspec.yaml conflicts → Run `flutter pub deps`
│   ├── Version mismatch → Check `pubspec.lock`
│   └── Missing packages → Run `flutter pub get`
├── Android Build Issues
│   ├── Gradle errors → Check `android/app/build.gradle.kts`
│   ├── ProGuard issues → Check `proguard-rules.pro`
│   └── SDK version → Verify minSdk=21, targetSdk=34
├── Code Generation Issues
│   ├── Missing .g.dart files → Run `flutter packages pub run build_runner build`
│   ├── Conflicting outputs → Add `--delete-conflicting-outputs`
│   └── Dart mappable errors → Check model annotations
└── Environment Issues
    ├── Missing .env → Copy from `.env.example`
    ├── Invalid credentials → Verify Supabase keys
    └── Path issues → Check Flutter/Android SDK paths
```

**SOLUTION PRIORITY**: Dependencies → Environment → Code Generation → Platform-specific

---

## 📱 **[PAYMENT_ISSUES] - Payment Flow Problems**

```
PAYMENT NOT WORKING
├── Mock Mode Issues
│   ├── Mock disabled → Check `.env` MOCK_PAYMENT_MODE=true
│   ├── Transaction not created → Check `payment_service.dart` line 80+
│   └── UI not updating → Check provider refresh calls
├── PhonePe Integration
│   ├── SDK initialization → Check `AppConstants.phonePeMerchantId`
│   ├── Salt key invalid → Verify UAT credentials
│   └── Environment mismatch → Check PHONEPE_ENVIRONMENT=UAT
├── Database Issues
│   ├── Transaction not saved → Check Supabase connection
│   ├── RLS policies → Verify user permissions
│   └── Edge function errors → Check Supabase logs
└── UI Flow Issues
    ├── Vendor not selected → Check autofocus logic
    ├── Amount validation → Check input validation
    └── Button disabled → Check form state
```

**CRITICAL FILES**: `payment_service.dart`, `.env`, `quick_payment_screen.dart`

---

## 🔍 **[UI_ISSUES] - User Interface Problems**

```
UI NOT WORKING
├── Keyboard Issues
│   ├── Emulator → Launch with `-no-hw-keyboard` flag
│   ├── Real device → Check AndroidManifest.xml windowSoftInputMode
│   ├── TextField focus → Check autofocus and focus nodes
│   └── Input validation → Check form validators
├── Navigation Issues
│   ├── Route not found → Check `app_router.dart`
│   ├── Context issues → Verify context.mounted
│   └── Back button → Check navigation stack
├── State Management
│   ├── Provider not updating → Check Riverpod provider refresh
│   ├── State not persisting → Check provider scope
│   └── Memory leaks → Check provider disposal
└── Styling Issues
    ├── Theme not applied → Check `app_theme.dart`
    ├── Responsive layout → Check MediaQuery usage
    └── Animation glitches → Check flutter_animate usage
```

**KEYBOARD ISSUE SPECIAL CASE**:
```
KEYBOARD NOT SHOWING
├── Platform Check
│   ├── Emulator → SOLUTION: `emulator -avd name -no-hw-keyboard`
│   └── Real Device → Check AndroidManifest.xml line 34
├── TextField Configuration
│   ├── autofocus → Should be false initially
│   ├── readOnly → Should be false
│   └── enabled → Should be true
└── Focus Management
    ├── FocusNode → Check proper initialization
    ├── Focus chain → Check tab order
    └── Context → Verify widget mounted
```

---

## 🚀 **[SIZE_OPTIMIZATION] - APK Size Reduction**

```
APK TOO LARGE (Current: 153MB, Target: <8MB)
├── Asset Optimization (CRITICAL - 20MB+ bloat)
│   ├── Icon sizes → Compress assets/icons/*.png
│   ├── Splash screens → Remove 3MB+ splash assets
│   └── Unused assets → Remove redundant files
├── Build Configuration
│   ├── ProGuard → Enable aggressive optimization
│   ├── Resource shrinking → Enable isShrinkResources=true
│   └── Split APKs → Consider ABI-specific builds
├── Dependencies
│   ├── Unused packages → Audit pubspec.yaml
│   ├── Large libraries → Consider alternatives
│   └── Tree shaking → Verify dead code elimination
└── Code Optimization
    ├── Unused imports → Remove with IDE
    ├── Dead code → Remove unused methods/classes
    └── String compression → Enable in ProGuard
```

**IMMEDIATE ACTION**: Fix asset bloat (20MB+ reduction possible)

---

## 🔄 **[DATABASE_ISSUES] - Supabase Problems**

```
DATABASE NOT WORKING
├── Connection Issues
│   ├── URL invalid → Check SUPABASE_URL in .env
│   ├── Key invalid → Verify SUPABASE_ANON_KEY
│   └── Network → Check internet connection
├── Authentication
│   ├── RLS policies → Check table permissions
│   ├── JWT expired → Re-authenticate user
│   └── User context → Verify auth state
├── Query Issues
│   ├── SQL syntax → Check raw queries
│   ├── Type mismatches → Verify model mappings
│   └── Constraints → Check foreign keys
└── Edge Functions
    ├── Function errors → Check Supabase logs
    ├── Environment vars → Verify function .env
    └── Deployment → Check function status
```

---

## ⚡ **QUICK DIAGNOSTIC COMMANDS**

### **Health Check Sequence**
```bash
# 1. Environment Check
flutter doctor -v

# 2. Dependencies Check
flutter pub deps

# 3. Build Check
flutter analyze

# 4. Test Build
flutter build apk --debug

# 5. Size Check
ls -lh build/app/outputs/flutter-apk/
```

### **Emergency Reset**
```bash
flutter clean
flutter pub get
flutter packages pub run build_runner build --delete-conflicting-outputs
```

---

## 🎯 **DECISION PRIORITY MATRIX**

### **CRITICAL (Fix Immediately)**
1. App won't build → [BUILD_ISSUES]
2. Payment flow broken → [PAYMENT_ISSUES]
3. Authentication failing → [AUTH_ISSUES]

### **HIGH (Fix Today)**
4. UI not responsive → [UI_ISSUES]
5. Database errors → [DATABASE_ISSUES]
6. Performance issues → [PERFORMANCE_ISSUES]

### **MEDIUM (Fix This Week)**
7. APK size optimization → [SIZE_OPTIMIZATION]
8. Build process improvement → [BUILD_OPTIMIZATION]

**🧠 LLM Agent Tip**: Follow decision trees systematically. Each branch provides specific file paths and line numbers for targeted fixes.**
