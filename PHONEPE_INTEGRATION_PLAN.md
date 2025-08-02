# 🚀 PhonePe SDK 3.0.0 Integration Plan

> **Elon-Style Implementation: Minimal Code, Maximum Performance, Zero Complexity**

## 📊 **EXECUTIVE SUMMARY**

**Objective**: Complete PhonePe SDK 3.0.0 integration with minimal code lines and maximum performance  
**Timeline**: 8 hours development + 2 hours testing = 1 working day  
**Approach**: Database → Flutter → Edge Functions → Testing  
**Result**: Production-ready PhonePe integration with card management  

---

## 🎯 **IMPLEMENTATION SEQUENCE**

### **PHASE 1: DATABASE OPERATIONS (1 hour)**
### **PHASE 2: FLUTTER CODE UPDATES (4 hours)**
### **PHASE 3: EDGE FUNCTIONS (2 hours)**
### **PHASE 4: TESTING & VALIDATION (1 hour)**

---

## 📋 **PHASE 1: DATABASE OPERATIONS (1 hour)**

### **Step 1.1: PhonePe SDK 3.0.0 Migration (30 minutes)**

Create migration file: `supabase/migrations/20250102000000_phonepe_sdk_3_support.sql`

```sql
-- PhonePe SDK 3.0.0 Database Migration
-- Minimal changes, maximum performance

-- 1. Add PhonePe Order Management to transactions table
ALTER TABLE public.transactions 
ADD COLUMN IF NOT EXISTS phonepe_order_id TEXT,
ADD COLUMN IF NOT EXISTS phonepe_order_token TEXT,
ADD COLUMN IF NOT EXISTS phonepe_order_status TEXT,
ADD COLUMN IF NOT EXISTS phonepe_merchant_order_id TEXT;

-- 2. Enhanced Error & Response Tracking (JSONB for flexibility)
ALTER TABLE public.transactions 
ADD COLUMN IF NOT EXISTS phonepe_error_details JSONB DEFAULT '{}',
ADD COLUMN IF NOT EXISTS phonepe_response_data JSONB DEFAULT '{}';

-- 3. Webhook & Verification Support
ALTER TABLE public.transactions 
ADD COLUMN IF NOT EXISTS webhook_received_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS webhook_verified BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS webhook_data JSONB DEFAULT '{}';

-- 4. Order Status Polling
ALTER TABLE public.transactions 
ADD COLUMN IF NOT EXISTS last_status_check_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS status_check_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS auto_polling_enabled BOOLEAN DEFAULT true;

-- 5. Performance Indexes (CRITICAL for speed)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_transactions_phonepe_order_id 
ON public.transactions(phonepe_order_id) WHERE phonepe_order_id IS NOT NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_transactions_order_status 
ON public.transactions(phonepe_order_status) WHERE phonepe_order_status IS NOT NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_transactions_polling 
ON public.transactions(last_status_check_at, auto_polling_enabled) 
WHERE auto_polling_enabled = true;

-- 6. Update status constraint for PhonePe statuses
ALTER TABLE public.transactions DROP CONSTRAINT IF EXISTS transactions_status_check;
ALTER TABLE public.transactions ADD CONSTRAINT transactions_status_check 
CHECK (status IN ('initiated', 'pending', 'success', 'failure', 'cancelled', 'expired'));
```

### **Step 1.2: Auth Token Management Table (30 minutes)**

```sql
-- 7. PhonePe Auth Token Management (Merchant-level)
CREATE TABLE IF NOT EXISTS public.phonepe_auth_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    access_token TEXT NOT NULL,
    token_type TEXT DEFAULT 'Bearer',
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true
);

-- Performance index for token lookup
CREATE INDEX IF NOT EXISTS idx_phonepe_tokens_active 
ON public.phonepe_auth_tokens(expires_at DESC, is_active) 
WHERE is_active = true;

-- RLS Policy (service-level access)
ALTER TABLE public.phonepe_auth_tokens ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Service can manage auth tokens" ON public.phonepe_auth_tokens
FOR ALL USING (true);

-- Apply migration
-- Run: supabase db push
```

---

## 💻 **PHASE 2: FLUTTER CODE UPDATES (4 hours)**

### **Step 2.1: Update Transaction Model (30 minutes)**

File: `lib/shared/models/transaction.dart`

