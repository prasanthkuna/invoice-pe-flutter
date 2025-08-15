# 🔧 InvoicePe - Code Patterns Library
> **Standardized Implementation Patterns for AI Agents - Elon Standard Code**

## 🎯 **CORE PRINCIPLES**

### **Tesla-Grade Standards**
- **Result Pattern**: All operations return `Result<T>` for error handling
- **Riverpod State**: All state management through providers
- **Immutable Models**: Using dart_mappable for serialization
- **Smart Logging**: Structured logging with context
- **Zero Nulls**: Null-safe code with proper validation

---

## 🏗️ **ARCHITECTURE PATTERNS**

### **1. Service Layer Pattern**
```dart
// File: lib/core/services/[service_name]_service.dart
class PaymentService {
  static final _log = Log.component('payment');
  
  /// Process payment with comprehensive error handling
  static Future<Result<PaymentResult>> processPayment({
    required double amount,
    required String vendorId,
    required String cardToken,
  }) async {
    try {
      _log.info('Processing payment', context: {
        'amount': amount,
        'vendorId': vendorId,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // Implementation logic here
      final result = await _performPayment(amount, vendorId, cardToken);
      
      _log.info('Payment successful', context: {'transactionId': result.id});
      return Success(result);
      
    } on PaymentException catch (e) {
      _log.error('Payment failed', error: e, context: {'vendorId': vendorId});
      return Failure(e.message);
    } catch (e) {
      _log.error('Unexpected payment error', error: e);
      return Failure('Payment processing failed');
    }
  }
}
```

### **2. Riverpod Provider Pattern**
```dart
// File: lib/features/[feature]/providers/[feature]_providers.dart
@riverpod
Future<Result<List<Transaction>>> transactions(TransactionsRef ref) async {
  try {
    final authState = ref.watch(authStateProvider);
    if (authState is! Authenticated) {
      return const Failure('User not authenticated');
    }
    
    final transactions = await TransactionService.getTransactions(
      userId: authState.user.id,
    );
    
    return Success(transactions);
  } catch (e) {
    Log.component('transactions').error('Failed to load transactions', error: e);
    return Failure('Failed to load transactions: $e');
  }
}

// State provider for UI state
@riverpod
class SelectedVendor extends _$SelectedVendor {
  @override
  Vendor? build() => null;
  
  void select(Vendor vendor) {
    state = vendor;
    Log.component('ui').info('Vendor selected', context: {'vendorId': vendor.id});
  }
  
  void clear() {
    state = null;
  }
}
```

### **3. Screen/Widget Pattern**
```dart
// File: lib/features/[feature]/presentation/screens/[screen]_screen.dart
class QuickPaymentScreen extends ConsumerStatefulWidget {
  const QuickPaymentScreen({super.key});

  @override
  ConsumerState<QuickPaymentScreen> createState() => _QuickPaymentScreenState();
}

class _QuickPaymentScreenState extends ConsumerState<QuickPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _amountFocusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();
    // Smart focus management
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleInitialFocus();
    });
  }
  
  void _handleInitialFocus() {
    final vendors = ref.read(vendorListProvider);
    if (vendors.length == 1) {
      // Auto-select single vendor and focus amount
      ref.read(selectedVendorProvider.notifier).select(vendors.first);
      _amountFocusNode.requestFocus();
    }
    // Otherwise, let user select vendor first
  }
  
  @override
  Widget build(BuildContext context) {
    final selectedVendor = ref.watch(selectedVendorProvider);
    final isProcessing = ref.watch(paymentProcessingProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Quick Payment')),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Vendor selection
            _buildVendorSelector(),
            
            // Amount input
            TextFormField(
              controller: _amountController,
              focusNode: _amountFocusNode,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹',
              ),
              validator: _validateAmount,
              enabled: selectedVendor != null,
            ),
            
            // Payment button
            ElevatedButton(
              onPressed: isProcessing ? null : _processPayment,
              child: isProcessing 
                ? const CircularProgressIndicator()
                : Text('Pay ₹${_amountController.text} to ${selectedVendor?.name ?? 'Vendor'}'),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;
    
    final vendor = ref.read(selectedVendorProvider);
    final amount = double.parse(_amountController.text);
    
    ref.read(paymentProcessingProvider.notifier).state = true;
    
    try {
      final result = await PaymentService.processPayment(
        amount: amount,
        vendorId: vendor!.id,
        cardToken: 'demo_token',
      );
      
      switch (result) {
        case Success():
          // Refresh providers for immediate UI update
          // ignore: unused_result
          ref.refresh(dashboardMetricsProvider);
          // ignore: unused_result
          ref.refresh(transactionsProvider);
          
          if (mounted) {
            context.go('/payment-success');
          }
          
        case Failure(error: final error):
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error), backgroundColor: Colors.red),
            );
          }
      }
    } finally {
      ref.read(paymentProcessingProvider.notifier).state = false;
    }
  }
  
  @override
  void dispose() {
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }
}
```

