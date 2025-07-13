import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/vendor.dart';

import '../../../../core/providers/data_providers.dart';
import '../../../../core/services/invoice_service.dart';

class InvoiceCreateScreen extends ConsumerStatefulWidget {
  const InvoiceCreateScreen({super.key});

  @override
  ConsumerState<InvoiceCreateScreen> createState() => _InvoiceCreateScreenState();
}

class _InvoiceCreateScreenState extends ConsumerState<InvoiceCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _invoiceNumberController = TextEditingController();
  
  Vendor? _selectedVendor;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Generate invoice number
    _invoiceNumberController.text = _generateInvoiceNumber();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _invoiceNumberController.dispose();
    super.dispose();
  }

  String _generateInvoiceNumber() {
    final now = DateTime.now();
    return 'INV-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(8)}';
  }

  @override
  Widget build(BuildContext context) {
    final vendors = ref.watch(vendorsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Invoice'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Invoice Number
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryAccent.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Invoice Details',
                      style: TextStyle(
                        color: AppTheme.primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _invoiceNumberController,
                      style: const TextStyle(color: AppTheme.primaryText),
                      decoration: const InputDecoration(
                        labelText: 'Invoice Number',
                        labelStyle: TextStyle(color: AppTheme.secondaryText),
                        prefixIcon: Icon(Icons.receipt, color: AppTheme.secondaryText),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter invoice number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      style: const TextStyle(color: AppTheme.primaryText),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Amount (₹)',
                        labelStyle: TextStyle(color: AppTheme.secondaryText),
                        prefixIcon: Icon(Icons.currency_rupee, color: AppTheme.secondaryText),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter valid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      style: const TextStyle(color: AppTheme.primaryText),
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        labelStyle: TextStyle(color: AppTheme.secondaryText),
                        prefixIcon: Icon(Icons.description, color: AppTheme.secondaryText),
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter description';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),

              const SizedBox(height: 20),

              // Vendor Selection
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryAccent.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vendor Selection',
                      style: TextStyle(
                        color: AppTheme.primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    vendors.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryAccent),
                        ),
                      ),
                      error: (error, stackTrace) => Text(
                        'Error loading vendors: $error',
                        style: const TextStyle(color: Colors.red),
                      ),
                      data: (vendorList) => DropdownButtonFormField<Vendor>(
                        value: _selectedVendor,
                        style: const TextStyle(color: AppTheme.primaryText),
                        decoration: const InputDecoration(
                          labelText: 'Select Vendor',
                          labelStyle: TextStyle(color: AppTheme.secondaryText),
                          prefixIcon: Icon(Icons.business, color: AppTheme.secondaryText),
                        ),
                        dropdownColor: AppTheme.cardBackground,
                        items: vendorList.map((vendor) {
                          return DropdownMenuItem<Vendor>(
                            value: vendor,
                            child: Text(
                              vendor.name,
                              style: const TextStyle(color: AppTheme.primaryText),
                            ),
                          );
                        }).toList(),
                        onChanged: (vendor) {
                          setState(() {
                            _selectedVendor = vendor;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a vendor';
                          }
                          return null;
                        },
                      ),
                    ),
                    if (_selectedVendor != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedVendor!.name,
                              style: const TextStyle(
                                color: AppTheme.primaryText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedVendor!.upiId ?? '${_selectedVendor!.accountNumber} • ${_selectedVendor!.ifscCode}',
                              style: const TextStyle(
                                color: AppTheme.secondaryText,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),

              const SizedBox(height: 20),

              // Due Date
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryAccent.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Due Date',
                      style: TextStyle(
                        color: AppTheme.primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _dueDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: AppTheme.primaryAccent,
                                  surface: AppTheme.cardBackground,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (date != null) {
                          setState(() {
                            _dueDate = date;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppTheme.secondaryText.withValues(alpha: 0.3),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: AppTheme.secondaryText,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
                              style: const TextStyle(
                                color: AppTheme.primaryText,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),

              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createInvoice,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.cardBackground,
                        foregroundColor: AppTheme.primaryAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(
                            color: AppTheme.primaryAccent,
                            width: 1,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Save Draft',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createAndPayInvoice,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Create & Pay Now',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.5),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createInvoice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await InvoiceService.createInvoice(
        vendorId: _selectedVendor!.id,
        amount: double.parse(_amountController.text),
        description: _descriptionController.text.trim(),
        invoiceNumber: _invoiceNumberController.text.trim(),
        dueDate: _dueDate,
      );

      if (!mounted) return;

      // Refresh invoices list
      ref.invalidate(filteredInvoicesProvider);

      // Show success and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invoice created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      context.pop();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create invoice: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _createAndPayInvoice() async {
    if (!_formKey.currentState!.validate() || _selectedVendor == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create invoice using smart defaults
      await InvoiceService.createPaymentInvoice(
        vendorId: _selectedVendor!.id,
        amount: double.parse(_amountController.text),
        description: _descriptionController.text.isEmpty
            ? 'Payment to ${_selectedVendor!.name}'
            : _descriptionController.text,
      );

      // Navigate to payment screen
      if (mounted) {
        context.go('/pay/${_selectedVendor!.id}');
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create invoice: $error'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
