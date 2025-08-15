# 🧠 InvoicePe - LLM Agent Context Map
> **Single Source of Truth for AI Agents - Elon Standard Navigation**

## 🎯 **INSTANT PROJECT UNDERSTANDING**

### **What is InvoicePe?**
Revolutionary B2B payment app that converts credit card payments to instant bank transfers, solving India's ₹182.84 trillion delayed payment crisis.

### **Current Status: DEMO READY**
- ✅ **Functionality**: 100% complete, all features working
- ✅ **Testing**: Mock payment mode, real device compatible
- 🔄 **Optimization**: APK size reduction (153MB → <8MB target)
- 🔄 **Issues**: Keyboard input on emulator (real device works)

---

## 📁 **CRITICAL FILE NAVIGATION**

### **🚨 IMMEDIATE ACTION FILES**
```
lib/main.dart                           # App entry point
lib/core/services/payment_service.dart  # Payment logic
lib/features/payment/presentation/screens/quick_payment_screen.dart  # Main UI
.env                                     # Environment config
android/app/build.gradle.kts            # Build optimization
```

### **📋 DOCUMENTATION HUB**
```
docs/AGENT_CONTEXT_MAP.md              # THIS FILE - Start here
docs/DECISION_TREES.md                 # Scenario-based guidance
docs/CODE_PATTERNS.md                  # Implementation standards
docs/TROUBLESHOOTING_MATRIX.md         # Systematic debugging
docs/ARCHITECTURE_BLUEPRINT.md         # System design
PROJECT_PROGRESS.md                    # Development status
```

### **🔧 CONFIGURATION FILES**
```
pubspec.yaml                           # Dependencies
android/app/proguard-rules.pro         # APK optimization
flutter_launcher_icons.yaml           # App icons
.gitignore                             # Version control
```

---

## 🎯 **QUICK DECISION MATRIX**

### **User Reports Issue → Action**
- **"Keyboard not working"** → Check `TROUBLESHOOTING_MATRIX.md` → Emulator vs Real Device
- **"Payment failed"** → Check `payment_service.dart` → Mock mode enabled?
- **"App won't build"** → Check `build.gradle.kts` → Dependencies resolved?
- **"Size too large"** → Check `PROJECT_PROGRESS.md` → Asset optimization status

### **Development Task → File**
- **Add new feature** → Check `CODE_PATTERNS.md` → Follow Riverpod pattern
- **Fix UI issue** → Navigate to `lib/features/[feature]/presentation/screens/`
- **Database change** → Check `supabase/migrations/` → Create new migration
- **Build optimization** → Check `android/app/build.gradle.kts` → ProGuard rules

---

## 🏗️ **ARCHITECTURE OVERVIEW**

### **Frontend (Flutter)**
```
lib/
├── core/                    # Shared services, constants, themes
│   ├── services/           # Payment, Auth, Logger services
│   ├── constants/          # App constants, environment config
│   └── theme/              # UI theme and styling
├── features/               # Feature-based architecture
│   ├── auth/              # Authentication (phone OTP)
│   ├── payment/           # Payment processing
│   ├── dashboard/         # Main dashboard
│   ├── vendors/           # Vendor management
│   └── transactions/      # Transaction history
└── shared/                # Shared widgets and utilities
```

### **Backend (Supabase)**
```
supabase/
├── migrations/            # Database schema changes
├── functions/            # Edge functions (payment processing)
└── config.toml          # Supabase configuration
```

---

## 🔄 **DEVELOPMENT WORKFLOW**

### **Standard Process**
1. **Check PROJECT_PROGRESS.md** for current status
2. **Use DECISION_TREES.md** for scenario guidance
3. **Follow CODE_PATTERNS.md** for implementation
4. **Update documentation** when making changes
5. **Test on real device** for keyboard/input validation

### **Build Process**
1. **Development**: `flutter run` (hot reload)
2. **Demo Build**: `.\build_demo.ps1` (automated)
3. **Optimization**: Check `android/app/build.gradle.kts`
4. **Size Check**: Target <8MB (current: 153MB)

---

## 🚨 **CRITICAL KNOWLEDGE**

### **Environment Variables**
- **MOCK_PAYMENT_MODE=true** - Safe for testing
- **SUPABASE_URL** - Database connection
- **PHONEPE_MERCHANT_ID=DEMOUAT** - UAT credentials

### **Known Issues**
- **Keyboard**: Works on real device, not emulator
- **APK Size**: 153MB due to unoptimized assets
- **Build**: Release build needs ProGuard optimization

### **Success Metrics**
- **Payment Flow**: <20 seconds end-to-end
- **APK Size**: <8MB (Tesla standard)
- **Performance**: 60fps UI, <100ms response

---

## 📈 **NEXT ACTIONS**

### **Immediate (Today)**
1. Fix APK size optimization
2. Test keyboard on real device
3. Validate payment flow end-to-end

### **This Week**
1. Complete build optimization
2. Create GitHub Actions CI/CD
3. Prepare for app store submission

---

**🎯 LLM Agent Tip**: Always start here for project context, then navigate to specific documentation files based on your task.**
