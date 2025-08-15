import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/data_providers.dart';
import '../../../../core/services/vendor_service.dart';
import '../../../../core/utils/navigation_helper.dart';
import '../../../../core/utils/error_handler.dart';

class VendorCreateScreen extends ConsumerStatefulWidget {
  const VendorCreateScreen({super.key});

  @override
  ConsumerState<VendorCreateScreen> createState() => _VendorCreateScreenState();
}

class _VendorCreateScreenState extends ConsumerState<VendorCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _upiIdController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscCodeController = TextEditingController();

  bool _isLoading = false;
  bool _useUpi = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _upiIdController.dispose();
    _accountNumberController.dispose();
    _ifscCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Vendor'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => NavigationHelper.safePop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Add New Vendor',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: AppTheme.primaryText,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.3),

              const SizedBox(height: 8),

              Text(
                'Enter vendor details to start making payments',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.secondaryText,
                ),
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 32),

              // Basic Information
              Text(
                'Basic Information',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ).animate().fadeIn(delay: 600.ms),

              const SizedBox(height: 16),

              // Name Field
              _buildTextField(
                controller: _nameController,
                label: 'Vendor Name',
                hint: 'Enter vendor name',
                icon: Icons.business,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vendor name is required';
                  }
                  if (value.trim().length < 2) {
                    return 'Vendor name must be at least 2 characters';
                  }
                  return null;
                },
              ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.3),

              const SizedBox(height: 16),

              // Phone Field
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: 'Enter phone number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Phone number is required';
                  }
                  if (value.trim().length != 10) {
                    return 'Phone number must be 10 digits';
                  }
                  return null;
                },
              ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.3),

              const SizedBox(height: 16),

              // Email Field
              _buildTextField(
                controller: _emailController,
                label: 'Email (Optional)',
                hint: 'Enter email address',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value.trim())) {
                      return 'Enter a valid email address';
                    }
                  }
                  return null;
                },
              ).animate().fadeIn(delay: 1200.ms).slideY(begin: 0.3),

              const SizedBox(height: 32),

              // Payment Method
              Text(
                'Payment Method',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ).animate().fadeIn(delay: 1400.ms),

              const SizedBox(height: 16),

              // Payment Method Toggle
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _useUpi = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: _useUpi
                                ? AppTheme.primaryAccent
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'UPI ID',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _useUpi
                                  ? Colors.white
                                  : AppTheme.secondaryText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _useUpi = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: !_useUpi
                                ? AppTheme.primaryAccent
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'Bank Account',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: !_useUpi
                                  ? Colors.white
                                  : AppTheme.secondaryText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 1600.ms).slideY(begin: 0.3),

              const SizedBox(height: 16),

              // Payment Details
              if (_useUpi) ...[
                _buildTextField(
                  controller: _upiIdController,
                  label: 'UPI ID',
                  hint: 'vendor@upi',
                  icon: Icons.account_balance_wallet,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'UPI ID is required';
                    }
                    if (!value.contains('@')) {
                      return 'Enter a valid UPI ID';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 1800.ms).slideY(begin: 0.3),
              ] else ...[
                _buildTextField(
                  controller: _accountNumberController,
                  label: 'Account Number',
                  hint: 'Enter account number',
                  icon: Icons.account_balance,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Account number is required';
                    }
                    if (value.trim().length < 9) {
                      return 'Enter a valid account number';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 1800.ms).slideY(begin: 0.3),

                const SizedBox(height: 16),

                _buildTextField(
                  controller: _ifscCodeController,
                  label: 'IFSC Code',
                  hint: 'Enter IFSC code',
                  icon: Icons.code,
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'IFSC code is required';
                    }
                    if (value.trim().length != 11) {
                      return 'IFSC code must be 11 characters';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 2000.ms).slideY(begin: 0.3),
              ],

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveVendor,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        )
                      : const Text(
                          'Add Vendor',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ).animate().fadeIn(delay: 2400.ms).slideY(begin: 0.5),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization? textCapitalization,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization ?? TextCapitalization.none,
      validator: validator,
      style: const TextStyle(
        color: AppTheme.primaryText,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.primaryAccent),
        labelStyle: const TextStyle(color: AppTheme.secondaryText),
        hintStyle: const TextStyle(color: AppTheme.secondaryText),
        filled: true,
        fillColor: AppTheme.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppTheme.secondaryText.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppTheme.primaryAccent,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppTheme.errorColor,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppTheme.errorColor,
            width: 2,
          ),
        ),
      ),
    );
  }

  void _saveVendor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await VendorService.createVendor(
        name: _nameController.text.trim(),
        accountNumber: _useUpi
            ? 'UPI_ACCOUNT'
            : _accountNumberController.text.trim(),
        ifscCode: _useUpi ? 'UPI_IFSC' : _ifscCodeController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        upiId: _useUpi ? _upiIdController.text.trim() : null,
      );

      // Refresh vendors list
      ref.refresh(vendorsProvider);

      if (mounted) {
        ErrorHandler.showSuccess(context, 'Vendor added successfully!');
        NavigationHelper.safePop(context, true);
      }
    } catch (error) {
      if (mounted) {
        ErrorHandler.showError(context, 'Failed to add vendor');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