```dart
@MappableClass()
class Transaction with TransactionMappable {
  const Transaction({
    // Existing fields...
    required this.id,
    required this.userId,
    required this.amount,
    required this.status,
    
    // NEW: PhonePe SDK 3.0.0 fields (minimal additions)
    this.phonepeOrderId,
    this.phonepeOrderToken,
    this.phonepeOrderStatus,
    this.phonepeMerchantOrderId,
    this.phonepeErrorDetails,
    this.phonepeResponseData,
    this.webhookReceivedAt,
    this.webhookVerified,
    this.lastStatusCheckAt,
    this.statusCheckCount,
    this.autoPollingEnabled = true,
  });

  // Existing fields...
  final String id;
  final String userId;
  final double amount;
  final TransactionStatus status;
  
  // NEW: PhonePe SDK 3.0.0 fields
  final String? phonepeOrderId;
  final String? phonepeOrderToken;
  final String? phonepeOrderStatus;
  final String? phonepeMerchantOrderId;
  final Map<String, dynamic>? phonepeErrorDetails;
  final Map<String, dynamic>? phonepeResponseData;
  final DateTime? webhookReceivedAt;
  final bool? webhookVerified;
  final DateTime? lastStatusCheckAt;
  final int? statusCheckCount;
  final bool autoPollingEnabled;
}
```

### **Step 2.2: PhonePe Auth Token Model (15 minutes)**

File: `lib/shared/models/phonepe_auth_token.dart`

```dart
import 'package:dart_mappable/dart_mappable.dart';

part 'phonepe_auth_token.mapper.dart';

@MappableClass()
class PhonePeAuthToken with PhonePeAuthTokenMappable {
  const PhonePeAuthToken({
    required this.id,
    required this.accessToken,
    required this.expiresAt,
    this.tokenType = 'Bearer',
    this.isActive = true,
    this.createdAt,
  });

  final String id;
  final String accessToken;
  final String tokenType;
  final DateTime expiresAt;
  final bool isActive;
  final DateTime? createdAt;
  
  // Performance helpers
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => isActive && !isExpired;
  
  static const PhonePeAuthToken Function(Map<String, dynamic> map) fromMap = PhonePeAuthTokenMapper.fromMap;
}
```

### **Step 2.3: Updated Payment Service (2 hours)**

File: `lib/core/services/payment_service.dart`

```dart
class PaymentService extends BaseService {
  static bool _phonePeInitialized = false;
  static final _log = Log.component('payment');

  /// Initialize PhonePe SDK 3.0.0 (NEW PATTERN)
  static Future<void> initializePhonePe() async {
    if (_phonePeInitialized) return;
    try {
      _log.info('🚀 Initializing PhonePe SDK 3.0.0');

      // NEW: SDK 3.0.0 initialization pattern
      await PhonePePaymentSdk.init(
        AppConstants.phonePeEnvironment,  // "SANDBOX" or "PRODUCTION"
        AppConstants.phonePeMerchantId,   // Merchant ID
        'INVOICE_PE_FLOW',                // Flow ID (user-specific)
        AppConstants.debugMode,           // Enable logging
      );

      _log.info('✅ PhonePe SDK 3.0.0 initialized');
      _phonePeInitialized = true;
    } catch (error) {
      _log.error('PhonePe SDK initialization failed', error: error);
      rethrow;
    }
  }

  /// Process Payment with PhonePe SDK 3.0.0 (COMPLETE REWRITE)
  static Future<PaymentSuccess> processPayment({
    required String vendorId,
    required String vendorName,
    required double amount,
    String? invoiceId,
  }) async {
    try {
      _log.info('💳 Starting PhonePe 3.0.0 payment', {
        'amount': amount,
        'vendor': vendorName,
      });

      // Step 1: Create Order via Edge Function
      final orderResponse = await BaseService.supabase.functions.invoke(
        'create-phonepe-order',
        body: {
          'amount': (amount * 100).round(), // Convert to paise
          'vendor_id': vendorId,
          'invoice_id': invoiceId,
        },
      );

      if (orderResponse.data?['success'] != true) {
        throw Exception('Order creation failed: ${orderResponse.data?['error']}');
      }

      final orderData = orderResponse.data as Map<String, dynamic>;
      final orderId = orderData['orderId'] as String;
      final orderToken = orderData['token'] as String;

      // Step 2: Initialize PhonePe SDK
      await initializePhonePe();

      // Step 3: Create Transaction Request (NEW FORMAT)
      final request = {
        "orderId": orderId,
        "merchantId": AppConstants.phonePeMerchantId,
        "token": orderToken,
        "paymentMode": {
          "type": "PAY_PAGE",
          "savedCards": true,      // Enable saved cards
          "allowNewCard": true,    // Allow new cards
        }
      };

      _log.info('📱 Starting PhonePe transaction', {'orderId': orderId});

      // Step 4: Start Transaction
      final result = await PhonePePaymentSdk.startTransaction(
        jsonEncode(request),
        null, // App schema (iOS only)
      );

      // Step 5: Handle Response
      return await _handlePaymentResponse(result, orderId, amount);

    } catch (error) {
      _log.error('Payment processing failed', error: error);
      rethrow;
    }
  }

  /// Handle Payment Response (OPTIMIZED)
  static Future<PaymentSuccess> _handlePaymentResponse(
    dynamic result, 
    String orderId, 
    double amount,
  ) async {
    try {
      // Parse PhonePe response
      final response = result as Map<String, dynamic>;
      final success = response['success'] == true;
      
      if (success) {
        // Verify payment status via Edge Function
        final statusResponse = await BaseService.supabase.functions.invoke(
          'verify-phonepe-payment',
          body: {'orderId': orderId},
        );

        if (statusResponse.data?['verified'] == true) {
          return PaymentSuccess(
            transactionId: statusResponse.data['transactionId'],
            amount: amount,
            message: 'Payment completed successfully',
          );
        }
      }

      throw Exception('Payment verification failed');
    } catch (error) {
      _log.error('Payment response handling failed', error: error);
      rethrow;
    }
  }
}
```

