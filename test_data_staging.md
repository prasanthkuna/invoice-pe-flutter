# InvoicePe Staging Test Data - Real Device Testing
# Elon's Approach: "Test with realistic data, not perfect examples"

## 🧪 **TEST USER ACCOUNTS**

### **Primary Test User (Your Android Phone)**
- **Phone**: +919008393030
- **OTP**: 123456 (configured in Supabase)
- **Name**: Elon Tester
- **Business**: Tesla Payments India
- **Role**: Primary payment tester

### **Secondary Test User (Friend's iPhone)**
- **Phone**: +91[friend's number]
- **OTP**: 123456 (same test OTP)
- **Name**: Steve Tester  
- **Business**: Apple Invoices
- **Role**: iOS validation tester

---

## 💰 **TEST PAYMENT SCENARIOS**

### **Scenario 1: Quick Payment Success**
- **Amount**: ₹100
- **Description**: "Coffee payment test"
- **Expected**: Success with PhonePe UAT
- **Test**: Complete payment flow

### **Scenario 2: Invoice Payment**
- **Amount**: ₹2,500
- **Description**: "Consulting invoice payment"
- **Expected**: Invoice generation + payment
- **Test**: End-to-end invoice workflow

### **Scenario 3: Vendor Payment**
- **Amount**: ₹5,000
- **Vendor**: "Acme Supplies"
- **Expected**: Vendor creation + payment
- **Test**: Vendor management + payment

### **Scenario 4: Edge Cases**
- **Amount**: ₹1 (minimum)
- **Amount**: ₹99,999 (near maximum)
- **Network**: Test with poor connectivity
- **Interruption**: Test app backgrounding during payment

---

## 🏢 **TEST VENDOR DATA**

### **Vendor 1: Local Supplier**
- **Name**: Mumbai Office Supplies
- **Phone**: +919876543210
- **Email**: supplies@mumbai.com
- **Address**: Bandra West, Mumbai
- **GST**: 27ABCDE1234F1Z5

### **Vendor 2: Service Provider**
- **Name**: Tech Solutions Pvt Ltd
- **Phone**: +918765432109
- **Email**: contact@techsolutions.in
- **Address**: Koramangala, Bangalore
- **GST**: 29FGHIJ5678K2Y6

---

## 📄 **TEST INVOICE DATA**

### **Invoice 1: Service Invoice**
- **Client**: Startup ABC
- **Amount**: ₹15,000
- **Items**: 
  - App Development: ₹12,000
  - Testing Services: ₹3,000
- **Due Date**: 30 days from creation

### **Invoice 2: Product Invoice**
- **Client**: Retail Store XYZ
- **Amount**: ₹8,500
- **Items**:
  - Software License: ₹7,000
  - Support: ₹1,500
- **Due Date**: 15 days from creation

---

## 💳 **TEST CARD SCENARIOS**

### **Card Management Testing**
- **Add Card**: Test card addition flow
- **Default Card**: Set primary payment method
- **Card Security**: Test encryption/decryption
- **Card Removal**: Test secure deletion

---

## 📱 **REAL DEVICE TESTING CHECKLIST**

### **Android Device Tests**
- [ ] App installation from APK
- [ ] OTP login with real phone number
- [ ] Payment flow with PhonePe UAT
- [ ] Invoice generation and PDF
- [ ] Vendor CRUD operations
- [ ] Card management features
- [ ] Transaction history
- [ ] App performance and responsiveness
- [ ] Network interruption handling
- [ ] Background/foreground transitions

### **iOS Device Tests**
- [ ] App installation (TestFlight/ad-hoc)
- [ ] OTP login functionality
- [ ] Payment flow compatibility
- [ ] UI/UX consistency with Android
- [ ] iOS-specific features (Face ID, etc.)
- [ ] Performance on iOS hardware
- [ ] Memory usage and stability
- [ ] iOS notification handling

---

## 🔍 **CRITICAL PATH TESTING**

### **Priority 1: Money Flow (CRITICAL)**
1. **Login** → OTP → Dashboard
2. **Quick Payment** → Amount → PhonePe → Success
3. **Transaction History** → Verify payment recorded
4. **Invoice Payment** → Generate → Pay → Verify

### **Priority 2: Core Features (HIGH)**
1. **Vendor Management** → Add → Edit → Delete
2. **Card Management** → Add → Set Default → Remove
3. **Invoice Generation** → Create → PDF → Share

### **Priority 3: Edge Cases (MEDIUM)**
1. **Network Issues** → Poor connectivity → Recovery
2. **App Interruptions** → Background → Foreground
3. **Error Handling** → Invalid inputs → User feedback

---

## 📊 **SUCCESS CRITERIA**

### **Android Success Metrics**
- ✅ App installs and launches successfully
- ✅ Login flow completes without errors
- ✅ Payment flow works with PhonePe UAT
- ✅ All 5 core features functional
- ✅ No crashes during testing session

### **iOS Success Metrics**
- ✅ App installs via chosen distribution method
- ✅ UI renders correctly on iOS
- ✅ Core functionality matches Android
- ✅ iOS-specific features work properly
- ✅ Performance acceptable on iOS hardware

### **Overall Success**
- ✅ Both testers can complete payment flow
- ✅ No critical bugs discovered
- ✅ App feels production-ready
- ✅ Positive feedback from both testers
- ✅ Ready for production deployment

---

## 🚀 **POST-TESTING ACTIONS**

### **If Tests Pass**
- ✅ Proceed with production deployment
- ✅ Submit to app stores
- ✅ Begin user acquisition

### **If Issues Found**
- 🔧 Prioritize critical bugs
- 🔧 Fix payment flow issues immediately
- 🔧 Address UI/UX feedback
- 🔧 Re-test before production

**Testing Philosophy**: *"Better to find issues now with 2 friendly testers than later with 1000 angry customers."*
