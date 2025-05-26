/*
Add/Edit Service Screen
This screen allows business owners and staff to add new services or edit existing ones
Features:
- Form validation for all required fields
- Category selection from dropdown
- Price and duration input with validation
- Buffer time configuration
- Description with character limit
*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../styles/app_styles.dart';
import '../api/create_service_api.dart';
import '../api/update_service_api.dart';
import '../api/get_categories_api.dart';

class AddEditServiceScreen extends StatefulWidget {
  final Map<String, dynamic> business;
  final bool isEditing;
  final Map<String, dynamic>? service;

  const AddEditServiceScreen({
    Key? key,
    required this.business,
    required this.isEditing,
    this.service,
  }) : super(key: key);

  @override
  State<AddEditServiceScreen> createState() => _AddEditServiceScreenState();
}

class _AddEditServiceScreenState extends State<AddEditServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serviceNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _bufferTimeController = TextEditingController();

  List<dynamic> _categories = [];
  int? _selectedCategoryId;
  bool _isLoading = false;
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();

    // If editing, populate the form with existing service data
    if (widget.isEditing && widget.service != null) {
      _populateFormWithServiceData();
    }
  }

  @override
  void dispose() {
    _serviceNameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _bufferTimeController.dispose();
    super.dispose();
  }

  // Load categories for the dropdown
  Future<void> _loadCategories() async {
    try {
      final result = await GetCategoriesApi.getCategories();

      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
          if (result['success']) {
            _categories = result['data']['categories'] ?? [];
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    }
  }

  // Populate form with existing service data for editing
  void _populateFormWithServiceData() {
    final service = widget.service!;

    _serviceNameController.text = service['service_name'] ?? '';
    _descriptionController.text = service['description'] ?? '';

    // Handle price conversion
    final price = service['price'];
    if (price != null) {
      if (price is String) {
        _priceController.text = price;
      } else {
        _priceController.text = price.toString();
      }
    }

    // Handle duration conversion
    final duration = service['duration'];
    if (duration != null) {
      _durationController.text = duration.toString();
    }

    // Handle buffer time conversion
    final bufferTime = service['buffer_time'];
    if (bufferTime != null && bufferTime != 0) {
      _bufferTimeController.text = bufferTime.toString();
    }

    // Set selected category
    _selectedCategoryId = service['category_id'];
  }

  // Save the service (create or update)
  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> result;

      if (widget.isEditing) {
        // Update existing service
        result = await UpdateServiceApi.updateService(
          serviceId: widget.service!['id'],
          serviceName: _serviceNameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          duration: int.parse(_durationController.text),
          price: double.parse(_priceController.text),
          bufferTime: _bufferTimeController.text.isEmpty
              ? 0
              : int.parse(_bufferTimeController.text),
          categoryId: _selectedCategoryId,
        );
      } else {
        // Create new service
        result = await CreateServiceApi.createService(
          businessId: widget.business['id'],
          serviceName: _serviceNameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          duration: int.parse(_durationController.text),
          price: double.parse(_priceController.text),
          bufferTime: _bufferTimeController.text.isEmpty
              ? 0
              : int.parse(_bufferTimeController.text),
          categoryId: _selectedCategoryId,
        );
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result['success']) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ??
                  (widget.isEditing ? 'Service updated successfully' : 'Service created successfully')),
              backgroundColor: AppStyles.successColor,
            ),
          );

          // Return to previous screen
          Navigator.of(context).pop();
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to save service'),
              backgroundColor: AppStyles.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: AppStyles.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Service' : 'Add Service'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Save button in app bar
          if (!_isLoading)
            TextButton(
              onPressed: _saveService,
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: _isLoadingCategories
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Service Name
                    TextFormField(
                      controller: _serviceNameController,
                      decoration: AppStyles.inputDecoration(
                        'Service Name *',
                        hint: 'e.g., Hair Cut, Massage, Consultation',
                        prefixIcon: const Icon(Icons.business_center),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Service name is required';
                        }
                        if (value.trim().length < 2) {
                          return 'Service name must be at least 2 characters';
                        }
                        return null;
                      },
                      textCapitalization: TextCapitalization.words,
                    ),

                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: AppStyles.inputDecoration(
                        'Description',
                        hint: 'Describe your service (optional)',
                        prefixIcon: const Icon(Icons.description),
                      ),
                      maxLines: 3,
                      maxLength: 500,
                      validator: (value) {
                        if (value != null && value.length > 500) {
                          return 'Description cannot exceed 500 characters';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Price and Duration Row
                    Row(
                      children: [
                        // Price
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            decoration: AppStyles.inputDecoration(
                              'Price (£) *',
                              hint: '25.00',
                              prefixIcon: const Icon(Icons.attach_money),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                            ],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Price is required';
                              }
                              final price = double.tryParse(value);
                              if (price == null || price < 0) {
                                return 'Enter a valid price';
                              }
                              return null;
                            },
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Duration
                        Expanded(
                          child: TextFormField(
                            controller: _durationController,
                            decoration: AppStyles.inputDecoration(
                              'Duration (min) *',
                              hint: '60',
                              prefixIcon: const Icon(Icons.schedule),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Duration is required';
                              }
                              final duration = int.tryParse(value);
                              if (duration == null || duration <= 0) {
                                return 'Enter a valid duration';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Buffer Time and Category Row
                    Row(
                      children: [
                        // Buffer Time
                        Expanded(
                          child: TextFormField(
                            controller: _bufferTimeController,
                            decoration: AppStyles.inputDecoration(
                              'Buffer Time (min)',
                              hint: '15',
                              prefixIcon: const Icon(Icons.timer),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final bufferTime = int.tryParse(value);
                                if (bufferTime == null || bufferTime < 0) {
                                  return 'Enter a valid buffer time';
                                }
                              }
                              return null;
                            },
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Category Dropdown
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _selectedCategoryId,
                            decoration: AppStyles.inputDecoration(
                              'Category',
                              prefixIcon: const Icon(Icons.category),
                            ),
                            hint: const Text('Select category'),
                            items: [
                              const DropdownMenuItem<int>(
                                value: null,
                                child: Text('No category'),
                              ),
                              ..._categories.map<DropdownMenuItem<int>>((category) {
                                return DropdownMenuItem<int>(
                                  value: category['id'],
                                  child: Text(category['name']),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedCategoryId = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveService,
                        style: AppStyles.primaryButtonStyle,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(widget.isEditing ? 'Update Service' : 'Create Service'),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Help text
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppStyles.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tips:',
                            style: AppStyles.bodyStyle.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• Duration: How long the service takes to complete\n'
                            '• Buffer Time: Extra time needed for cleanup/preparation\n'
                            '• Category: Helps customers find your service more easily\n'
                            '• Description: Explain what\'s included in your service',
                            style: AppStyles.captionStyle,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}