### **Step 2.4: Card Management Update (1 hour)**

File: `lib/features/cards/presentation/screens/card_list_screen.dart`

```dart
class CardListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Methods')),
      body: Column(
        children: [
          // PhonePe Card Management Info
          _PhonePeCardInfoCard(),
          
          // Recent Payment Methods (from transaction history)
          _RecentPaymentMethods(),
          
          // Manage Cards via PhonePe Button
          _ManageCardsButton(),
        ],
      ),
    );
  }

  Widget _PhonePeCardInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.security, color: AppTheme.primaryAccent),
            const SizedBox(height: 8),
            Text('Secure Card Management', style: AppTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Your cards are securely managed by PhonePe with bank-grade security and automatic tokenization.',
              textAlign: TextAlign.center,
              style: AppTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _ManageCardsButton() {
    return ElevatedButton.icon(
      onPressed: () => _initiateCardManagement(),
      icon: const Icon(Icons.payment),
      label: const Text('Manage Cards via PhonePe'),
    );
  }

  void _initiateCardManagement() {
    // Start a ₹1 payment to access PhonePe card management
    PaymentService.processPayment(
      vendorId: 'card_management',
      vendorName: 'Card Management',
      amount: 1.0, // ₹1 for card management access
    );
  }
}
```

---

## 🌐 **PHASE 3: EDGE FUNCTIONS (2 hours)**

### **Step 3.1: Auth Token Service (45 minutes)**

