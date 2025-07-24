# 🚀 InvoicePe Setup Guide - Tesla Speed

> "The best setup is no setup. Automate everything." - Elon Standard

## ⚡ Quick Start (2 Minutes)

```bash
# 1. Clone & Setup
git clone https://github.com/prasanthkuna/invoice-pe-flutter.git
cd invoice-pe-flutter

# 2. Environment Setup
cp .env.example .env
# Edit .env with your Supabase credentials (see below)

# 3. Install & Run
flutter pub get
flutter run
```

## 🔑 Required Credentials

### **Supabase Setup (CRITICAL)**
1. Go to: https://supabase.com/dashboard/project/ixwwtabatwskafyvlwnm/settings/api
2. Copy these values to your `.env`:
   ```
   SUPABASE_URL=https://ixwwtabatwskafyvlwnm.supabase.co
   SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   ```

### **Edge Functions Setup**
```bash
# Create edge function environment
echo "SUPABASE_URL=https://ixwwtabatwskafyvlwnm.supabase.co" > supabase/functions/.env
echo "SUPABASE_ANON_KEY=your-anon-key" >> supabase/functions/.env
```

## 🛠️ Development Commands

```bash
# Hot reload development
flutter run -d emulator-5554

# Build for testing
flutter build apk --debug

# Deploy edge functions
supabase functions deploy
```

## 🎯 Verification Checklist

- [ ] App launches without errors
- [ ] Can login with phone number
- [ ] Dashboard shows data
- [ ] Can make mock payments
- [ ] Transactions appear in database

## 🚨 Troubleshooting

**App won't start?**
```bash
flutter clean && flutter pub get
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