---

## 📊 **DATA MODEL PATTERNS**

### **4. Dart Mappable Model Pattern**
```dart
// File: lib/core/models/[model_name].dart
import 'package:dart_mappable/dart_mappable.dart';

part '[model_name].mapper.dart';

@MappableClass()
class Transaction with TransactionMappable {
  const Transaction({
    required this.id,
    required this.amount,
    required this.vendorId,
    required this.status,
    required this.createdAt,
    this.description,
    this.fee = 0.0,
    this.rewards = 0.0,
  });
  
  final String id;
  final double amount;
  final String vendorId;
  final TransactionStatus status;
  final DateTime createdAt;
  final String? description;
  final double fee;
  final double rewards;
  
  // Computed properties
  double get total => amount + fee;
  bool get isSuccessful => status == TransactionStatus.success;
  
  // Factory constructors
  factory Transaction.fromSupabase(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      vendorId: json['vendor_id'] as String,
      status: TransactionStatus.values.byName(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      description: json['description'] as String?,
      fee: (json['fee'] as num?)?.toDouble() ?? 0.0,
      rewards: (json['rewards'] as num?)?.toDouble() ?? 0.0,
    );
  }
  
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'amount': amount,
      'vendor_id': vendorId,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'description': description,
      'fee': fee,
      'rewards': rewards,
    };
  }
}

@MappableEnum()
enum TransactionStatus {
  pending,
  processing,
  success,
  failed,
  cancelled,
}
```

---

## 🔄 **ERROR HANDLING PATTERNS**

### **5. Result Pattern Implementation**
```dart
// File: lib/core/types/result.dart
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

class Failure<T> extends Result<T> {
  const Failure(this.error);
  final String error;
}

// Usage in services
Future<Result<User>> authenticateUser(String phone, String otp) async {
  try {
    final user = await _performAuth(phone, otp);
    return Success(user);
  } on AuthException catch (e) {
    return Failure(e.message);
  } catch (e) {
    return Failure('Authentication failed');
  }
}

// Usage in UI
final authResult = await AuthService.authenticateUser(phone, otp);
switch (authResult) {
  case Success(data: final user):
    // Handle success
    context.go('/dashboard');
  case Failure(error: final error):
    // Handle error
    showErrorSnackBar(error);
}
```

---

## 📝 **LOGGING PATTERNS**

### **6. Smart Logging Pattern**
```dart
// File: lib/core/services/smart_logger.dart
class SmartLogger {
  static void info(String message, {Map<String, dynamic>? context}) {
    _log('INFO', message, context ?? {});
  }
  
  static void error(String message, {Object? error, Map<String, dynamic>? context}) {
    final enrichedContext = {
      ...context ?? {},
      if (error != null) 'error': error.toString(),
      'timestamp': DateTime.now().toIso8601String(),
      'correlationId': _generateCorrelationId(),
    };
    
    _log('ERROR', message, enrichedContext);
    
    // Database logging for production monitoring
    if (AppConstants.enableDatabaseLogging) {
      _logToDatabase('ERROR', message, enrichedContext);
    }
  }
  
  static void _log(String level, String message, Map<String, dynamic> context) {
    if (kDebugMode) {
      print('[$level] $message ${context.isNotEmpty ? context : ''}');
    }
  }
}

// Usage
Log.component('payment').info('Processing payment', context: {
  'amount': amount,
  'vendorId': vendorId,
});
```

---

## 🎯 **IMPLEMENTATION CHECKLIST**

### **When Creating New Features**
- [ ] Create service class with Result pattern
- [ ] Add Riverpod providers for state management
- [ ] Implement screen with proper lifecycle management
- [ ] Add dart_mappable models for data
- [ ] Include comprehensive error handling
- [ ] Add smart logging with context
- [ ] Write integration tests
- [ ] Update documentation

### **Code Quality Standards**
- [ ] All async operations return Result<T>
- [ ] All state managed through Riverpod
- [ ] All models use dart_mappable
- [ ] All errors logged with context
- [ ] All UI properly disposed
- [ ] All navigation context-safe
- [ ] All forms validated
- [ ] All providers refreshed after mutations

**🧠 LLM Agent Tip**: Copy these patterns exactly. They're battle-tested and follow InvoicePe's Elon-standard architecture.**