File: `supabase/functions/phonepe-auth/index.ts`

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  try {
    // Get or refresh PhonePe auth token
    const authResponse = await fetch('https://api-preprod.phonepe.com/apis/pg-sandbox/v1/oauth/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        client_id: Deno.env.get('PHONEPE_CLIENT_ID')!,
        client_secret: Deno.env.get('PHONEPE_CLIENT_SECRET')!,
        grant_type: 'client_credentials',
        client_version: '1',
      }),
    })

    const authData = await authResponse.json()
    
    if (!authData.access_token) {
      throw new Error('Failed to get auth token')
    }

    // Store token in database
    const { data, error } = await supabaseAdmin
      .from('phonepe_auth_tokens')
      .insert({
        access_token: authData.access_token,
        expires_at: new Date(Date.now() + (authData.expires_in * 1000)),
      })
      .select()
      .single()

    if (error) throw error

    return new Response(JSON.stringify({ 
      success: true, 
      token: authData.access_token 
    }), {
      headers: { 'Content-Type': 'application/json' },
    })

  } catch (error) {
    return new Response(JSON.stringify({ 
      success: false, 
      error: error.message 
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})
```

### **Step 3.2: Create Order Function (45 minutes)**

File: `supabase/functions/create-phonepe-order/index.ts`

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  try {
    const { amount, vendor_id, invoice_id } = await req.json()

    // Get valid auth token
    const { data: tokenData } = await supabaseAdmin
      .from('phonepe_auth_tokens')
      .select('access_token')
      .eq('is_active', true)
      .gt('expires_at', new Date().toISOString())
      .order('expires_at', { ascending: false })
      .limit(1)
      .single()

    if (!tokenData) {
      // Get new token
      const authResponse = await fetch(`${Deno.env.get('SUPABASE_URL')}/functions/v1/phonepe-auth`)
      const authData = await authResponse.json()
      if (!authData.success) throw new Error('Auth token failed')
    }

    // Create order with PhonePe
    const merchantOrderId = `INV_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
    
    const orderPayload = {
      merchantOrderId,
      amount,
      paymentFlow: { type: "PG_CHECKOUT" },
      merchantUserId: "USER_" + Math.random().toString(36).substr(2, 9),
    }

    const orderResponse = await fetch('https://api-preprod.phonepe.com/apis/pg-sandbox/checkout/v2/sdk/order', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `O-Bearer ${tokenData.access_token}`,
      },
      body: JSON.stringify(orderPayload),
    })

    const orderData = await orderResponse.json()
    
    if (!orderData.orderId) {
      throw new Error('Order creation failed')
    }

    // Create transaction record
    const { data: transaction } = await supabaseAdmin
      .from('transactions')
      .insert({
        user_id: req.headers.get('user-id'),
        vendor_id,
        invoice_id,
        amount: amount / 100, // Convert back to rupees
        status: 'initiated',
        phonepe_order_id: orderData.orderId,
        phonepe_order_token: orderData.token,
        phonepe_merchant_order_id: merchantOrderId,
        phonepe_order_status: 'CREATED',
      })
      .select()
      .single()

    return new Response(JSON.stringify({
      success: true,
      orderId: orderData.orderId,
      token: orderData.token,
      transactionId: transaction.id,
    }), {
      headers: { 'Content-Type': 'application/json' },
    })

  } catch (error) {
    return new Response(JSON.stringify({
      success: false,
      error: error.message,
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})
```

### **Step 3.3: Payment Verification Function (30 minutes)**

File: `supabase/functions/verify-phonepe-payment/index.ts`

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  try {
    const { orderId } = await req.json()

    // Get auth token
    const { data: tokenData } = await supabaseAdmin
      .from('phonepe_auth_tokens')
      .select('access_token')
      .eq('is_active', true)
      .gt('expires_at', new Date().toISOString())
      .order('expires_at', { ascending: false })
      .limit(1)
      .single()

    // Check order status with PhonePe
    const statusResponse = await fetch(
      `https://api-preprod.phonepe.com/apis/pg-sandbox/checkout/v2/order/${orderId}/status`,
      {
        headers: {
          'Authorization': `O-Bearer ${tokenData.access_token}`,
        },
      }
    )

    const statusData = await statusResponse.json()
    
    // Update transaction record
    const { data: transaction } = await supabaseAdmin
      .from('transactions')
      .update({
        status: statusData.status === 'SUCCESS' ? 'success' : 'failure',
        phonepe_order_status: statusData.status,
        phonepe_response_data: statusData,
        completed_at: statusData.status === 'SUCCESS' ? new Date().toISOString() : null,
      })
      .eq('phonepe_order_id', orderId)
      .select()
      .single()

    return new Response(JSON.stringify({
      verified: statusData.status === 'SUCCESS',
      transactionId: transaction.id,
      status: statusData.status,
    }), {
      headers: { 'Content-Type': 'application/json' },
    })

  } catch (error) {
    return new Response(JSON.stringify({
      verified: false,
      error: error.message,
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})
```

---

## 🧪 **PHASE 4: TESTING & VALIDATION (1 hour)**

### **Step 4.1: Database Migration Test (15 minutes)**
```bash
# Apply migration
supabase db push

# Verify tables
supabase db diff
```

### **Step 4.2: Edge Functions Deployment (15 minutes)**
```bash
# Deploy functions
supabase functions deploy phonepe-auth
supabase functions deploy create-phonepe-order  
supabase functions deploy verify-phonepe-payment
```

### **Step 4.3: Flutter Integration Test (30 minutes)**
```bash
# Generate models
dart run build_runner build

# Test payment flow
flutter test integration_test/phonepe_payment_test.dart
```

---

## 🎯 **SUCCESS CRITERIA**

### **✅ COMPLETION CHECKLIST**
- [ ] Database migration applied successfully
- [ ] All Flutter models generated without errors
- [ ] PhonePe SDK 3.0.0 initializes correctly
- [ ] Edge functions deploy successfully
- [ ] Test payment completes end-to-end
- [ ] Card management UI shows PhonePe integration
- [ ] Transaction records created with all new fields
- [ ] Order status verification works

### **🚀 PERFORMANCE TARGETS**
- **Payment Initiation**: < 2 seconds
- **Order Creation**: < 1 second  
- **Status Verification**: < 1 second
- **Database Queries**: < 100ms
- **Total Payment Flow**: < 10 seconds

---

## 📋 **DEPLOYMENT SEQUENCE**

1. **Apply Database Migration** → Test locally
2. **Update Flutter Models** → Generate and test
3. **Deploy Edge Functions** → Test with Postman
4. **Update Flutter Code** → Test payment flow
5. **End-to-End Testing** → Verify complete flow
6. **Production Deployment** → Switch to production credentials

**TOTAL TIME**: 8 hours development + 2 hours testing = **1 working day**

🚀 **Ready to revolutionize payments with minimal code and maximum performance!**
